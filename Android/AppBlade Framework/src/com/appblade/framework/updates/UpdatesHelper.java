package com.appblade.framework.updates;

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

import android.Manifest;
import android.annotation.TargetApi;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.DownloadManager;
//import android.app.ProgressDialog;
//import android.app.Notification;
import android.app.NotificationManager;
//import android.app.PendingIntent;
import android.content.Context;
import android.content.DialogInterface;
import android.content.DialogInterface.OnCancelListener;
import android.content.DialogInterface.OnDismissListener;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.content.pm.PackageInfo;
import android.database.Cursor;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Environment;
import android.util.Log;

import com.appblade.framework.AppBlade;
//import com.appblade.framework.R;
import com.appblade.framework.WebServiceHelper;
import com.appblade.framework.WebServiceHelper.HttpMethod;
import com.appblade.framework.authenticate.AuthHelper;
import com.appblade.framework.updates.DownloadProgressDialog.DownloadProgressDelegate;
import com.appblade.framework.utils.HttpClientProvider;
import com.appblade.framework.utils.HttpUtils;
import com.appblade.framework.utils.IOUtils;
import com.appblade.framework.utils.StringUtils;
import com.appblade.framework.utils.SystemUtils;

/**
 * Class containing functions that will handle a download and installation of an apk update for the given app.
 * @author rich.stern@raizlabs  
 * @author andrew.tremblay@raizlabs
 */
@TargetApi(Build.VERSION_CODES.HONEYCOMB)
public class UpdatesHelper {
	private static AlertDialog updateDialog = null;//for checking download process
	private static UpdateTask updateTask = null;//for checking download process
	private static Thread downloadThread = null; //for checking download process
	
//	private static final int NotificationNewVersion = 0;
	private static final int NotificationNewVersionDownloading = 1;	
	private static final String APK_MIMETYPE = "application/vnd.android.package-archive";

	
	private static final String PrefsKey = "AppBlade.UpdatesHelper.SharedPrefs";
	private static final String PrefsKeyTTL = "AppBlade.UpdatesHelper.TTL";
	private static final String PrefsKeyTTLUpdated = "AppBlade.UpdatesHelper.TTLUpdated";

	
	private static Long ttl = Long.MIN_VALUE;
	private static Long ttlLastUpdated = Long.MIN_VALUE;
	private static final int MillisPerHour = 1000 * 60 * 60;
	@SuppressWarnings("unused")
	private static final int MillisPerDay = MillisPerHour * 24;

	/**
	 * Update check that soft-checks for the best update method available. <br>
	 * If not authenticated, we checks with {@link #checkForAnonymousUpdate(Activity)}. <br> 
	 * @param activity the Activity to handle the update. Should belong to the same application context that was authenticated if authenticated updates are required. 
	 * @param promptForDownload 
	 */
	public static void checkForUpdate(Activity activity, boolean promptForDownload)
	{	//falls into the best behavior available. Currently Anonymous update is the only supported behavior. 
		checkForAnonymousUpdate(activity, promptForDownload, false);
	}


	/**
	 * Update check that soft-checks for the best update method available. <br>
	 * If we are still within the ttl of the last check, the update process is skipped. <br>
	 * If not authenticated, we check with {@link #checkForAnonymousUpdate(Activity)}. <br> 
	 * @param activity the Activity to handle the update. Should belong to the same application context that was authenticated if authenticated updates are required. 
	 * @param promptForDownload 
	 */
	public static void checkForUpdateWithTimeout(Activity activity, boolean promptForDownload)
	{	
		//falls into the best behavior available. Currently Anonymous update is the only supported behavior. 
		checkForAnonymousUpdate(activity, promptForDownload, false);
	}

	/**
	 * Checks the ttl against system time to see whether we need to update.
	 * @return If it is time to update.
	 */
	public static boolean shouldUpdate(Activity activity, boolean respectTimeout) {
		SharedPreferences prefs = activity.getSharedPreferences(PrefsKey, Context.MODE_PRIVATE);
		ttl = prefs.getLong(PrefsKeyTTL, ttl);
		ttlLastUpdated = prefs.getLong(PrefsKeyTTLUpdated, ttlLastUpdated);
		
		boolean shouldUpdate = true; //ever the optimist
		long now = System.currentTimeMillis();
		long timeToUpdate = (ttlLastUpdated + ttl);
		// If TTL is satisfied (we are within the time to live from the last time updated), do not require update
		if(timeToUpdate > now && respectTimeout)
		{
			shouldUpdate = false;
		}

		Log.v(AppBlade.LogTag, String.format("UpdatesHelper.shouldUpdate, ttl:%d, last updated:%d now:%d", ttl, ttlLastUpdated, now));
		Log.v(AppBlade.LogTag, String.format("UpdatesHelper.shouldUpdate? %b", shouldUpdate));
		
		
		//check if the activity is already in the process of checking/downloading/confirming the download 
		if(updateTask != null)
		{
			if(updateTask.getStatus() == AsyncTask.Status.PENDING || updateTask.getStatus() == AsyncTask.Status.RUNNING){
				shouldUpdate = false;
			}else if(updateTask.getStatus() == AsyncTask.Status.FINISHED){
				updateTask = null; //clean up the task since we don't need it anymore
			}
		}
		
		//or if we're already displaying a dialog
		if(updateDialog != null)
		{
			if(updateDialog.isShowing()){
				shouldUpdate = false;
			}else{
				updateDialog = null;
			}
		}
		
		if(downloadThread != null){   
			if(downloadThread.isAlive()){
				shouldUpdate = false;
			}else{
				downloadThread = null;
			}
		}
		
		return shouldUpdate;
	}
	

	
	/** <h2>NOT YET SUPPORTED BY THE API</h2>
	 * Authentication check that uses authorization credentials to determine if an update is available. <br> 
	 * Will prompt a login dialog if credentials are not immediately found to be available.
	 * Note that this is essentially unnecessary to call right after {@link AppBlade.authenticate(Activity)} since that handles authentication by default. 
	 * @param activity activity to check authorization and run the {@link UpdateTask}
	 * @param promptForDownload flag for whether we want to prompt the user before we start downloading the update, which is polite if they aren't on wifi or th eapk is very large. 
	 */
	public static void checkForAuthenticatedUpdate(Activity activity, boolean promptForDownload)
	{
		checkForAuthenticatedUpdate( activity, promptForDownload, true); //we respect TTL by default
	}	
	
	/**<h2>NOT YET SUPPORTED BY THE API</h2>
	 * Authentication check that uses authorization credentials to determine if an update is available. <br> 
	 * Will prompt a login dialog if credentials are not immediately found to be available.
	 * Note that this is essentially unnecessary to call right after {@link AppBlade.authenticate(Activity)} since that handles authentication by default. 
	 * @param activity activity to check authorization and run the {@link UpdateTask}
	 * @param promptForDownload flag for whether we want to prompt the user before we start downloading the update, which is polite if they aren't on wifi or th eapk is very large. 
	 * @param respectUpdateTtl flag for whether we want to respect the timeout the server last gave. 
	 */
	public static void checkForAuthenticatedUpdate(Activity activity, boolean promptForDownload, boolean respectUpdateTtl)
	{
		if(UpdatesHelper.shouldUpdate(activity, respectUpdateTtl)){
			if(AuthHelper.isAuthorized(activity))
			{
				updateTask = new UpdateTask(activity, true, promptForDownload);
				updateTask.execute();
			}
			else
			{
				UpdatesHelper.checkAuthorization(activity, true);
			}
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
				builder.setCancelable(false);
				updateDialog = builder.create();
				updateDialog.setOnDismissListener(new OnDismissListener() {
					public void onDismiss(DialogInterface dialog) {
						updateDialog = null;
					}
				});

				updateDialog.show();
			} else {
				AuthHelper.authorize(activity);
			}

	}

	public static void checkForAnonymousUpdate(Activity activity, boolean promptForDownload)
	{
		checkForAnonymousUpdate(activity, promptForDownload, true); //we respect TTL by default 
	}
	
	public static void checkForAnonymousUpdate(Activity activity, boolean promptForDownload, boolean respectUpdateTtl)
	{
		if(UpdatesHelper.shouldUpdate(activity, respectUpdateTtl)){
			updateTask = new UpdateTask(activity, false, promptForDownload);
			updateTask.execute();
		}
	}



	
/**
 * Synchronized generator for device authorization. 
 * @return HttpResponse for kill switch api.
 */
public static synchronized HttpResponse getUpdateResponse(boolean authorize) {
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
		
		Log.v(AppBlade.LogTag, "DEVICE_FINGERPRINT: " + request.getFirstHeader("DEVICE_FINGERPRINT"));
		Log.v(AppBlade.LogTag, "android_id: " + request.getFirstHeader("android_id"));
	    response = client.execute(request);
		Log.e(AppBlade.LogTag, String.format("%s", request.getURI() ) );
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
 * @param delegate ProgressDelegate that handles progress view
 */
public static void confirmUpdate(final Activity activity, final JSONObject update, final DownloadProgressDelegate delegate) {
	activity.runOnUiThread(new Runnable() {
		public void run() {
			AlertDialog.Builder builder = new AlertDialog.Builder(activity);
			builder.setMessage("A new version is available on AppBlade");
			builder.setPositiveButton("Download", new DialogInterface.OnClickListener() {
				public void onClick(DialogInterface dialog, int which) {
					Thread processUpdateThread = new Thread()
					{
					    @Override
					    public void run() {
					        try {
					        	processUpdate(activity, update, delegate);
					        }                               
					        catch (Exception e) {
					            e.printStackTrace();
					        }
					    }
					};
					processUpdateThread.start(); 						
				}
			});

			builder.setNegativeButton("Not Now", null);
			updateDialog = builder.create();
			updateDialog.setOnDismissListener(new OnDismissListener() {
				public void onDismiss(DialogInterface dialog) {
					updateDialog = null;
				}
			});

			updateDialog.show();
		}
	});
}

/**
 * We have been given a response from the server through {@link #getUpdateResponse(boolean)} that an update is available.<br>
 * Kick off an update and install if we have the write permissions. Notify the user of the download if we don't have write permissions.
 * <br>Used in {@link com.appblade.framework.authenticate.KillSwitch}
 * @param activity Activity to handle the notification or installation.
 * @param update JSONObject containing the necessary update information (like where to install).
 * @param delegate ProgressDelegate that handles progress view
 */
public static void processUpdate(Activity activity, JSONObject update, DownloadProgressDelegate delegate) {
	if(UpdatesHelper.fileFromJsonNotDownloadedYet(update))
	{
		if(UpdatesHelper.appCanDownload()) {
			notifyDownloading(activity);
			Log.v(AppBlade.LogTag, "UpdatesHelper.processUpdate - permission to write to sd, processing download");
			downloadUpdate(activity, update, delegate);
		}
		else {
			Log.v(AppBlade.LogTag, "UpdatesHelper.processUpdate - download available but there are no permissions to write to sd, notifying...");
			notifyUpdate(activity, update);
		}
	}else{
		Log.v(AppBlade.LogTag, "UpdatesHelper.processUpdate - download available and already exists");
		//we have this file already, open it/notify
		try {
			File downloadedFile = UpdatesHelper.fileFromUpdateJSON(update);		
			UpdatesHelper.handleDownloadedFile(activity, downloadedFile);
		} catch (JSONException e) {
			Log.w(AppBlade.LogTag, "Error opening file from update for installation! ", e);
		}
	}
}

private static void handleDownloadedFile(Activity activity, File downloadedFile) {
	//if(we want to notify)
	//UpdatesHelper.openWithAlert(activity, downloadedFile); //push this check to a preference or a setting in the app. Can't keep passing these flags around!
	
	Intent intent = new Intent(Intent.ACTION_VIEW);
	intent.setDataAndType(Uri.fromFile(downloadedFile), APK_MIMETYPE );
	activity.startActivity(intent);

}


private static boolean appCanDownload() {
	//currently only checks for valid permissions, since that's the only crucial one 
	PackageInfo pkg = AppBlade.getPackageInfo();
	boolean hasAllPackagePermissions = SystemUtils.hasPermission(pkg, Manifest.permission.WRITE_EXTERNAL_STORAGE) && SystemUtils.hasPermission(pkg, Manifest.permission.INTERNET);
	//TODO:add additional stipulations (like only downloading off of a WiFi connection, or if we have enough space required)
	return hasAllPackagePermissions;
}

private static boolean isCanceled = false;

/**
 * Attempts to download the update given the response from the server.
 * @param context Activity to handle the download and notifications
 * @param update the JSONObject that the server returned. 
 * @param delegate ProgressDelegate that handles progress view
 */
public static void downloadUpdate(Activity context, JSONObject update, DownloadProgressDelegate delegate) {
	File fileDownloadLocation = null; //filename is determined by the server

	long expectedFileSize = 0;
	long totalBytesRead = 0;
	boolean savedSuccessfully = false;
	String url = null;
	
	InputStream inputStream = null;
	BufferedInputStream bufferedInputStream = null;
	FileOutputStream fileOutput = null;
	BufferedOutputStream bufferedOutput = null;
	isCanceled = false;
	
	if (delegate != null) {
		delegate.showProgress();
		delegate.setOnCancelListener(new OnCancelListener() {
			public void onCancel(DialogInterface dialog) {
				isCanceled = true;
			}
		});
	}
	try
	{
		fileDownloadLocation = UpdatesHelper.fileFromUpdateJSON(update);
		url = update.getString("url");	
		
		expectedFileSize = HttpUtils.getHeaderAsLong(url, HttpUtils.HeaderContentLength);
		Log.v(AppBlade.LogTag, String.format("Downloading %d bytes from %s", expectedFileSize, url));
		
		HttpGet request = new HttpGet();
		request.setURI(new URI(url));
		WebServiceHelper.addCommonHeaders(request);
		HttpClient client = HttpClientProvider.newInstance(SystemUtils.UserAgent);
		HttpResponse response = client.execute(request);
		if(HttpUtils.isOK(response)) {
			if(fileDownloadLocation.exists()){ //this location needs to start empty
					UpdatesHelper.deleteFileAndNotifyDownloadManager(fileDownloadLocation, context);
			}
			fileDownloadLocation.createNewFile();
			
			inputStream = response.getEntity().getContent();
			bufferedInputStream = new BufferedInputStream(inputStream);
			
			//fileOutput = context.getApplicationContext().openFileOutput(fileDownloadLocation.getName(), Context.MODE_WORLD_READABLE);
	    	
			
	    	fileOutput = new FileOutputStream(fileDownloadLocation);
	    	bufferedOutput = new BufferedOutputStream(fileOutput);
			Log.v(AppBlade.LogTag, String.format("Downloading to %s ", fileDownloadLocation.getAbsolutePath()));
	    	
	        byte[] buffer = new byte[1024 * 16];
	        totalBytesRead = 0;
	    	
	    	while(!isCanceled)
	    	{
	    		synchronized (buffer)
	    		{
		    		int bytesRead = bufferedInputStream.read(buffer);
		    		if(bytesRead > 0) {
			    		bufferedOutput.write(buffer, 0, bytesRead);
		    			totalBytesRead += bytesRead;
		    			if (delegate != null) {
		    				delegate.updateProgress((int)(100.0*totalBytesRead/expectedFileSize));
		    			}
		    		}
		    		else {
		    			// end of file...
		    			savedSuccessfully = true; //ever the optimist
		    			break;
		    		}
	    		}
	    	}
	    	
	    	if (!isCanceled) {
		    	
		    	bufferedOutput.flush();
				IOUtils.safeClose(bufferedInputStream);
				IOUtils.safeClose(bufferedOutput);
				IOUtils.safeClose(fileOutput);
		    	
				if(expectedFileSize > 0 && expectedFileSize == totalBytesRead)
					savedSuccessfully = true;
	
				
		    	if(savedSuccessfully)
		    	{
		    		//check md5 of the local file with the one we expect from the server, don't bother if we already know the bytestream was interrupted
		    		String md5OnServer = update.getString("md5");
		    		String md5Local = StringUtils.md5FromFile(fileDownloadLocation);
		    		Log.v(AppBlade.LogTag, "" + fileDownloadLocation.getAbsolutePath() + " " + (fileDownloadLocation.exists() ? "exists" : "does not exist" ) );
		    		Log.v(AppBlade.LogTag, "does md5 " +  md5OnServer + " = " + md5Local + "  ? " + (md5OnServer.equals(md5Local) ? "equal" : "not equal" ));
		    		savedSuccessfully = md5OnServer.equals(md5Local);
		    		if(!savedSuccessfully){
		    			notifyRetryDownload(context, update);
		    		}
		    		UpdatesHelper.addFileAndNotifyDownloadManager(fileDownloadLocation, context, md5OnServer, totalBytesRead);
		    	}
	    	}
	    	
		}
		else
		{
			notifyRetryDownload(context, update);
		}
	}
	catch(JSONException ex) { Log.w(AppBlade.LogTag, "JSON error when downloading update ", ex); }
	catch(URISyntaxException ex) { Log.w(AppBlade.LogTag, "URI Syntax error when downloading update ", ex); }
	catch(ClientProtocolException ex) { Log.w(AppBlade.LogTag, "Client protocol error when downloading update ", ex); }
	catch(IOException ex) { Log.w(AppBlade.LogTag, "IO error when downloading update ", ex); }
	finally
	{
		if (delegate != null) {
			delegate.dismissProgress();
		}
		NotificationManager notificationManager =
				(NotificationManager) context.getApplicationContext().getSystemService(Context.NOTIFICATION_SERVICE);
		notificationManager.cancel(NotificationNewVersionDownloading);		
		if(savedSuccessfully && fileDownloadLocation != null) {
			Log.v(AppBlade.LogTag, String.format("Download succeeded, opening file at %s", fileDownloadLocation.getAbsolutePath()));
			UpdatesHelper.handleDownloadedFile(context, fileDownloadLocation);
		}
	}
}
	
	private static void notifyRetryDownload(final Activity context, final JSONObject update) 
	{
		Log.v(AppBlade.LogTag, "Download failed, notify the user");

		context.runOnUiThread(new Runnable() {
			public void run() {
				AlertDialog.Builder builder = new AlertDialog.Builder(context);
				builder.setMessage("There was a problem downloading an update for your app.");
				builder.setPositiveButton("Retry", new DialogInterface.OnClickListener() {
					public void onClick(DialogInterface dialog, int which) {
						if(updateTask != null && updateTask.cancel(true)){ 
							Log.v(AppBlade.LogTag, "Cancelling existing UpdateTask!"); //ensure the previous task is finished
						}
						updateTask = new UpdateTask(context, false, false);
						updateTask.execute();
					}
				});
				builder.setNegativeButton("Later", new DialogInterface.OnClickListener() {
					public void onClick(DialogInterface dialog, int which) {
						notifyUpdate(context, update);
					}
				});
				updateDialog = builder.create();
				updateDialog.setOnDismissListener(new OnDismissListener() {
					public void onDismiss(DialogInterface dialog) {
						dialog = null;
					}
				});

				updateDialog.show();
			}
		});

		
	}


	/**
	 * A helper function to get a readable local file location from the update response from the AppBlade server
	 * @param update The "update" object within the JSON data that AppBlade optionally returns when a update is available. 
	 * @return A readable file location form the bundle_identifier value in the update JSON.
	 * @throws JSONException when the update parameter is invalid.
	 */
	public static File fileFromUpdateJSON(JSONObject update) throws JSONException {
		String newFileName = SystemUtils.getReadableApkFileNameFromPackageName(update.getString("bundle_identifier"));
		return new File(UpdatesHelper.getRootDirectory(), newFileName); //might exist
	}



	//File I/O
	@SuppressWarnings("unused")
	private static void openWithAlert(final Activity activity, final File file) {
		activity.runOnUiThread(new Runnable() {
			public void run() {
				AlertDialog.Builder builder = new AlertDialog.Builder(activity);
				builder.setMessage("A new version has been downloaded, click OK to install");
				builder.setPositiveButton("OK", new DialogInterface.OnClickListener() {
					public void onClick(DialogInterface dialog, int which) {
						Intent intent = new Intent(Intent.ACTION_VIEW);
						intent.setDataAndType(Uri.fromFile(file), APK_MIMETYPE );
						activity.startActivity(intent);
					}
				});
				builder.setNegativeButton("Later", new DialogInterface.OnClickListener() {
					public void onClick(DialogInterface dialog, int which) {
						dialog.dismiss();
					}
				});
				updateDialog = builder.create();				
				updateDialog.setOnDismissListener(new OnDismissListener() {
					public void onDismiss(DialogInterface dialog) {
						updateDialog = null;
					}
				});
				updateDialog.show();
			}
		});
	}
	
	private static File getRootDirectory() {
		String path = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).getAbsolutePath();
		Log.d(AppBlade.LogTag, "getRootDirectory " + path);
		File dir = new File(path);
		if(!dir.exists()){
			dir.mkdirs();
		}
		return dir;
	}
	
	/**
	 * The current location of the downloaded file (does not check existence)
	 * @return new instance of the unique downloaded file location for this package
	 */
	public static File downloadedFile()
	{
		String packageDir = "error_no_package_name.apk";
		if(AppBlade.hasPackageInfo()){
			packageDir = SystemUtils.getReadableApkFileNameFromPackageName(AppBlade.getPackageInfo().packageName);
		}
		File rootDir = UpdatesHelper.getRootDirectory(); 
		return new File(rootDir, packageDir);
	}
	
	/**
	 * DO NOT CHANGE f.getName(). It is required for the deletion code.
	 * @param f
	 * @param context
	 * @param description
	 * @param length
	 */
	@TargetApi(Build.VERSION_CODES.HONEYCOMB_MR1)
	private static void addFileAndNotifyDownloadManager(File f, Context context, String description, long length) {
		if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB_MR1 && context != null) //send to download manager if we can, HONEYCOMB_MR1 and above only
		{
			DownloadManager manager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
			manager.addCompletedDownload(f.getName(), description, true, APK_MIMETYPE, f.getAbsolutePath(), length, true);
		}
	}
	
	/**
	 * Deletes the file and notifies the DownloadManager that the file no longer exists.
	 * @param f file to delete
	 * @param context the context to use to notify the download manager
	 * @return
	 */
	private static boolean deleteFileAndNotifyDownloadManager(File f, Context context) {
		boolean deleted = f.delete();
		if(deleted)
		{
    		if(Build.VERSION.SDK_INT >= 12 && context != null) //send to download manager if we can, HONEYCOMB_MR1 and above only
    		{
    			DownloadManager manager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
    			DownloadManager.Query q = new DownloadManager.Query();
    			q.setFilterByStatus(DownloadManager.STATUS_SUCCESSFUL);
    			Cursor c = manager.query(q);
    			int idIndex = c.getColumnIndexOrThrow(DownloadManager.COLUMN_ID);
    			int titleIndex = c.getColumnIndexOrThrow(DownloadManager.COLUMN_TITLE);
    			if(c.moveToFirst() && idIndex >= 0){
    				long downloadId = c.getLong(idIndex);
    				String downloadTitle = c.getString(titleIndex);
    				if(f.getName().equals(downloadTitle))
    					manager.remove(downloadId);
    		        while(c.moveToNext())
    		        {
        				downloadId = c.getLong(idIndex);
        				if(f.getName().equals(downloadTitle))
        					manager.remove(downloadId);
        		    }
    			}
    		}
		}
		return deleted;
	}


	/**
	 * One liner for deleting the downloaded update file for this app.
	 */
	public static void deleteCurrentFile(Context context) {
		File currentFile = UpdatesHelper.downloadedFile();
		if(UpdatesHelper.deleteFileAndNotifyDownloadManager(currentFile, context))
		{
			Log.v(AppBlade.LogTag, "Deleted now-unnecessary apk: " + currentFile.getName());
			
		}
		Log.v(AppBlade.LogTag, "Everything up-to-date");		
	}
	
	//Notifiers
//	@SuppressWarnings("deprecation")
	private static void notifyDownloading(Context context) {
//			Intent blank = new Intent();
//			PendingIntent contentIntent = PendingIntent.getBroadcast(context, 0, blank, 0);
//			String message = "Downloading update...";
//			NotificationManager notificationManager =
//					(NotificationManager) context.getApplicationContext().getSystemService(Context.NOTIFICATION_SERVICE);
//			Notification notification = new Notification(R.drawable.notification_icon, message, System.currentTimeMillis());
//			notification.setLatestEventInfo(context.getApplicationContext(), "Update", message, contentIntent);
//			notificationManager.notify(NotificationNewVersionDownloading, notification);
	}

//	@SuppressWarnings("deprecation")
	private static void notifyUpdate(Context context, JSONObject update) {
//		Log.v(AppBlade.LogTag, "UpdatesHelper.notifyUpdate");
//		try
//		{
//			String url = update.getString("url");
//			String message = update.getString("message");
//			
//			if(context != null) {
////				Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
////				PendingIntent contentIntent = PendingIntent.getActivity(context.getApplicationContext(), 0, intent, PendingIntent.FLAG_UPDATE_CURRENT);
////				
////				NotificationManager notificationManager =
////						(NotificationManager) context.getApplicationContext().getSystemService(Context.NOTIFICATION_SERVICE);
////				Notification notification = new Notification(R.drawable.notification_icon, message, System.currentTimeMillis());
////				notification.setLatestEventInfo(context.getApplicationContext(), "Update", message, contentIntent);
////				notificationManager.notify(NotificationNewVersion, notification);
//			}
//				
//		}
//		catch(JSONException ex) { Log.w(AppBlade.LogTag, "JSON error when notifying of update ", ex); }
	}

	//TTL handling 
	
	/**
	 * Stores ttl and ttlLastUpdated in their static locations.
	 * @param timeToLive
	 */
	public static void saveTtl(long timeToLive, Context context) {
		ttl = timeToLive;
		ttlLastUpdated = System.currentTimeMillis();
		SharedPreferences prefs = context.getSharedPreferences(PrefsKey, Context.MODE_PRIVATE);
		Editor editor = prefs.edit();
		editor.putLong(PrefsKeyTTL, ttl);
		editor.putLong(PrefsKeyTTLUpdated, ttlLastUpdated);
		editor.commit();
	}
	
	/**
	 * Loads ttl from static location. Does not assign to the private variable.
	 * @param context
	 * @return the value of stored ttl
	 */
	public int loadTtl(Context context) {
		SharedPreferences prefs = context.getSharedPreferences(PrefsKey, Context.MODE_PRIVATE);
		return prefs.getInt(PrefsKeyTTL, Integer.MIN_VALUE);
	}
	
	/**
	 * Loads TtlLastUpdated from static location. Does not assign to the private variable.
	 * @param context
	 * @return the value the ttl was last updated
	 */
	public int loadTtlLastUpdated(Context context) {
		SharedPreferences prefs = context.getSharedPreferences(PrefsKey, Context.MODE_PRIVATE);
		return prefs.getInt(PrefsKeyTTLUpdated, Integer.MIN_VALUE);
	}


	//checks not only existence, but validity
	public static boolean fileFromJsonNotDownloadedYet(JSONObject update) {
		//check if we already have it, assume we don't 
		boolean notDownloadedYet = true;
		try {
			String md5OnServer = update.getString("md5");
			File destFile = UpdatesHelper.fileFromUpdateJSON(update);
			if(destFile.exists()){
				//stage one complete! check the hash.
				String md5Local = StringUtils.md5FromFile(destFile);
				if(md5Local.equals(md5OnServer) && !md5Local.equals(StringUtils.md5OfNull)){ 
					//a match! and it's not a null of something!
					notDownloadedYet = false;
				}
			}
		} catch (JSONException e) {
			Log.w(AppBlade.LogTag, "Couldn't check file at update JSON", e);
		}
		return notDownloadedYet;
	}
	
	
}
