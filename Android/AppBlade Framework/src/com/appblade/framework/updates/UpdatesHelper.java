package com.appblade.framework.updates;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
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
import android.app.Activity;
import android.app.AlertDialog;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.DialogInterface;
import android.content.DialogInterface.OnCancelListener;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.content.pm.PackageInfo;
import android.net.Uri;
import android.os.Environment;
import android.util.Log;

import com.appblade.framework.AppBlade;
import com.appblade.framework.R;
import com.appblade.framework.WebServiceHelper;
import com.appblade.framework.WebServiceHelper.HttpMethod;
import com.appblade.framework.authenticate.AuthHelper;
import com.appblade.framework.authenticate.KillSwitch;
import com.appblade.framework.utils.HttpClientProvider;
import com.appblade.framework.utils.HttpUtils;
import com.appblade.framework.utils.IOUtils;
import com.appblade.framework.utils.StringUtils;
import com.appblade.framework.utils.SystemUtils;

/**
 * Class containing functions that will handle a download and installation of an apk update for the given app.
 * @author rich.stern@raizlabs  
 * @author andrew.tremblay@raizlabs
 * @see KillSwitch
 */
public class UpdatesHelper {
	private static final int NotificationNewVersion = 0;
	private static final int NotificationNewVersionDownloading = 1;	

	
	private static final String PrefsKey = "AppBlade.UpdatesHelper.SharedPrefs";
	private static final String PrefsKeyTTL = "AppBlade.UpdatesHelper.TTL";
	private static final String PrefsKeyTTLUpdated = "AppBlade.UpdatesHelper.TTLUpdated";

	
	private static int ttl = Integer.MIN_VALUE;
	private static long ttlLastUpdated = Long.MIN_VALUE;
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
		checkForAnonymousUpdate(activity, promptForDownload);
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
		if(UpdatesHelper.shouldUpdate(activity)){
			checkForAnonymousUpdate(activity, promptForDownload);
		}
	}

	/**
	 * Checks the ttl against system time to see whether we need to update.
	 * @return If it is time to update.
	 */
	public static boolean shouldUpdate(Activity activity) {
		SharedPreferences prefs = activity.getSharedPreferences(PrefsKey, Context.MODE_PRIVATE);
		ttl = prefs.getInt(PrefsKeyTTL, ttl);
		ttlLastUpdated = prefs.getLong(PrefsKeyTTLUpdated, ttlLastUpdated);
		
		boolean shouldUpdate = true;
		long now = System.currentTimeMillis();
		long timeTTLUpdates = ttl + ttlLastUpdated;
		
		// If we have updated TTL value from AppBlade within the last hour, do not require update
		if(timeTTLUpdates > (now - MillisPerHour))
			shouldUpdate = false;
		
		// If TTL is satisfied (we are within the time to live from the last time updated), do not require update
		else if((ttlLastUpdated + ttl) > now)
			shouldUpdate = false;

		Log.d(AppBlade.LogTag, String.format("KillSwitch.shouldUpdate, ttl:%d, last updated:%d now:%d", ttl, ttlLastUpdated, now));
		Log.d(AppBlade.LogTag, String.format("KillSwitch.shouldUpdate? %b", shouldUpdate));
		
		return shouldUpdate;
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
		
		Log.d(AppBlade.LogTag, "DEVICE_FINGERPRINT: " + request.getFirstHeader("DEVICE_FINGERPRINT"));
		Log.d(AppBlade.LogTag, "android_id: " + request.getFirstHeader("android_id"));
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
 */
public static void confirmUpdate(final Activity activity, final JSONObject update) {
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
 * @param update JSONObject containing the necessary update information (like where to install).
 */
public static void processUpdate(Activity activity, JSONObject update) {
	PackageInfo pkg = AppBlade.getPackageInfo();
	String permission = Manifest.permission.WRITE_EXTERNAL_STORAGE;
	if(SystemUtils.hasPermission(pkg, permission)) {
		notifyDownloading(activity);
		Log.i(AppBlade.LogTag, "UpdatesHelper.processUpdate - permission to write to sd, processing download");
		downloadUpdate(activity, update);
	}
	else {
		Log.i(AppBlade.LogTag, "UpdatesHelper.processUpdate - download available but there are no permissions to write to sd, notifying...");
		notifyUpdate(activity, update);
	}
}

private static void downloadUpdate(Activity context, JSONObject update) {
	File fileDownloadLocation = null; //filename is determined by the server

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
		fileDownloadLocation = UpdatesHelper.fileFromUpdateJSON(update);
		url = update.getString("url");	
		
		expectedFileSize = HttpUtils.getHeaderAsLong(url, HttpUtils.HeaderContentLength);
		Log.d(AppBlade.LogTag, String.format("Downloading %d bytes from %s", expectedFileSize, url));
		
		HttpGet request = new HttpGet();
		request.setURI(new URI(url));
		WebServiceHelper.addCommonHeaders(request);
		HttpClient client = HttpClientProvider.newInstance(SystemUtils.UserAgent);
		HttpResponse response = client.execute(request);
		if(response != null) {
			
			if(fileDownloadLocation.exists()) //this location needs to start empty
				fileDownloadLocation.delete();
			fileDownloadLocation.createNewFile();
			
			inputStream = response.getEntity().getContent();
			bufferedInputStream = new BufferedInputStream(inputStream);
			
	    	fileOutput = new FileOutputStream(fileDownloadLocation);
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
		    			savedSuccessfully = true; //ever the optimist
		    			break;
		    		}
	    		}
	    	}
	    	if(savedSuccessfully)
	    	{
	    		//check md5 of the local file with the one we expect from the server, don't bother if we already know the bytestream was interrupted
	    		String md5OnServer = update.getString("md5");
	    		String md5Local = StringUtils.md5FromFile(fileDownloadLocation);
	    		Log.d(AppBlade.LogTag, "does md5 " +  md5OnServer + " = " + md5Local + "  ? ");
	    		savedSuccessfully = md5OnServer.equals(md5Local);
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
		
		if(savedSuccessfully && fileDownloadLocation != null) {
			Log.d(AppBlade.LogTag, String.format("Download succeeded, opening file at %s", fileDownloadLocation.getAbsolutePath()));
			openWithAlert(context, fileDownloadLocation);
		}
		else {
			Log.d(AppBlade.LogTag, "Download failed, fall back to notifying and let the browser handle it");
			notifyUpdate(context, update);
		}
	}
}

public static File fileFromUpdateJSON(JSONObject update) throws JSONException {
	String identifierOnServer = update.getString("bundle_identifier");
	String newFileName = String.format("%s%s", identifierOnServer, ".apk");
	return new File(UpdatesHelper.getRootDirectory(), newFileName); //might exist
}


/**
 * Stores ttl and ttlLastUpdated in their static locations.
 * @param timeToLive
 */
public static void saveTtl(int timeToLive, Context context) {
	ttl = timeToLive;
	ttlLastUpdated = System.currentTimeMillis();
	SharedPreferences prefs = context.getSharedPreferences(PrefsKey, Context.MODE_PRIVATE);
	Editor editor = prefs.edit();
	editor.putInt(PrefsKeyTTL, ttl);
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


	//File I/O
	private static void openWithAlert(final Activity context, final File file) {
		context.runOnUiThread(new Runnable() {
			public void run() {
				AlertDialog.Builder builder = new AlertDialog.Builder(context);
				builder.setMessage("A new version has been downloaded, click OK to install");
				builder.setPositiveButton("OK", new DialogInterface.OnClickListener() {
					public void onClick(DialogInterface dialog, int which) {
						Intent intent = new Intent(Intent.ACTION_VIEW);
						intent.setDataAndType(Uri.fromFile(file), "application/vnd.android.package-archive");
						context.startActivity(intent);
					}
				});
				builder.setOnCancelListener(new OnCancelListener() {
					public void onCancel(DialogInterface dialog) {
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
	
	/**
	 * The current location of the downloaded file (does not check existence)
	 * @return new instance of the unique downloaded file location for this package
	 */
	public static File downloadedFile()
	{
		String packageDir = "error_no_package_name.apk";
		if(AppBlade.hasPackageInfo()){
			packageDir = String.format("%s%s", AppBlade.getPackageInfo().packageName, ".apk");
		}
		File rootDir = UpdatesHelper.getRootDirectory(); 
		return new File(rootDir, packageDir);
	}

	public static void deleteCurrentFile() {
		File currentFile = UpdatesHelper.downloadedFile();
		if(currentFile.delete())
		{
			Log.d(AppBlade.LogTag, "Deleted now-unnecessary apk: " + currentFile.getName());
		}
		Log.d(AppBlade.LogTag, "Everything up-to-date");		
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
