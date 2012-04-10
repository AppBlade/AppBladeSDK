package com.appblade.framework;

import java.io.IOException;
import java.net.URI;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.AlertDialog.Builder;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.os.AsyncTask;
import android.util.Log;

import com.appblade.framework.WebServiceHelper.HttpMethod;

public class KillSwitch {
	
	private static final String PrefsKey = "AppBlade.KillSwitch.SharedPrefs";
	private static final String PrefsKeyTTL = "AppBlade.KillSwitch.TTL";
	private static final String PrefsKeyTTLUpdated = "AppBlade.KillSwitch.TTLUpdated";
	
	private static int ttl = Integer.MIN_VALUE;
	private static long ttlLastUpdated = Long.MIN_VALUE;
	
	private static final int MillisPerHour = 1000 * 60 * 60;
	private static final int MillisPerDay = MillisPerHour * 24;
	
	private static boolean inProgress = false;
	
	public static synchronized void authorize(Activity activity) {
		
		reloadSharedPrefs(activity);
		
		if(shouldUpdate() && !inProgress) {
			KillSwitchTask task = new KillSwitchTask(activity);
			task.execute();
		}
	}
	
	public static boolean shouldUpdate() {
		boolean shouldUpdate = true;
		long now = System.currentTimeMillis();
		
		// If we have updated TTL value from AppBlade within the last hour, do not require update
		if(ttlLastUpdated > (now - MillisPerHour))
			shouldUpdate = false;
		
		// If TTL is satisfied (we are within the time to live from the last time updated), do not require update
		else if(ttlLastUpdated > (ttl * MillisPerDay + ttlLastUpdated))
			shouldUpdate = false;

		Log.d(AppBlade.LogTag, String.format("KillSwitch.shouldUpdate, ttl:%d, last updated:%d", ttl, ttlLastUpdated));
		Log.d(AppBlade.LogTag, String.format("KillSwitch.shouldUpdate? %b", shouldUpdate));
		return shouldUpdate;
	}

	private static void reloadSharedPrefs(Activity activity) {
		SharedPreferences prefs = activity.getSharedPreferences(PrefsKey, Context.MODE_PRIVATE);
		ttl = prefs.getInt(PrefsKeyTTL, ttl);
		ttlLastUpdated = prefs.getLong(PrefsKeyTTLUpdated, ttlLastUpdated);
	}
	
	public static void clear(Activity activity) {
		SharedPreferences prefs = activity.getSharedPreferences(PrefsKey, Context.MODE_PRIVATE);
		Editor editor = prefs.edit();
		editor.remove(PrefsKeyTTL);
		editor.remove(PrefsKeyTTLUpdated);
		editor.commit();
		
		ttl = Integer.MIN_VALUE;
		ttlLastUpdated = Long.MIN_VALUE;
	}

	public static synchronized HttpResponse getKillSwitchResponse() {
		HttpResponse response = null;
		HttpClient client = HttpClientProvider.newInstance("Android");

		String urlPath = String.format(WebServiceHelper.ServicePathKillSwitchFormat, AppBlade.appInfo.AppId, AppBlade.appInfo.Ext);
		String url = WebServiceHelper.getUrl(urlPath);
		String authHeader = WebServiceHelper.getHMACAuthHeader(AppBlade.appInfo, urlPath, null, HttpMethod.GET);
		
		Log.d(AppBlade.LogTag, "getKillSwitchResponse " + urlPath);
		Log.d(AppBlade.LogTag, "getKillSwitchResponse " + url);
		Log.d(AppBlade.LogTag, "getKillSwitchResponse " + authHeader);
		
		try {
			HttpGet request = new HttpGet();
			request.setURI(new URI(url));
			request.addHeader("Authorization", authHeader);
			WebServiceHelper.addCommonHeaders(request);
		    response = client.execute(request);
		}
		catch(Exception ex)
		{
			Log.d(AppBlade.LogTag, String.format("%s %s", ex.getClass().getSimpleName(), ex.getMessage()));
		}
		
		return response;
	}
	
	static class KillSwitchTask extends AsyncTask<Void, Void, HttpResponse> {

		Activity context;
		ProgressDialog progress;

		public KillSwitchTask(Activity context) {
			this.context = context;
		}

		@Override
		protected void onPreExecute() {
			inProgress = true;
			progress = ProgressDialog.show(context, null, "Checking access...");
		}

		@Override
		protected HttpResponse doInBackground(Void... params) {
			HttpResponse response = getKillSwitchResponse();
			return response;
		}
		
		@Override
		protected void onCancelled() {
			inProgress = false;
		}

		@Override
		protected void onPostExecute(HttpResponse response) {
			inProgress = false;
			if(progress != null && progress.isShowing())
				progress.dismiss();

			Log.d(AppBlade.LogTag, String.format("Response status:%s", response.getStatusLine()));
			handleResponse(response);
		}

		private void handleResponse(HttpResponse response) {
			if(HttpUtils.isOK(response)) {
				try {
					String data = StringUtils.readStream(response.getEntity().getContent());
					Log.d(AppBlade.LogTag, String.format("KillSwitch response OK %s", data));
					JSONObject json = new JSONObject(data);
					int timeToLive = json.getInt("ttl");
					save(timeToLive);
				}
				catch (IOException ex) { }
				catch (JSONException ex) { }
			}
			
			if(HttpUtils.isUnauthorized(response)) {
				
				// display modal dialog that finishes the activity
				String message = null;
				try {
					String data = StringUtils.readStream(response.getEntity().getContent());
					Log.d(AppBlade.LogTag, String.format("KillSwitch response unauthorized %s", data));
					JSONObject json = new JSONObject(data);
					message = json.getString("error");
					Log.d(AppBlade.LogTag, json.toString());
				}
				catch (IOException ex) { }
				catch (JSONException ex) { }
				
				if(StringUtils.isNullOrEmpty(message))
					message = "Your access have been revoked";
				
				AlertDialog.Builder builder = new Builder(context);
				builder.setMessage(message);
				builder.setCancelable(false);
				builder.setPositiveButton("OK", new DialogInterface.OnClickListener() {
					
					public void onClick(DialogInterface dialog, int which) {
						context.finish();
					}
				});
				builder.setNegativeButton("Try Again", new DialogInterface.OnClickListener() {
					
					public void onClick(DialogInterface dialog, int which) {
						RemoteAuthHelper.clear(context);
						KillSwitch.clear(context);
						AuthHelper.checkAuthorization(context, false);
					}
				});
				builder.show();
			}
		}

		private void save(int timeToLive) {
			ttl = timeToLive;
			ttlLastUpdated = System.currentTimeMillis();
			
			SharedPreferences prefs = context.getSharedPreferences(PrefsKey, Context.MODE_PRIVATE);
			Editor editor = prefs.edit();
			editor.putInt(PrefsKeyTTL, ttl);
			editor.putLong(PrefsKeyTTLUpdated, ttlLastUpdated);
			editor.commit();
			
			//displayResult();
		}

		/**
		 * Temp method to show results
		 */
		@SuppressWarnings("unused")
		private void displayResult() {
			String message = String.format("ttl: %d, updated: %d", ttl, ttlLastUpdated);
			
			AlertDialog.Builder builder = new AlertDialog.Builder(context);
			builder.setPositiveButton("OK", null);
			builder.setMessage(message);
			builder.show();
		}
		
	}

}
