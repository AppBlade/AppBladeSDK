package com.appblade.framework.authenticate;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;

import com.appblade.framework.AppBlade;
import com.appblade.framework.utils.IOUtils;
import com.appblade.framework.utils.StringUtils;

import android.content.Context;
import android.util.Log;

/**
 * Class used mostly for storing, retrieving and clearing the remote Authentication token securely.
 * @author rich.stern@raizlabs
 * @author andrew.tremblay@raizlabs 
 *
 */
public class RemoteAuthHelper {
	
	private static final String defaultFileName = "REMOTE_AUTH";
	
	/**
	 * Create a unique unreadable filename so that rooted device owners won't know what is in this file
	 * @param context
	 * @return filename of access token
	 */
	private static String getAccessTokenFilename(Context context) {
		String packageName = context.getPackageName();
		String basename = String.format("%s::%s", packageName, defaultFileName);
		String filename = StringUtils.md5(basename);
		
		return filename;
	}
	
	
	/**
	 * store the auth token variables securely 
	 * @param context
	 * @param tokenType String type of token we received
	 * @param accessToken String of the access token we received
	 * @param refreshToken String of the refresh token we will use
	 * @param expiresIn  Integer of the amount of time until the token will expire
	 * @return
	 */
	public static void store(Context context, String tokenType, String accessToken, String refreshToken, int expiresIn) {
		try
		{
			String filename = getAccessTokenFilename(context);
			FileOutputStream fos = context.openFileOutput(filename, Context.MODE_PRIVATE);
			fos.write(accessToken.getBytes());
			IOUtils.safeClose(fos);

			Log.d(AppBlade.LogTag, String.format("RemoteAuthHelper.store token:%s", accessToken));
			Log.d(AppBlade.LogTag, String.format("RemoteAuthHelper.store path:%s", filename));
			
			AppBlade.setDeviceId(accessToken);
		}
		catch (Exception ex) { ex.printStackTrace(); }
	}
	
	/**
	 * remove the auth token variables securely 
	 * @param context
	 */	
	public static void clear(Context context) {
		try
		{
			String filename = getAccessTokenFilename(context);
			context.deleteFile(filename);

			Log.d(AppBlade.LogTag, String.format("RemoteAuthHelper.clear (delete file) path:%s", filename));
			
			AppBlade.setDeviceId(null);
		}
		catch (Exception ex) { ex.printStackTrace(); }
	}
	
	/**
	 * retrieve the auth token string securely 
	 * @param context Context used to read storage
	 * @return String of the stored access token, returns "" if no access token exists.
	 */	
	public static String getAccessToken(Context context) {
		String accessToken = "";
		String filename = getAccessTokenFilename(context);
		
		try
		{
			FileInputStream fis = context.openFileInput(filename);
		    InputStreamReader inputStreamReader = new InputStreamReader(fis);
		    BufferedReader bufferedReader = new BufferedReader(inputStreamReader);
		    accessToken = bufferedReader.readLine();
		}
		catch (Exception ex) { ex.printStackTrace(); }
		
		Log.d(AppBlade.LogTag, String.format("getAccessToken File:%s, token:%s", filename, accessToken));
		return accessToken;
	}

}
