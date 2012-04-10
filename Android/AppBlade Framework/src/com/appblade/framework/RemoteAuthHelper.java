package com.appblade.framework;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;

import android.content.Context;
import android.util.Log;

public class RemoteAuthHelper {
	
	private static final String defaultFileName = "REMOTE_AUTH";
	
	/**
	 * Create a unique unreadable filename so that rooted device owners won't know what is in this file
	 * @param context
	 * @return
	 */
	private static String getAccessTokenFilename(Context context) {
		String packageName = context.getPackageName();
		String basename = String.format("%s::%s", packageName, defaultFileName);
		String filename = StringUtils.md5(basename);
		
		return filename;
	}
	
	public static void store(Context context, String accessToken) {
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
		catch (Exception ex) { }
	}
	
	public static void clear(Context context) {
		try
		{
			String filename = getAccessTokenFilename(context);
			context.deleteFile(filename);

			Log.d(AppBlade.LogTag, String.format("RemoteAuthHelper.clear (delete file) path:%s", filename));
			
			AppBlade.setDeviceId(null);
		}
		catch (Exception ex) { }
	}
	
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
		catch (Exception ex) { }
		
		Log.d(AppBlade.LogTag, String.format("getAccessToken File:%s, token:%s", filename, accessToken));
		return accessToken;
	}

}
