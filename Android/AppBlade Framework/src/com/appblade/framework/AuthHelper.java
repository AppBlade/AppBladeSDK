package com.appblade.framework;

import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.DialogInterface.OnCancelListener;
import android.content.Intent;
import android.os.Build;

public class AuthHelper {
	
	public static void checkAuthorization(final Activity activity, boolean shouldPrompt) {
		
		if(shouldPrompt) {
			AlertDialog.Builder builder = new AlertDialog.Builder(activity);
			builder.setMessage("Authorization Required");
			builder.setPositiveButton("Continue", new DialogInterface.OnClickListener() {
				
				public void onClick(DialogInterface dialog, int which) {
					authorize(activity);
				}
			});
			builder.setNegativeButton("No thanks", new DialogInterface.OnClickListener() {
				
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
		}
		else
		{
			authorize(activity);
		}
		
	}
	
	public static void checkRegistration(final Activity activity)
	{
		String accessToken = RemoteAuthHelper.getAccessToken(activity);
		if (accessToken == null || accessToken.length() == 0)
		{
			String tempToken = AuthHelper.MD5_Hash(Build.ID);
			RemoteAuthHelper.store(activity, tempToken);
		}
		
		KillSwitch.authorize(activity, true);
	}

	private static void authorize(Activity activity) {
		
		String accessToken = RemoteAuthHelper.getAccessToken(activity);
		
		if(!StringUtils.isNullOrEmpty(accessToken)) {
			KillSwitch.authorize(activity, false);
		}
		else {
			Intent intent = new Intent(activity, RemoteAuthorizeActivity.class);
			activity.startActivity(intent);
		}
	}
	
	public static String MD5_Hash(String s) {
        MessageDigest m = null;

        try {
                m = MessageDigest.getInstance("MD5");
        } catch (NoSuchAlgorithmException e) {
                e.printStackTrace();
        }

        m.update(s.getBytes(),0,s.length());
        String hash = new BigInteger(1, m.digest()).toString(16);
        return hash;
	}

}
