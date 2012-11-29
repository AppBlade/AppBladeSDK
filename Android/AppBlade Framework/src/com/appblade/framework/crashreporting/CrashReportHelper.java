package com.appblade.framework.crashreporting;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.net.URI;
import java.util.Random;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;

import android.util.Log;

import com.appblade.framework.AppBlade;
import com.appblade.framework.WebServiceHelper;
import com.appblade.framework.WebServiceHelper.HttpMethod;
import com.appblade.framework.utils.ExceptionUtils;
import com.appblade.framework.utils.HttpClientProvider;
import com.appblade.framework.utils.IOUtils;
import com.appblade.framework.utils.StringUtils;

public class CrashReportHelper {

	public static Boolean postCrashes(CrashReportData data) {
		writeExceptionToDisk(data.exception);
		postExceptionsToServer();
		return false;
	}

	private static void writeExceptionToDisk(Throwable e) {
		try
		{
			String systemInfo = AppBlade.appInfo.getSystemInfo();
			String stackTrace = ExceptionUtils.getStackTrace(e);

			if(!StringUtils.isNullOrEmpty(stackTrace))
			{
				int r = new Random().nextInt(9999);
				String filename = String.format("%s/ex-%d-%d.txt",
						AppBlade.rootDir, System.currentTimeMillis(), r);

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
			Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", ex.getClass().getCanonicalName(), ex.getMessage()));
		}
	}

	private static void postExceptionsToServer() {

		File exceptionDir = new File(AppBlade.rootDir);
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
				String urlPath = String.format(WebServiceHelper.ServicePathCrashReportsFormat, AppBlade.appInfo.AppId, AppBlade.appInfo.Ext);
				String url = WebServiceHelper.getUrl(urlPath);
				String authHeader = WebServiceHelper.getHMACAuthHeader(AppBlade.appInfo, urlPath, content, HttpMethod.POST);

				Log.d(AppBlade.LogTag, urlPath);
				Log.d(AppBlade.LogTag, url);
				Log.d(AppBlade.LogTag, authHeader);

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
			Log.d(AppBlade.LogTag, String.format("%s %s", ex.getClass().getSimpleName(), ex.getMessage()));
		}

		IOUtils.safeClose(client);

		// delete the file
		if(success && f.exists())
		{
			f.delete();
		}
	}


	
}
