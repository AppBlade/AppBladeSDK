package com.appblade.framework;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.lang.Thread.UncaughtExceptionHandler;
import java.net.URI;
import java.util.Random;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.DialogInterface.OnClickListener;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.os.AsyncTask;
import android.util.Log;

import com.appblade.framework.WebServiceHelper.HttpMethod;


public class AppBlade {
	
	public static String LogTag = "AppBlade";
	
	protected static AppInfo appInfo;
	
	static boolean canWriteToDisk = false;
	static String rootDir = null;
	
	static final String AppBladeExceptionsDirectory = "app_blade_exceptions";
	
	private static final String BOUNDARY = "---------------------------14737809831466499882746641449";
	
	public static void doFeedback(Context context) {
		String[] permissions = appInfo.PackageInfo.requestedPermissions;
		
		String _consoleData = "";
		for (String permission : permissions) {
			if (permission.equals("android.permission.READ_LOGS"))
			{
				_consoleData = FeedbackHelper.getLogData();
				break;
			}
		}
		
		
		final String consoleData = _consoleData;
		//postFeedback("Test Notes", "Test Console", null, null);
		
		FeedbackHelper.getFeedbackData(context, new OnFeedbackDataAcquiredListener() {
			public void OnFeedbackDataAcquired(FeedbackData data) {
				data.Console = consoleData;
				postFeedback(data);
			}
		});
	}
	
	private static void postFeedback(FeedbackData data) {
		boolean success = false;
		HttpClient client = HttpClientProvider.newInstance("Android");
		
		try
		{
				String urlPath = String.format(WebServiceHelper.ServicePathFeedbackFormat, appInfo.AppId, appInfo.Ext);
				String url = WebServiceHelper.getUrl(urlPath);
				
				String content = FeedbackHelper.getPostFeedbackBody(data, BOUNDARY);
				
				String authHeader = WebServiceHelper.getHMACAuthHeader(appInfo, urlPath, content, HttpMethod.POST);
				
				Log.d(LogTag, urlPath);
				Log.d(LogTag, url);
				Log.d(LogTag, authHeader);
				
				HttpPost request = new HttpPost();
				request.setURI(new URI(url));
				request.addHeader("Content-Type", "multipart/form-data; boundary=" + BOUNDARY);
				request.addHeader("Authorization", authHeader);
				WebServiceHelper.addCommonHeaders(request);
				
				if(!StringUtils.isNullOrEmpty(content))
					request.setEntity(new StringEntity(content));
			    
				HttpResponse response = null;
			    response = client.execute(request);
				if(response != null && response.getStatusLine() != null)
				{
					int statusCode = response.getStatusLine().getStatusCode();
					int statusCategory = statusCode / 100;
					
					if(statusCategory == 2)
						success = true;
				}
		}
		catch(Exception ex)
		{
			Log.d(LogTag, String.format("%s %s", ex.getClass().getSimpleName(), ex.getMessage()));
		}
		
		IOUtils.safeClose(client);
	}
	
	public static void register(Context context, String token, String secret, String uuid, String issuance)
	{
		// Check params
		if(context == null)
		{
			throw new IllegalArgumentException("Invalid context registered with AppBlade");
		}
		
		if(
				StringUtils.isNullOrEmpty(token) ||
				StringUtils.isNullOrEmpty(secret) ||
				StringUtils.isNullOrEmpty(uuid) ||
				StringUtils.isNullOrEmpty(issuance))
		{
			throw new IllegalArgumentException("Invalid application info registered with AppBlade");
		}
		
		// Initialize App Info
		appInfo = new AppInfo();
		appInfo.AppId = uuid;
		appInfo.Token = token;
		appInfo.Secret = secret;
		appInfo.Issuance = issuance;
		
		// Set the device ID for exception reporting requests
		String accessToken = RemoteAuthHelper.getAccessToken(context);
		setDeviceId(accessToken);
		
		registerExceptionHandler();
		
		try
		{
			String packageName = context.getPackageName();
			int flags = PackageManager.GET_PERMISSIONS;
			appInfo.PackageInfo = context.getPackageManager().getPackageInfo(packageName, flags);
		}
		catch (Exception ex) { }
		
		rootDir = String.format("%s/%s",
				context.getFilesDir().getAbsolutePath(),
				AppBladeExceptionsDirectory);
		File exceptionsDirectory = new File(rootDir);
		exceptionsDirectory.mkdirs();
		canWriteToDisk = exceptionsDirectory.exists();
	}
	
	public boolean isRegistered() {
		return
				appInfo != null && appInfo.isValid();
	}

	/**
	 * Register default exception handler on current thread
	 */
	private static void registerExceptionHandler() {
		UncaughtExceptionHandler current = Thread.getDefaultUncaughtExceptionHandler();
		if(! (current instanceof AppBladeExceptionHandler))
		{
			Thread.setDefaultUncaughtExceptionHandler(new AppBladeExceptionHandler(current));
		}
	}
	
	public static void notify(final Throwable e)
	{
		if(e != null && canWriteToDisk)
		{
			new AsyncTask<Void, Void, Void>() {

				@Override
				protected Void doInBackground(Void... params) {
					writeExceptionToDisk(e);
					postExceptionsToServer();
					
					return null;
				}
				
			}.execute();
		}
	}

	private static void writeExceptionToDisk(Throwable e) {
		try
		{
			String systemInfo = appInfo.getSystemInfo();
			String stackTrace = ExceptionUtils.getStackTrace(e);
			
			if(!StringUtils.isNullOrEmpty(stackTrace))
			{
				int r = new Random().nextInt(9999);
				String filename = String.format("%s/ex-%d-%d.txt",
						rootDir, System.currentTimeMillis(), r);
				
				File file = new File(filename);
				if(file.createNewFile())
				{
					BufferedWriter writer = new BufferedWriter(new FileWriter(filename));
					writer.write(systemInfo);
					writer.write(stackTrace);
					writer.close();
				}
			}
		}
		catch(Exception ex)
		{
			Log.d(LogTag, String.format("Ex: %s, %s", ex.getClass().getCanonicalName(), ex.getMessage()));
		}
	}

	private static void postExceptionsToServer() {

        File exceptionDir = new File(rootDir);
        if(exceptionDir.exists() && exceptionDir.isDirectory()) {
            File[] exceptions = exceptionDir.listFiles();
            for(File f : exceptions) {
                if(f.exists() && f.isFile()) {
                    sendExceptionData(f);
                }
            }
        }
	}

	private static synchronized void sendExceptionData(File f) {
		boolean success = false;
		HttpClient client = HttpClientProvider.newInstance("Android");
		
		try
		{
			FileInputStream fis = new FileInputStream(f);
			String content = StringUtils.readStream(fis);
			if(!StringUtils.isNullOrEmpty(content))
			{
				String urlPath = String.format(WebServiceHelper.ServicePathCrashReportsFormat, appInfo.AppId, appInfo.Ext);
				String url = WebServiceHelper.getUrl(urlPath);
				String authHeader = WebServiceHelper.getHMACAuthHeader(appInfo, urlPath, content, HttpMethod.POST);
				
				Log.d(LogTag, urlPath);
				Log.d(LogTag, url);
				Log.d(LogTag, authHeader);
				
				HttpPost request = new HttpPost();
				request.setURI(new URI(url));
				request.addHeader("Authorization", authHeader);
				WebServiceHelper.addCommonHeaders(request);
				
				if(!StringUtils.isNullOrEmpty(content))
					request.setEntity(new StringEntity(content));
			    
				HttpResponse response = null;
			    response = client.execute(request);
				if(response != null && response.getStatusLine() != null)
				{
					int statusCode = response.getStatusLine().getStatusCode();
					int statusCategory = statusCode / 100;
					
					if(statusCategory == 2)
						success = true;
				}
			}
		}
		catch(Exception ex)
		{
			Log.d(LogTag, String.format("%s %s", ex.getClass().getSimpleName(), ex.getMessage()));
		}
		
		IOUtils.safeClose(client);
		
		// delete the file
		if(success && f.exists())
		{
			f.delete();
		}
	}

	public static boolean hasPackageInfo() {
		return appInfo != null && appInfo.PackageInfo != null;
	}

	public static PackageInfo getPackageInfo() {
		return appInfo.PackageInfo;
	}
	
	/**
	 * Default fromLoopBack parameter to false since this is how it is called from the host app
	 * @param activity
	 */
	public static void authorize(Activity activity) {
		authorize(activity, false);
	}

	/**
	 * Static entry point for authorization logic and navigation
	 * @param activity
	 * @param fromLoopBack
	 */
	public static void authorize(final Activity activity, boolean fromLoopBack) {
		
		// If we don't have enough stored information to authorize the curent user,
		// delegate to the AuthHelper
		if(!isAuthorized(activity))
		{
			// If the call came from the host application (and not from AppBlade)
			// show a dialog so the user knows what is going on
			if(!fromLoopBack)
			{
				AlertDialog.Builder builder = new AlertDialog.Builder(activity);
				builder.setMessage("Authorization Required");
				builder.setPositiveButton("OK", new OnClickListener() {
					
					public void onClick(DialogInterface dialog, int which) {
						AuthHelper.checkAuthorization(activity, false);
					}
				});
				builder.setNegativeButton("No, thanks", new OnClickListener() {
					
					public void onClick(DialogInterface dialog, int which) {
						activity.finish();
					}
				});
				builder.setOnCancelListener(new DialogInterface.OnCancelListener() {
					
					public void onCancel(DialogInterface dialog) {
						activity.finish();
					}
				});
				builder.show();
			}
			// Otherwise, we are looping back from within AppBlade and we should run the code
			// without bothering the user
			else
			{
				AuthHelper.checkAuthorization(activity, false);
			}
		}
		
		// If we do have enough information and the source of this call is from within AppBlade,
		// close the activity context
		else if (fromLoopBack)
			activity.finish();
	}
	
	private static boolean isAuthorized(Activity activity) {
		String accessToken = RemoteAuthHelper.getAccessToken(activity);
		setDeviceId(accessToken);
		
		boolean isTtlInvalid = KillSwitch.shouldUpdate();
		
		return
				!StringUtils.isNullOrEmpty(accessToken) &&
				!isTtlInvalid;
	}

	public static void setDeviceId(String accessToken) {
		Log.d(AppBlade.LogTag, String.format("AppBlade.setDeviceId: %s", accessToken));
		
		if(!StringUtils.isNullOrEmpty(accessToken))
			AppBlade.appInfo.Ext = accessToken;
		else
			AppBlade.appInfo.Ext = AppInfo.DefaultUDID;
	}
}
