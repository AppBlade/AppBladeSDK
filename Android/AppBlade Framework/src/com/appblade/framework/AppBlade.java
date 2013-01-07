package com.appblade.framework;

import java.io.File;
import java.lang.Thread.UncaughtExceptionHandler;
import java.net.URL;
import java.util.Random;

import org.json.JSONException;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.DialogInterface.OnClickListener;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.util.Log;
import android.view.View;

import com.appblade.framework.authenticate.AuthHelper;
import com.appblade.framework.authenticate.RemoteAuthHelper;
import com.appblade.framework.crashreporting.CrashReportData;
import com.appblade.framework.crashreporting.PostCrashReportTask;
import com.appblade.framework.customparams.CustomParamData;
import com.appblade.framework.customparams.CustomParamDataHelper;
import com.appblade.framework.feedback.FeedbackData;
import com.appblade.framework.feedback.FeedbackHelper;
import com.appblade.framework.feedback.OnFeedbackDataAcquiredListener;
import com.appblade.framework.feedback.PostFeedbackTask;
import com.appblade.framework.stats.SessionData;
import com.appblade.framework.stats.SessionHelper;
import com.appblade.framework.utils.StringUtils;

/**
 * AppBlade
 * @author andrew.tremblay@raizlabs
 * @author rich.stern@raizlabs
 */
public class AppBlade {

	public static String LogTag = "AppBlade";
	
	public static AppInfo appInfo;

	static boolean canWriteToDisk = false;
	public static String rootDir = null;
	public static String exceptionsDir = null;
	public static String feedbackDir = null;
	public static String sessionsDir = null;
	public static String customParamsDir = null;

	public static SessionData currentSession;

	//keeping folders all in one place (the rootDir)
	public static final String AppBladeExceptionsFolder = "app_blade_exceptions";
	public static final String AppBladeFeedbackFolder = "app_blade_feedback";
	public static final String AppBladeSessionsFolder = "app_blade_sessions";
	public static final String AppBladeCustomParamsFolder = "app_blade_params";

	public static final String BOUNDARY_FORMAT = "---------------------------%s";
	private static final int dynamicBoundaryLength = 64;

	
	/********************************************************
	 ********************************************************
	 * APPBLADE REGISTRATION
	 * Methods to help assign the app with the necessary information to communicate with AppBlade. A register call should be made before all other calls, and only once. 
	 */
	
	/**
	 * Static entry point for registering with AppBlade (must be called before anything else).
	 * Find your API keys on your project page at http://www.appblade.com
	 * @param context Context to use to control storage.
	 * @param token String value of the token.
	 * @param secret String value of the shared secret.
	 * @param uuid String value of the project uuid.
	 * @param issuance String value of the timestamp value.
	 */	
	public static void register(Context context, String token, String secret, String uuid, String issuance)
	{
		register(context, token, secret, uuid, issuance, null);		
	}
	
	/**
	 * Static entry point for registering with AppBlade (must be called before anything else)
	 * @param context Context to use to control storage.
	 * @param token String value of the token.
	 * @param secret String value of the shared secret.
	 * @param uuid String value of the project uuid.
	 * @param issuance String value of the timestamp value.
	 * @param customHost String value of the custom endpoint to use. Will determine port automatically if not defined from the given protocol (http/https), falls back to default values of protocol and port if neither included.
	 */	
	public static void register(Context context, String token, String secret, String uuid, String issuance, String customHost)
	{
		// Check parameters
		if(context == null)
		{
			throw new IllegalArgumentException("Invalid context registered with AppBlade");
		}

		if(		StringUtils.isNullOrEmpty(token) ||
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

		if(customHost != null)
		{
			//check url validity of custom host
			try{
				URL hostCheck = new URL(customHost);
				hostCheck.toURI();
				appInfo.CurrentEndpoint  = hostCheck.getHost();
				if(hostCheck.getPort() != -1){
					appInfo.CurrentEndpoint = String.format("%s:%d", hostCheck.getHost(), hostCheck.getPort());
				}
				
				appInfo.CurrentServiceScheme = String.format("%s://", hostCheck.getProtocol());
				if(appInfo.CurrentServiceScheme == null){
					appInfo.CurrentServiceScheme = AppInfo.DefaultServiceScheme;
				}
				
			}
			catch(Exception e) {   
				//the URL was not valid, fallback to default
				Log.d(LogTag, String.format("%s was not a valid URL, falling back to %s", customHost, AppInfo.DefaultAppBladeHost));
				appInfo.CurrentEndpoint  = AppInfo.DefaultAppBladeHost;
				appInfo.CurrentServiceScheme = AppInfo.DefaultServiceScheme;
			}
		}
		Log.d(LogTag, String.format("Using a endpoint URL, %s %s", appInfo.CurrentServiceScheme, appInfo.CurrentEndpoint));

		
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

		rootDir = context.getFilesDir().getAbsolutePath();
		exceptionsDir = makeDirFromRoot(AppBladeExceptionsFolder, context);
		feedbackDir = makeDirFromRoot(AppBladeFeedbackFolder, context);
		sessionsDir = makeDirFromRoot(AppBladeSessionsFolder, context);
		customParamsDir  = makeDirFromRoot(AppBladeCustomParamsFolder, context);
		File exceptionsDirectory = new File(exceptionsDir);
		canWriteToDisk = exceptionsDirectory.exists();
	}

	/**
	 * Static check for whether we are currently registered with AppBlade.
	 */
	public boolean isRegistered() {
		return appInfo != null && appInfo.isValid();
	}
	
	
	

	/********************************************************
	 ********************************************************
	 * APP AUTHORIZATION 
	 * Methods to force users to sign into AppBlade before using the app (or a part of the app).
	 * The features of AppBlade benefit from authorization, but calls to it should be removed before Play Store release.
	 */

	/**
	 * Static entry point for authorization logic and navigation.
	 * Simple wrapper call to  authorize(final Activity activity, boolean fromLoopBack) where fromLoopBack is false
	 * @param activity
	 */
	public static void authorize(Activity activity) {
		authorize(activity, false);
	}

	/**
	 * Static entry point for authorization logic and navigation
	 * Prompts an Authorization view with a sign-in to AppBlade, fetches a token on successful login. 
	 * If a valid token already exists, will not prompt anything.
	 * @param activity
	 * @param fromLoopBack whether the authorize call is from the authorization window or not, (defaults to false)
	 */
	public static void authorize(final Activity activity, boolean fromLoopBack) {

		// If we don't have enough stored information to authorize the current user,
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
	}


	/**
	 * Static check for authorization 
	 * @param activity Activity to check for authorization
	 * @return Whether we have a valid access token (a token exists AND we are still within the ttl)
	 */
	private static boolean isAuthorized(Activity activity) {
		String accessToken = RemoteAuthHelper.getAccessToken(activity);
		setDeviceId(accessToken);

		boolean isTtlValid = !KillSwitch.shouldUpdate();
		return  !StringUtils.isNullOrEmpty(accessToken) && isTtlValid;
	}
	
	/**
	 * Static check for authorization 
	 * @param context The Context we want to check for authorization
	 * @return Whether we have a valid access token (a token exists AND we are still within the ttl)
	 */
	private static boolean isAuthorized(Context context) {
		String accessToken = RemoteAuthHelper.getAccessToken(context);
		setDeviceId(accessToken);

		boolean isTtlValid = !KillSwitch.shouldUpdate(); 
		return  !StringUtils.isNullOrEmpty(accessToken) && isTtlValid;
	}


	
	/********************************************************
	 ********************************************************
	 * SESSION COUNTING
	 * Methods to store and send when a session is started and ended (usually reserved for when an application or activity is resumed or paused)
	 */
	
	/**
	 * Static point for beginning a session (posts any existing sessions by default) 
	 * @param context Context to use to control the posting of the session.
	 */
	public static void startSession(Context context)
	{
		startSession(context, false);
	}
	
	/**
	 * Static point for ending a session
	 * @param context Context to use to control the posting of the session.
	 * @param onlyAuthorized boolean to determine manually if you only want to log authorized sessions or not.
	 */
	public static void startSession(Context context, boolean onlyAuthorized)
	{
		if(onlyAuthorized){
			if(isAuthorized(context)) {
				//check for existing sessions, post them.
				SessionHelper.startSession(context);
			}
			else
			{
				Log.d(LogTag, "Client is not yet authorized, cannot start session");
			}
		}
		else
		{
			//we don't care about authorization
			SessionHelper.startSession(context);
		}


	}

	/**
	 * Static point for ending a session
	 * @param context Context to use to control the posting of the session.
	 */
	public static void endSession(Context context)
	{
		endSession(context, false);		
	}
		
	/**
	 * Static point for ending a session
	 * @param context Context to use to control the posting of the session.
	 * @param onlyAuthorized boolean to determine manually if you only want to log authorized sessions or not.
	 */
	public static void endSession(Context context, boolean onlyAuthorized)
	{
		if(onlyAuthorized){
			if(isAuthorized(context)) {
				SessionHelper.endSession(context);
			}
			else
			{
				Log.d(LogTag, "Client is not yet authorized, cannot end session");			
			}
		}
		else
		{
			//we don't care about authorization
			SessionHelper.endSession(context);
		}
		SessionHelper.postExistingSessions(context);
	}

	
	/********************************************************
	 ********************************************************
	 * FEEDBACK REPORTING
	 * Methods for the AppBlade feedback window, will send a screenshot of hte current screen and a personalized message to appblade, as well as any custom parameters you have set. 
	 * Be very careful that you do not send any personal information accidentally (or maliciously) 
	 */
	
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
		String screenshotName = "feedback.png"; //keep for appblade logic
		doFeedbackWithScreenshot(context, screenshot, screenshotName);
	}

	/**
	 * Gets feedback from the user via a dialog and posts the feedback, log data, and given
	 * Bitmap to AppBlade.
	 * @param context Context to use to display the dialog.
	 * @param screenshot The screenshot Bitmap to post to AppBlade.
	 * @param screenshotName The filename to use for the screenshot.
	 */
	public static void doFeedbackWithScreenshot(final Context context, Bitmap screenshot, String screenshotName) {
		FeedbackData data = new FeedbackData();
		data.setPersistentScreenshot(screenshot);
		data.ScreenshotName = screenshotName;
		FeedbackHelper.getFeedbackData(context, data, new OnFeedbackDataAcquiredListener() {
			public void OnFeedbackDataAcquired(FeedbackData data) {
				new PostFeedbackTask(context).execute(data);
			}
		});
	}

	/********************************************************
	 ********************************************************
	 * CRASH REPORTING 
	 * Error handling methods that can help you send data to AppBlade
	 */
	
	/**
	 * Register AppBladeExceptionHandler as the default uncaught exception handler on the current thread.
	 * Will call on every uncaught exception and will pass that exception to AppBlade.notify(final Throwable e).
	 */
	private static void registerExceptionHandler() {
		UncaughtExceptionHandler current = Thread.getDefaultUncaughtExceptionHandler();
		if(! (current instanceof AppBladeExceptionHandler))
		{
			Thread.setDefaultUncaughtExceptionHandler(new AppBladeExceptionHandler(current));
		}
	}

	/**
	 * Notify the AppBlade Server of a crash, given the thrown error/exception
	 * @param e The Throwable to send to AppBlade
	 */
	public static void notify(final Throwable e)
	{
		if(e != null && canWriteToDisk)
		{
			Log.d(AppBlade.LogTag, e.getLocalizedMessage());
			CrashReportData data = new CrashReportData(e);
			new PostCrashReportTask(null).execute(data);
		}
	}

	
	/********************************************************
	 ********************************************************
	 * CUSTOM PARAMETERS 
	 * Methods to set, get, and clear any custom parameters you'd like to send along with feedback or crash reporting to AppBlade 
	 */

	/**
	 * Static entry point for setting custom parameters
	 * custom parameters are stored and sent as JSON
	 * silently throws JSONException 
	 * @param context Context to use to control storage.
	 * @param key Key value (name) of the parameter.
	 * @param value Object value that you want the key set to. (JSON or String, usually) 
	 */
	public static void setCustomParameter(Context context, String key, Object value) 
	{
		try {
			AppBlade.setCustomParameterThrowy(context, key, value);
		} catch (JSONException e) {
			e.printStackTrace();
		}
	}

	/**
	 * Static entry point for setting custom parameters
	 * loudly throws JSONException 
	 * @param context Context to use to control storage.
	 * @param key Key value (name) of the parameter.
	 * @param value Object value that you want the key set to. (JSON or String, usually) 
	 * @throws JSONException 
	 */
	public static void setCustomParameterThrowy(Context context, String key, Object value) throws JSONException
	{
		CustomParamData currentParams = CustomParamDataHelper.getCurrentCustomParams();
		currentParams.put(key, value);
		CustomParamDataHelper.storeCurrentCustomParams(context, currentParams);
	}
	
	/**
	 * Static entry point for clearing all custom Params
	 * @param context Context to use to control storage.
	 */
	public static void clearCustomParameters(Context context)
	{
		CustomParamData emptyData = new CustomParamData();
		CustomParamDataHelper.storeCurrentCustomParams(context, emptyData);		
	}


	/********************************************************
	 ********************************************************
	 * ASSORTED DETRITUS 
	 * Helper methods to make the inner workings of AppBlade a bit easier
	 */

	/**
	 * Static check for whether we are have info about the current apk.
	 */
	public static boolean hasPackageInfo() {
		return appInfo != null && appInfo.PackageInfo != null;
	}

	/**
	 * Static call for the info about the current apk.
	 * @return package info about the apk we have already generated on registering. Returns null if we are not registered.
	 */
	public static PackageInfo getPackageInfo() {
		if(AppBlade.hasPackageInfo()) {
			return appInfo.PackageInfo;
		}
		return null;	
	}


	/**
	 * Static helper call to set the device ID (ext) for the device running this app.
	 * @param accessToken the access token to that will be the new deviceID, defaults to AppInfo.DefaultUDID if null or an empty string
	 */
	public static void setDeviceId(String accessToken) {
		Log.d(AppBlade.LogTag, String.format("AppBlade.setDeviceId: %s", accessToken));

		if(!StringUtils.isNullOrEmpty(accessToken))
			AppBlade.appInfo.Ext = accessToken;
		else
			AppBlade.appInfo.Ext = AppInfo.DefaultUDID;
	}
	
	/**
	 * Static helper call to generate a dynamic boundary for webservice calls.
	 * @return a random string of numbers of length dynamicBoundaryLength, the string will not contain zero
	 */
	public static String genDynamicBoundary()
	{
		//copying from random nonce string in case anything changes over there.
		String letters = "123456789";
		StringBuilder builder = new StringBuilder();
		Random random = new Random();
		for(int i = 0; i < dynamicBoundaryLength; i++)
		{
			builder.append(letters.charAt(random.nextInt(letters.length())));
		}
		return builder.toString();
	}

	/**
	 * Helper method for setting up AppBlade storage
	 * @param subfolder String name of subfolder to create.
	 * @param context Context to use to control storage.	 
	 */	
	private static String makeDirFromRoot(String subfolder, Context context)
	{
		String toRet = String.format("%s%s%s",
				context.getFilesDir().getAbsolutePath(), "/", subfolder);
		File fileDirectory = new File(toRet);
		fileDirectory.mkdirs();
		return toRet;
	}

}
