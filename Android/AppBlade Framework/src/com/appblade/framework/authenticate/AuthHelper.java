package com.appblade.framework.authenticate;


import com.appblade.framework.utils.StringUtils;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.DialogInterface.OnCancelListener;
import android.content.Intent;

/**
 * Helper class for functions related to authorization. These functions
 * shouldn't need to be called directly, call {@link
 * AppBlade.authorize(Activity)} instead.
 * 
 * @author rich.stern@raizlabs
 * @author andrew.tremblay@raizlabs
 * */
public class AuthHelper {

	/**
	 * Checks whether the given activity is authorized, does nothing else. <br>
	 * For the login flow see {@link #checkAuthorization(Activity, boolean)};
	 * @param activity Activity to check authorization/prompt dialog. 
	 * @returns true if the current activity is authorized, false in all other cases.
	 */
	public static boolean isAuthorized(Activity activity)
	{
		boolean toRet = false;   // assume not authorized
		String accessToken = RemoteAuthHelper.getAccessToken(activity);
		if(!StringUtils.isNullOrEmpty(accessToken)) {  //we have a token 
			KillSwitch.reloadSharedPrefs(activity); //set latest variables, for best accuracy.
			toRet = KillSwitch.shouldUpdate(); // set if we're in the TTL
		}
		return toRet;
	}
	
	
	/**
	 * Checks whether the given activity is authorized, prompts an optional dialog beforehand. 
	 * @param activity Activity to check authorization/prompt dialog. 
	 * @param shouldPrompt boolean of whether an "Authorization Required" dialog should be shown to the user first.
	 */
	public static void checkAuthorization(final Activity activity, boolean shouldPrompt) {
		AuthHelper.checkAuthorization(activity, shouldPrompt, false);
	}

	/**
	 * Checks whether the given activity is authorized, prompts an optional dialog beforehand. 
	 * @param activity Activity to check authorization/prompt dialog. 
	 * @param shouldPrompt boolean of whether an "Authorization Required" dialog should be shown to the user first.
	 * @param updateCheck boolean of whether we should go through the update process after authorization.
	 */
	public static void checkAuthorization(final Activity activity, boolean shouldPrompt, boolean updateCheck) {
		if (shouldPrompt) {
			AlertDialog.Builder builder = new AlertDialog.Builder(activity);
			builder.setMessage("Authorization Required");
			builder.setPositiveButton("Continue",
					new DialogInterface.OnClickListener() {

						public void onClick(DialogInterface dialog, int which) {
							authorize(activity);
						}
					});
			builder.setNegativeButton("No thanks",
					new DialogInterface.OnClickListener() {
						public void onClick(DialogInterface dialog, int which) {
							dialog.dismiss();
							activity.finish();
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
			authorize(activity);
		}

	}

	/**
	 * Function to authorize the given activity. <br>
	 * First checks if the user has an accessToken already with {@link
	 * RemoteAuthHelper.getAccessToken(Activity)}<br>
	 * If an accessToken exists, calls {@link KillSwitch.authorize(Activity)} If
	 * we don't have an accessToken, we start a {@link RemoteAuthorizeActivity}
	 * from the given activity.
	 * 
	 * @param activity
	 *            Activity to check for an accessToken and/or call a
	 *            RemoteAuthorizeActivity Intent.
	 */
	public static void authorize(Activity activity) {
		String accessToken = RemoteAuthHelper.getAccessToken(activity);

		if (!StringUtils.isNullOrEmpty(accessToken)) {
			KillSwitch.authorize(activity);
		} else {
			Intent intent = new Intent(activity, RemoteAuthorizeActivity.class);
			intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			activity.startActivity(intent);
		}
	}
}
