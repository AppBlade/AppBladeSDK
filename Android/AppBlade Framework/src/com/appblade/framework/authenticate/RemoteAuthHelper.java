package com.appblade.framework.authenticate;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.util.Locale;

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
		String basename = String.format(Locale.US, "%s::%s", packageName, defaultFileName);
		String filename = String.format(Locale.US, "app_%s.txt", StringUtils.md5(basename));
		
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
		Log.v(AppBlade.LogTag, "RemoteAuthHelper.store(Context context, String tokenType, String accessToken, String refreshToken, int expiresIn)");

		try
		{
			String filename = getAccessTokenFilename(context.getApplicationContext());
			Log.v(AppBlade.LogTag, "RemoteAuthHelper.store writing " + accessToken + " to " + filename);

			FileOutputStream fos = context.openFileOutput(filename, Context.MODE_PRIVATE);
			fos.write(accessToken.getBytes());
			IOUtils.safeClose(fos);

			Log.v(AppBlade.LogTag, String.format("RemoteAuthHelper.store token:%s", accessToken));
			Log.v(AppBlade.LogTag, String.format("RemoteAuthHelper.store path:%s", filename));
			
			AppBlade.setDeviceId(accessToken);
		}
		catch (Exception ex) { Log.w(AppBlade.LogTag, "RemoteAuthHelper store ", ex); }
	}
	
	/**
	 * remove the auth token variables securely 
	 * @param context
	 */	
	public static void clear(Context context) {
		try
		{
			String filename = getAccessTokenFilename(context.getApplicationContext());
			context.deleteFile(filename);

			Log.v(AppBlade.LogTag, String.format("RemoteAuthHelper.clear (delete file) path:%s", filename));
			
			AppBlade.setDeviceId(null);
		}
		catch (Exception ex) {  Log.w(AppBlade.LogTag, "RemoteAuthHelper clear ", ex); }
	}
	
	/**
	 * retrieve the auth token string securely 
	 * @param context Context used to read storage
	 * @return String of the stored access token, returns "" if no access token exists.
	 */	
	public static String getAccessToken(Context context) {
		String accessToken = "";
		String filename = getAccessTokenFilename(context.getApplicationContext());
		File authFile = new File(context.getFilesDir(), filename);
		try
		{
			if(!authFile.exists() || authFile.isDirectory()){
				authFile.delete();
				Log.e(AppBlade.LogTag, "Access Token: Trying to create Authfile location : " + authFile.getAbsolutePath());
				String string = "";
				FileOutputStream outputStream;
				try {
				  outputStream = context.openFileOutput(filename, Context.MODE_PRIVATE);
				  outputStream.write(string.getBytes());
				  outputStream.close();
				} catch (Exception e) {
				  e.printStackTrace();
				}
			}
			Log.v(AppBlade.LogTag, "Access Token: Authfile opening file: " + filename);
			Log.v(AppBlade.LogTag, "Access Token: Authfile opening file: " + authFile.getName());
			FileInputStream fis = context.openFileInput(authFile.getName());
		    InputStreamReader inputStreamReader = new InputStreamReader(fis);
		    BufferedReader bufferedReader = new BufferedReader(inputStreamReader);
		    accessToken = bufferedReader.readLine();
		}
		catch (Exception ex) { 
			Log.w(AppBlade.LogTag, "Error creating Access Token ", ex); 
			if(authFile.exists()){
				Log.w(AppBlade.LogTag, "Bullshit "); 
			}
		}
		if(!authFile.exists()){
			Log.e(AppBlade.LogTag, "Did not create Authfile location : " + authFile);
		}
		
		Log.v(AppBlade.LogTag, String.format("getAccessToken File:%s, token:%s", filename, accessToken));
		return accessToken;
	}

}
