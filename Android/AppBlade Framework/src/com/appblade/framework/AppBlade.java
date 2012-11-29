package com.appblade.framework;

import java.io.File;
import java.lang.Thread.UncaughtExceptionHandler;
import java.net.URL;
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
import com.appblade.framework.feedback.FeedbackData;
import com.appblade.framework.feedback.FeedbackHelper;
import com.appblade.framework.feedback.OnFeedbackDataAcquiredListener;
import com.appblade.framework.feedback.PostFeedbackTask;
import com.appblade.framework.utils.StringUtils;


public class AppBlade {

	public static String LogTag = "AppBlade";
	
	public static AppInfo appInfo;

	static boolean canWriteToDisk = false;
	public static String rootDir = null;

	static final String AppBladeExceptionsDirectory = "app_blade_exceptions";

	public static final String BOUNDARY = "---------------------------14737809831466499882746641449";

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
		String screenshotName = "feedback.png";
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
		
		FeedbackData data = new FeedbackData();
		data.Screenshot = screenshot;
		data.ScreenshotName = screenshotName;

		FeedbackHelper.getFeedbackData(context, data, new OnFeedbackDataAcquiredListener() {
			public void OnFeedbackDataAcquired(FeedbackData data) {
				new PostFeedbackTask(context).execute(data);
			}
		});
	}


	public static void register(Context context, String token, String secret, String uuid, String issuance)
	{
		register(context, token, secret, uuid, issuance, null);		
	}
	
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
				
			}catch(Exception e){   
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

	/**
	 * Notify the AppBlade Server of a crash, given the thrown error/exception
	 * @param e
	 */
	public static void notify(final Throwable e)
	{
		if(e != null && canWriteToDisk)
		{
			CrashReportData data = new CrashReportData(e);
			new PostCrashReportTask(null).execute(data);
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
