package com.appblade.framework;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.lang.Thread.UncaughtExceptionHandler;
import java.net.URI;
import java.nio.ByteBuffer;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Hashtable;
import java.util.Iterator;

import javax.crypto.BadPaddingException;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.ByteArrayEntity;
import org.json.JSONException;
import org.json.JSONObject;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.DialogInterface.OnClickListener;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.AsyncTask;
import android.util.Log;
import android.view.View;

import com.appblade.framework.WebServiceHelper.HttpMethod;


public class AppBlade {

	public static String LogTag = "AppBlade";
	public static byte[] ivBytes = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
	public static String AESkey = "e8ffc7e56311679f12b6fc91aa77a5eb";

	protected static AppInfo appInfo;
	protected static Hashtable<String, String> customFields;

	static boolean canWriteToDisk = false;
	static String rootDir = null;
	static String feedbackDir = null;

	static final String AppBladeExceptionsDirectory = "app_blade_exceptions";
	static final String AppBladeFeedbackDirectory = "app_blade_feedback";

	private static final String BOUNDARY = "---------------------------14737809831466499882746641449";
	
	/**
	 * Adds a new key/value pair for our custom fields
	 * @param key
	 * @param value
	 */

	public static void setCustomField(String key, String value) {
		if (customFields == null) {
			customFields = new Hashtable<String, String>();
		}

		customFields.put(key, value);
	}

	/**
	 * Gets feedback from the user via a dialog and posts the feedback along with log data to AppBlade.
	 * @param context Context to use to display the dialog. 
	 */
	public static void doFeedback(Context context) {
		doFeedbackWithScreenshot(context, null, null);
	}

	/**
	 * Gets feedback from the user via a dialog and takes a screenshot from the content of the given
	 * Activity. Posts the feedback, log data, and screenshot to AppBlade.
	 * @param context Context to use to display the dialog.
	 * @param activity Activity to screenshot.
	 */
	public static void doFeedbackWithScreenshot(Context context, Activity activity) {
		View view = activity.getWindow().getDecorView().findViewById(android.R.id.content);
		doFeedbackWithScreenshot(context, view);
	}

	/**
	 * Gets feedback from the user via a dialog and takes a screenshot from the given View.
	 * Posts the feedback, log data, and screenshot to AppBlade.
	 * @param context Context to use to display the dialog.
	 * @param view View to screenshot.
	 */
	public static void doFeedbackWithScreenshot(Context context, View view) {
		boolean wasCacheEnabled = view.isDrawingCacheEnabled();
		view.setDrawingCacheEnabled(true);
		Bitmap viewScreenshot = view.getDrawingCache();
		Bitmap screenshot = viewScreenshot.copy(viewScreenshot.getConfig(), false);
		view.setDrawingCacheEnabled(wasCacheEnabled);

		doFeedbackWithScreenshot(context, screenshot);
	}

	/**
	 * Gets feedback from the user via a dialog and posts the feedback, log data, and given
	 * Bitmap to AppBlade.
	 * @param context Context to use to display the dialog.
	 * @param screenshot The screenshot Bitmap to post to AppBlade.
	 */
	public static void doFeedbackWithScreenshot(Context context, Bitmap screenshot) {
		//String screenshotName = "Feedback " + feedbackDateFormat.format(new Date()) + ".png";
		String screenshotName = "feedback.jpg";
		doFeedbackWithScreenshot(context, screenshot, screenshotName);
	}

	/**
	 * Gets feedback from the user via a dialog and posts the feedback, log data, and given
	 * Bitmap to AppBlade.
	 * @param context Context to use to display the dialog.
	 * @param screenshot The screenshot Bitmap to post to AppBlade.
	 * @param screenshotName The filename to use for the screenshot.
	 */
	public static void doFeedbackWithScreenshot(final Context context, 
			Bitmap screenshot, String screenshotName) {
		String[] permissions = appInfo.PackageInfo.requestedPermissions;

		String consoleData = "";
		for (String permission : permissions) {
			if (permission.equals(Manifest.permission.READ_LOGS))
			{
				consoleData = FeedbackHelper.getLogData();
				break;
			}
		}

		FeedbackData data = new FeedbackData();
		data.Console = consoleData;
		data.Screenshot = screenshot;
		data.ScreenshotName = screenshotName;

		FeedbackHelper.getFeedbackData(context, data, new OnFeedbackDataAcquiredListener() {
			public void OnFeedbackDataAcquired(FeedbackData data) {
				new PostFeedbackTask(context).execute(data);
			}
		});
	}

	protected static boolean postFeedback(FeedbackData data) {
		boolean success = false;
		HttpClient client = HttpClientProvider.newInstance("Android");

		try
		{
			String urlPath = String.format(WebServiceHelper.ServicePathFeedbackFormat, appInfo.AppId, appInfo.Ext);
			String url = WebServiceHelper.getUrl(urlPath);

			byte[] content = FeedbackHelper.getPostFeedbackBody(data, BOUNDARY);
			
			ByteArrayEntity entity = new ByteArrayEntity(content);

			HttpPost request = new HttpPost();
			request.setEntity(entity);
			
			String contentBody = new String(content, "UTF-8");
			
			String authHeader = WebServiceHelper.getHMACAuthHeader(appInfo, urlPath, contentBody, HttpMethod.POST);

			Log.d(LogTag, urlPath);
			Log.d(LogTag, url);
			Log.d(LogTag, authHeader);

			request.setURI(new URI(url));
			request.addHeader("Content-Type", "multipart/form-data; boundary=" + BOUNDARY);
			request.addHeader("Authorization", authHeader);
			WebServiceHelper.addCommonHeaders(request);
			
			
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
		
		return success;
	}
	
	@SuppressWarnings("unchecked")
	public static void postFeedbackToServer()
	{
		Log.d(LogTag, "Posting backlogged feedback.");
		File dir = new File(feedbackDir);
		if(dir.exists() && dir.isDirectory()) {
			File[] feedback = dir.listFiles();
			for(File f : feedback) {
				if(f.exists() && f.isFile() && FeedbackHelper.GetFileExt(f.getName()).equals("json")) {

					try {
						InputStream inputStream = new FileInputStream(f);
						BufferedReader r = new BufferedReader(new InputStreamReader(inputStream));
						StringBuilder total = new StringBuilder();
						String line;
						while ((line = r.readLine()) != null) {
						    total.append(line);
						}
						
						
						byte[] unencodedData = Base64.decode(total.toString(), Base64.DEFAULT);
						
						byte[] unencryptedData = AES256Cipher.decrypt(ivBytes, AESkey.getBytes("UTF-8"), unencodedData);
						String jsonString = new String(unencryptedData);
						
						JSONObject feedbackJSON = new JSONObject(jsonString);
						
						FeedbackData data = new FeedbackData();
						data.Console = feedbackJSON.getString(FeedbackData.CONSOLE_KEY);
						data.Notes = feedbackJSON.getString(FeedbackData.NOTES_KEY);
						data.ScreenshotName = feedbackJSON.getString(FeedbackData.SCREENSHOT_NAME_KEY);
						data.SavedName = f.getName();
						
						JSONObject jsonParams = (JSONObject) feedbackJSON.getJSONObject(FeedbackData.PARAMS_KEY);
						Hashtable <String, String> params = new Hashtable<String, String>();
						Iterator<String> paramsIterator = jsonParams.keys();
						while(paramsIterator.hasNext())
						{
							String key = (String)paramsIterator.next();
							try {
								params.put(key, jsonParams.getString(key));
							} catch (JSONException e) {
								e.printStackTrace();
							}
						}
						
						data.CustomParams = params;
						
						
						String screenshotPath = String.format("%s/%s", AppBlade.feedbackDir, data.ScreenshotName);
						// Get screenshot bitmap
						
						BitmapFactory.Options options = new BitmapFactory.Options();
						options.inPreferredConfig = Bitmap.Config.ARGB_8888;
						Bitmap bitmap = BitmapFactory.decodeFile(screenshotPath, options);
						data.Screenshot = bitmap;
						
						postFeedback(data);
						
					} catch (FileNotFoundException e) {
						Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
					} catch (IOException e) {
						Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
					} catch (InvalidKeyException e) {
						Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
					} catch (NoSuchAlgorithmException e) {
						Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
					} catch (NoSuchPaddingException e) {
						Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
					} catch (InvalidAlgorithmParameterException e) {
						Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
					} catch (IllegalBlockSizeException e) {
						Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
					} catch (BadPaddingException e) {
						Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
					} catch (JSONException e) {
						Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
					}
					
					
				}
			}
		}
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
		
		feedbackDir = String.format("%s/%s",
				context.getFilesDir().getAbsolutePath(),
				AppBladeFeedbackDirectory);
		File feedbackDirectory = new File(feedbackDir);
		feedbackDirectory.mkdirs();

	}

	public boolean isRegistered() {
		return
				appInfo != null && appInfo.isValid();
	}

	/**
	 * Register default exception handler on current thread
	 */
	public static void registerExceptionHandler() {
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
				SecureRandom random = new SecureRandom();
//				random.generateSeed(4);
				byte[] randomBytes = null;
				random.nextBytes(randomBytes);
				int r = ByteBuffer.wrap(randomBytes).getInt();
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
		
		try {
			byte[] content = ExceptionUtils.buildExceptionBody(f, BOUNDARY);
	
			ByteArrayEntity entity = new ByteArrayEntity(content);
	
			HttpPost request = new HttpPost();
			request.setEntity(entity);
			
			String contentBody = new String(content, "UTF-8");
			
			String urlPath = String.format(WebServiceHelper.ServicePathCrashReportsFormat, appInfo.AppId, appInfo.Ext);
			String url = WebServiceHelper.getUrl(urlPath);
			String authHeader = WebServiceHelper.getHMACAuthHeader(appInfo, urlPath, contentBody, HttpMethod.POST);
	
			Log.d(LogTag, urlPath);
			Log.d(LogTag, url);
			Log.d(LogTag, authHeader);
	
			request.setURI(new URI(url));
			request.addHeader("Content-Type", "multipart/form-data; boundary=" + BOUNDARY);
			request.addHeader("Authorization", authHeader);
			WebServiceHelper.addCommonHeaders(request);
			
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
		{
			Log.d(AppBlade.LogTag,
					String.format("AppBlade.authorize: user is authorized, closing activity: %s",
							activity.getLocalClassName()));
			activity.finish();
		}
		
		else {
			postFeedbackToServer();
		}
	}
	
	public static void registerDevice(Activity activity) {
		if(!isAuthorized(activity))
		{
			AuthHelper.checkRegistration(activity);
		}
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
