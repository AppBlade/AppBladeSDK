package com.appblade.framework;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;

import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.json.JSONException;
import org.json.JSONObject;

import com.appblade.framework.WebServiceHelper.HttpMethod;
import com.appblade.framework.authenticate.AuthHelper;
import com.appblade.framework.authenticate.KillSwitch;
import com.appblade.framework.utils.HttpClientProvider;
import com.appblade.framework.utils.HttpUtils;
import com.appblade.framework.utils.IOUtils;
import com.appblade.framework.utils.StringUtils;
import com.appblade.framework.utils.SystemUtils;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.DialogInterface.OnCancelListener;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Environment;
import android.util.Log;

/**
 * Class containing functions that will handle a download and installation of an apk update for the given app.
 * @author rich.stern@raizlabs  
 * @author andrew.tremblay@raizlabs
 * @see KillSwitch
 */
public class UpdatesHelper {
	private static final int NotificationNewVersion = 0;
	private static final int NotificationNewVersionDownloading = 1;	

	/**
	 * Update check that soft-checks for the best update method available. <br>
	 * If not authenticated, we checks with {@link #checkForAnonymousUpdate(Activity)}. <br> 
	 * @param activity the Activity to handle the update. Should belong to the same application context that was authenticated if authenticated updates are required. 
	 * @param promptForDownload 
	 */
	public static void checkForUpdate(Activity activity, boolean promptForDownload)
	{	//falls into the best behavior available. Currently Anonymous update is the only supported behavior. 
		checkForAnonymousUpdate(activity, promptForDownload);
	}

	
	/** <h2>NOT YET SUPPORTED BY THE API</h2>
	 * Authentication check that uses authorization credentials to determine if an update is available. <br> 
	 * Will prompt a login dialog if credentials are not immediately found to be available.
	 * Note that this is essentially unnecessary to call right after {@link AppBlade.authenticate(Activity)} since that handles authentication by default. 
	 * @param activity activity to check authorization and run the {@link UpdateTask}
	 * @param promptForDownload 
	 */
	public static void checkForAuthenticatedUpdate(Activity activity, boolean promptForDownload)
	{
		//TODO: check if we're already processing the update / downloading / installing anything. Shouldn't be an issue as long as there's enough time between calls.
		if(AuthHelper.isAuthorized(activity))
		{
			UpdateTask updateTask = new UpdateTask(activity, true, promptForDownload);
			updateTask.execute();
		}
		else
		{
			UpdatesHelper.checkAuthorization(activity, true);
		}
	}


	/**<h2>NOT YET SUPPORTED BY THE API</h2>
	 * Checks whether the given activity is authorized, prompts an optional dialog beforehand. 
	 * Does not kill the activity should the user cancel the authentication.
	 * @param activity Activity to check authorization/prompt dialog. 
	 * @param shouldPrompt boolean of whether an "Authorization Required" dialog should be shown to the user first.
	 */
	private static void checkAuthorization(final Activity activity, boolean shouldPrompt) {
			if (shouldPrompt) {
				AlertDialog.Builder builder = new AlertDialog.Builder(activity);
				builder.setMessage("Authorization Required For Update");
				builder.setPositiveButton("Continue",
						new DialogInterface.OnClickListener() {
							public void onClick(DialogInterface dialog, int which) {
								AuthHelper.authorize(activity);
							}
						});
				builder.setNegativeButton("No thanks",
						new DialogInterface.OnClickListener() {
							public void onClick(DialogInterface dialog, int which) {
								dialog.dismiss();
							}
						});
				builder.setOnCancelListener(new OnCancelListener() {
					public void onCancel(DialogInterface dialog) {
						dialog.dismiss();
						activity.finish();
					}
				});
				builder.setCancelable(false);
				builder.show();
			} else {
				AuthHelper.authorize(activity);
			}

	}

	public static void checkForAnonymousUpdate(Activity activity, boolean promptForDownload)
	{
		//TODO: check if we're already processing the update / downloading / installing anything. Shouldn't be an issue as long as there's enough time between calls.
		UpdateTask updateTask = new UpdateTask(activity, false, promptForDownload);
		updateTask.execute();
	}
		
	/**
	 * Class to check for updates asychronously, will automatically kick off a download in the event that one is available and confirmation prompting is disabled.<br>
	 * If the requireAuthCredentials flag is set to true (default is false) then the update check will hard-check for authentication of the activity first. Potentially prompting a login dialog.
	 * @author andrewtremblay
	 */
	static class UpdateTask extends AsyncTask<Void, Void, Void> {
		Activity activity;
		ProgressDialog progress;
		public boolean requireAuthCredentials = false; // default anonymous
		public boolean promptDownloadConfirm = true; // default noisy
		
		
		public UpdateTask(Activity _activity, boolean hardCheckAuthenticate, boolean promptForDownload) {
			this.activity = _activity;
			//this.requireAuthCredentials = hardCheckAuthenticate; 
			this.promptDownloadConfirm = promptForDownload;
		}


		
		@Override
		protected void onPreExecute() {
			//check if we already have an apk downloaded but haven't installed. No need to redownload if we do.
		}
		
		@Override
		protected Void doInBackground(Void... params) {
			HttpResponse response = UpdatesHelper.getUpdateResponse(this.requireAuthCredentials);
			
			if(response != null){
				Log.d(AppBlade.LogTag, String.format("Response status:%s", response.getStatusLine()));
			}
			handleResponse(response);
			return null;
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
					Log.d(AppBlade.LogTag, String.format("UpdateTask response OK %s", data));
					JSONObject json = new JSONObject(data);
					int timeToLive = json.getInt("ttl");
					if(json.has("update")) {
						JSONObject update = json.getJSONObject("update");
						if(update != null) {
							if(this.promptDownloadConfirm)
							{
								UpdatesHelper.confirmUpdate(this.activity, update);
							}
							else
							{
								UpdatesHelper.processUpdate(this.activity, update);								
							}
						}
					}
				}
				catch (IOException ex) { ex.printStackTrace(); }
				catch (JSONException ex) { ex.printStackTrace(); }
			}
		}
	}
		
	/**
	 * Synchronized generator for device authorization. 
	 * @return HttpResponse for kill switch api.
	 */
	private static synchronized HttpResponse getUpdateResponse(boolean authorize) {
		HttpResponse response = null;
		HttpClient client = HttpClientProvider.newInstance(SystemUtils.UserAgent);
		String urlPath = String.format(WebServiceHelper.ServicePathUpdateFormat, AppBlade.appInfo.AppId);
		String url = WebServiceHelper.getUrl(urlPath);
		String authHeader = WebServiceHelper.getHMACAuthHeader(AppBlade.appInfo, urlPath, null, HttpMethod.GET);
		try {
			HttpGet request = new HttpGet();
			request.setURI(new URI(url));
			request.addHeader("Authorization", authHeader);
			if(!authorize){
				request.addHeader("USE_ANONYMOUS", "true");
			}
			WebServiceHelper.addCommonHeaders(request);
		    response = client.execute(request);
		}
		catch(Exception ex)
		{
			Log.e(AppBlade.LogTag, String.format("%s %s", ex.getClass().getSimpleName(), ex.getMessage()));
		}
		
		return response;
	}

	/**
	 * Confirm with the user that an update should be downloaded. Kicks off {@link #processUpdate(Activity, JSONObject)} on the go ahead.
	 * @param activity
	 * @param update
	 */
	private static void confirmUpdate(final Activity activity, final JSONObject update) {
		activity.runOnUiThread(new Runnable() {
			public void run() {
				AlertDialog.Builder builder = new AlertDialog.Builder(activity);
				builder.setMessage("A new version is available on AppBlade");
				builder.setPositiveButton("Download", new DialogInterface.OnClickListener() {
					public void onClick(DialogInterface dialog, int which) {
						Thread thread = new Thread()
						{
						    @Override
						    public void run() {
						        try {
						        	processUpdate(activity, update);			
						        }                               
						        catch (Exception e) {
						            e.printStackTrace();
						        }
						    }
						};

						thread.start(); 						
					}
				});
				builder.setNegativeButton("Not Now", null);
				builder.create().show();
			}
		});
	}

	/**
	 * We have been given a response from the server through {@link #getUpdateResponse(boolean)} that an update is available.<br>
	 * Kick off an update and install if we have the write permissions. Notify the user of the download if we don't have write permissions.
	 * <br>Used in {@link com.appblade.framework.authenticate.KillSwitch}
	 * @param activity Activity to handle the notification or installation.
	 * @param update JSONObject containing the necessary update information.
	 */
	public static void processUpdate(Activity activity, JSONObject update) {
		PackageInfo pkg = AppBlade.getPackageInfo();
		String permission = Manifest.permission.WRITE_EXTERNAL_STORAGE;
		if(SystemUtils.hasPermission(pkg, permission)) {
			notifyDownloading(activity);
			Log.d(AppBlade.LogTag, "UpdatesHelper.processUpdate - permission to write to sd, downloading...");
			downloadUpdate(activity, update);
		}
		else {
			Log.d(AppBlade.LogTag, "UpdatesHelper.processUpdate - no permission to write to sd, notifying...");
			notifyUpdate(activity, update);
		}
	}

	private static void downloadUpdate(Activity context, JSONObject update) {
		File dir = getRootDirectory();
		File file = new File(dir, "install.apk");
		
		long expectedFileSize = 0;
		long totalBytesRead = 0;
		boolean savedSuccessfully = false;
		String url = null;
		
		InputStream inputStream = null;
		BufferedInputStream bufferedInputStream = null;
		FileOutputStream fileOutput = null;
		BufferedOutputStream bufferedOutput = null;
		
		try
		{
			url = update.getString("url");	
			url = url.replaceFirst("http://", "https://");
			
			expectedFileSize = HttpUtils.getHeaderAsLong(url, HttpUtils.HeaderContentLength);
			Log.d(AppBlade.LogTag, String.format("Downloading %d bytes from %s", expectedFileSize, url));
			
			HttpGet request = new HttpGet();
			request.setURI(new URI(url));
			HttpClient client = HttpClientProvider.newInstance(SystemUtils.UserAgent);
			HttpResponse response = client.execute(request);
			if(response != null) {
				
				if(file.exists())
					file.delete();
				file.createNewFile();
				
				inputStream = response.getEntity().getContent();
				bufferedInputStream = new BufferedInputStream(inputStream);
				
		    	fileOutput = new FileOutputStream(file);
		    	bufferedOutput = new BufferedOutputStream(fileOutput);
		    	
		        byte[] buffer = new byte[1024 * 16];
		        totalBytesRead = 0;
		    	
		    	while(true)
		    	{
		    		synchronized (buffer)
		    		{
			    		int bytesRead = bufferedInputStream.read(buffer);
			    		if(bytesRead > 0) {
				    		bufferedOutput.write(buffer, 0, bytesRead);
			    			totalBytesRead += bytesRead;
			    		}
			    		else {
			    			// end of file...
			    			savedSuccessfully = true;
			    			break;
			    		}
		    		}
		    	}
			}
		}
		catch(JSONException ex) { ex.printStackTrace(); }
		catch(URISyntaxException ex) { ex.printStackTrace(); }
		catch(ClientProtocolException ex) { ex.printStackTrace(); }
		catch(IOException ex) { ex.printStackTrace(); }
		finally
		{
			NotificationManager notificationManager =
					(NotificationManager) context.getApplicationContext().getSystemService(Context.NOTIFICATION_SERVICE);
			notificationManager.cancel(NotificationNewVersionDownloading);
			
			IOUtils.safeClose(bufferedInputStream);
			IOUtils.safeClose(bufferedOutput);
			
			Log.d(AppBlade.LogTag, String.format("%d bytes downloaded from %s", totalBytesRead, url));
			
			if(expectedFileSize > 0 && expectedFileSize == totalBytesRead)
				savedSuccessfully = true;
			
			if(savedSuccessfully) {
				Log.d(AppBlade.LogTag, String.format("Download succeeded, opening file at %s", file.getAbsolutePath()));
				open(context, file);
			}
			else {
				Log.d(AppBlade.LogTag, "Download failed, fall back to notifying and let the browser handle it");
				notifyUpdate(context, update);
				KillSwitch.kill(context);
			}
		}
	}

	//File I/O
	private static void open(final Activity context, final File file) {
		context.runOnUiThread(new Runnable() {
			public void run() {
				AlertDialog.Builder builder = new AlertDialog.Builder(context);
				builder.setMessage("A new version has been downloaded, click OK to install");
				builder.setPositiveButton("OK", new DialogInterface.OnClickListener() {
					public void onClick(DialogInterface dialog, int which) {
						Intent intent = new Intent(Intent.ACTION_VIEW);
						intent.setDataAndType(Uri.fromFile(file), "application/vnd.android.package-archive");
						context.startActivity(intent);
						KillSwitch.kill(context);
					}
				});
				builder.setOnCancelListener(new OnCancelListener() {
					public void onCancel(DialogInterface dialog) {
						//KillSwitch.kill(context);
					}
				});
				builder.create().show();
			}
		});
	}
	
	private static File getRootDirectory() {
		String rootDir = ".appblade";
		String path = String.format("%s%s%s",
				Environment.getExternalStorageDirectory().getAbsolutePath(), "/",
				rootDir);
		File dir = new File(path);
		dir.mkdirs();
		return dir;
	}
	
	//Notifiers
	@SuppressWarnings("deprecation")
	private static void notifyDownloading(Activity context) {
		Intent blank = new Intent();
		PendingIntent contentIntent = PendingIntent.getBroadcast(context, 0, blank, 0);
		
		String message = "Downloading update...";
		NotificationManager notificationManager =
				(NotificationManager) context.getApplicationContext().getSystemService(Context.NOTIFICATION_SERVICE);
		Notification notification = new Notification(R.drawable.notification_icon, message, System.currentTimeMillis());
		notification.setLatestEventInfo(context.getApplicationContext(), "Update", message, contentIntent);
		notificationManager.notify(NotificationNewVersionDownloading, notification);
	}

	@SuppressWarnings("deprecation")
	private static void notifyUpdate(Activity context, JSONObject update) {
		Log.d(AppBlade.LogTag, "UpdatesHelper.notifyUpdate");
		try
		{
			String url = update.getString("url");
			String message = update.getString("message");
			
			if(context != null) {
				Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
				PendingIntent contentIntent = PendingIntent.getActivity(context.getApplicationContext(), 0, intent, PendingIntent.FLAG_UPDATE_CURRENT);
				
				NotificationManager notificationManager =
						(NotificationManager) context.getApplicationContext().getSystemService(Context.NOTIFICATION_SERVICE);
				Notification notification = new Notification(R.drawable.notification_icon, message, System.currentTimeMillis());
				notification.setLatestEventInfo(context.getApplicationContext(), "Update", message, contentIntent);
				notificationManager.notify(NotificationNewVersion, notification);
			}
				
		}
		catch(JSONException ex) { ex.printStackTrace(); }
	}

}
