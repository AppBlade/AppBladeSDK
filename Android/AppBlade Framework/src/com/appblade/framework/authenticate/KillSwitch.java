package com.appblade.framework.authenticate;

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

import com.appblade.framework.AppBlade;
import com.appblade.framework.WebServiceHelper;
import com.appblade.framework.WebServiceHelper.HttpMethod;
import com.appblade.framework.updates.UpdatesHelper;
import com.appblade.framework.utils.HttpClientProvider;
import com.appblade.framework.utils.HttpUtils;
import com.appblade.framework.utils.StringUtils;
import com.appblade.framework.utils.SystemUtils;

/**
 * Class used for asynchronously authenticating an app and closing the app if unauthorized.
 * @see KillSwitchTask
 * @author rich.stern@raizlabs
 * @author andrew.tremblay@raizlabs 
 */
public class KillSwitch {
	private static final String PrefsKey = "AppBlade.KillSwitch.SharedPrefs";
	private static final String PrefsKeyTTL = "AppBlade.KillSwitch.TTL";
	private static final String PrefsKeyTTLUpdated = "AppBlade.KillSwitch.TTLUpdated";
	
	private static final String DefaultAccessRevokedMessage = "Your access have been revoked";
	
	private static int ttl = Integer.MIN_VALUE;
	private static long ttlLastUpdated = Long.MIN_VALUE;
	private static final int MillisPerHour = 1000 * 60 * 60;
	@SuppressWarnings("unused")
	private static final int MillisPerDay = MillisPerHour * 24;
	
	private static boolean inProgress = false;
	
	/**
	 * Kicks off a new {@link KillSwitchTask} 
	 * @param activity Activity we will authorizing and, potentially, be killing.
	 */
	public static synchronized void authorize(Activity activity) {
		reloadSharedPrefs(activity);
		if(shouldUpdate() && !inProgress) {
			KillSwitchTask task = new KillSwitchTask(activity);
			task.execute();
		}
	}
	
	/**
	 * This feels a little hacky, but it serves the same purpose as passing the isLoopBack flag around
	 * which I'm not in love with either.  This basically addresses the need to shut down the 
	 * {@link RemoteAuthorizationActivity} when we require login info.  Once the whole process completes,
	 * this is basically the end of the road, and we need to shut down the activity and return to the 
	 * main application.  <br>
	 * If remote auth is not required, the Activity context we have a reference to is the 
	 * main application's root activity that called to request authorization, and we definitely don't want
	 * to shut that one down. <br>
	 * @param context context we want to kill.
	 */
	public static void kill(Activity context) {
		if(context.getClass().equals(RemoteAuthorizeActivity.class))
			context.finish();
	}

	
	/**
	 * Checks the ttl against system time to see whether we need to update.
	 * @return If it is time to update.
	 */
	public static boolean shouldUpdate() {
		boolean shouldUpdate = true;
		long now = System.currentTimeMillis();
		
		// If we have updated TTL value from AppBlade within the last hour, do not require update
		if(ttlLastUpdated > (now - MillisPerHour))
			shouldUpdate = false;
		
		// If TTL is satisfied (we are within the time to live from the last time updated), do not require update
		else if((ttlLastUpdated + ttl) > now)
			shouldUpdate = false;

		Log.v(AppBlade.LogTag, String.format("KillSwitch.shouldUpdate, ttl:%d, last updated:%d now:%d", ttl, ttlLastUpdated, now));
		Log.v(AppBlade.LogTag, String.format("KillSwitch.shouldUpdate? %b", shouldUpdate));
		
		return shouldUpdate;
	}
	
	/**
	 * Clears ttl from the shared preferences. Will cause a kick off to refresh the authentication. 
	 * @param activity
	 */
	public static void clear(Activity activity) {
		SharedPreferences prefs = activity.getSharedPreferences(PrefsKey, Context.MODE_PRIVATE);
		Editor editor = prefs.edit();
		editor.remove(PrefsKeyTTL);
		editor.remove(PrefsKeyTTLUpdated);
		editor.commit();
		ttl = Integer.MIN_VALUE;
		ttlLastUpdated = Long.MIN_VALUE;
	}

	/**
	 * Synchronized generator for device authorization. 
	 * @return HttpResponse for kill switch api.
	 */
	public static synchronized HttpResponse getKillSwitchResponse() {
		HttpResponse response = null;
		HttpClient client = HttpClientProvider.newInstance(SystemUtils.UserAgent);
		String urlPath = String.format(WebServiceHelper.ServicePathKillSwitchFormat);
		String url = WebServiceHelper.getUrl(urlPath);
		String authHeader = WebServiceHelper.getHMACAuthHeader(AppBlade.appInfo, urlPath, null, HttpMethod.GET);
		try {
			HttpGet request = new HttpGet();
			request.setURI(new URI(url));
			request.addHeader("Authorization", authHeader);
			WebServiceHelper.addCommonHeaders(request);
		    response = client.execute(request);
		}
		catch(Exception ex)
		{
			Log.v(AppBlade.LogTag, String.format("%s %s", ex.getClass().getSimpleName(), ex.getMessage()));
		}
		
		return response;
	}
	
	/**
	 * Refreshes local varables ttl and ttlLAstUpdated from their stored location. 
	 * @param activity Activity from which to load preferences. 
	 */
	public static void reloadSharedPrefs(Activity activity) {
		SharedPreferences prefs = activity.getSharedPreferences(PrefsKey, Context.MODE_PRIVATE);
		ttl = prefs.getInt(PrefsKeyTTL, ttl);
		ttlLastUpdated = prefs.getLong(PrefsKeyTTLUpdated, ttlLastUpdated);
	}


	/**
	 * Asynchronously checks access with {@link #getKillSwithResponse()}
	 * Displays a progress dialog
 * @author rich.stern@raizlabs
 * @author andrew.tremblay@raizlabs 
	 */
	static class KillSwitchTask extends AsyncTask<Void, Void, Void> {
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
		protected Void doInBackground(Void... params) {
			HttpResponse response = getKillSwitchResponse();
			if(response != null){
				Log.v(AppBlade.LogTag, String.format("Response status:%s", response.getStatusLine()));
			}
			handleResponse(response);
			return null;
		}
		@Override
		protected void onPostExecute(Void unused) {
			inProgress = false;
			if(progress != null && progress.isShowing()){
			    try {
			    	progress.dismiss();
			    } catch (IllegalArgumentException e) {
			        // nothing, in case activity is dismissed before dialog is dismissed
			    }
			}
		}
		@Override
		protected void onCancelled() {
			inProgress = false;
		}

		/**
		 * Handles the response back from the server. Gets new ttl and an optional update notification. 
		 * @see UpdatesHelper
		 * @param response
		 */
		private void handleResponse(HttpResponse response) {
			if(HttpUtils.isOK(response)) {
				try {
					String data = StringUtils.readStream(response.getEntity().getContent());
					Log.v(AppBlade.LogTag, String.format("KillSwitch response OK %s", data));
					JSONObject json = new JSONObject(data);
					int timeToLive = json.getInt("ttl");
					save(timeToLive);

					kill(context);
				}
				catch (IOException ex) { }
				catch (JSONException ex) { }
			}
			
			if(HttpUtils.isUnauthorized(response)) {
				// display modal dialog that finishes the activity
				String message = getKillSwitchUnauthorizedMessage(response);
				displayUnauthorizedDialog(message);
			}
		}

		/**
		 * Attempts to pull a friendly message out of a web response
		 * and optionally falls back to a default
		 * @param response
		 * @return
		 */
		public static String getKillSwitchUnauthorizedMessage(HttpResponse response) {
			String message = null;
			try {
				String data = StringUtils.readStream(response.getEntity().getContent());
				Log.v(AppBlade.LogTag, String.format("KillSwitch response unauthorized %s", data));
				JSONObject json = new JSONObject(data);
				message = json.getString("error");
				Log.v(AppBlade.LogTag, json.toString());
			}
			catch (IOException ex) { }
			catch (JSONException ex) { }
			
			if(StringUtils.isNullOrEmpty(message))
				message = DefaultAccessRevokedMessage;
			
			return message;
		}

		/**
		 * In the event of bad authorization, allows user to retry or give up. 
		 * @param message String message to display to the user before closing the activity. 
		 */
		private void displayUnauthorizedDialog(final String message) {
			context.runOnUiThread(new Runnable() {
				public void run() {
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
			});
		}

		/**
		 * Stores ttl and ttlLAastUpdated in their static locations.
		 * @param timeToLive
		 */
		private void save(int timeToLive) {
			ttl = timeToLive;
			ttlLastUpdated = System.currentTimeMillis();
			SharedPreferences prefs = context.getSharedPreferences(PrefsKey, Context.MODE_PRIVATE);
			Editor editor = prefs.edit();
			editor.putInt(PrefsKeyTTL, ttl);
			editor.putLong(PrefsKeyTTLUpdated, ttlLastUpdated);
			editor.commit();
		}
		
	}

	
}
