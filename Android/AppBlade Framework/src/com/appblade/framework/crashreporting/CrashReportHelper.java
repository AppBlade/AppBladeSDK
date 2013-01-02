package com.appblade.framework.crashreporting;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.net.URI;
import java.util.Random;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.mime.HttpMultipartMode;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.entity.mime.content.ByteArrayBody;
import org.apache.http.entity.mime.content.ContentBody;
import org.apache.http.entity.mime.content.StringBody;
import org.json.JSONObject;

import android.util.Log;

import com.appblade.framework.AppBlade;
import com.appblade.framework.WebServiceHelper;
import com.appblade.framework.WebServiceHelper.HttpMethod;
import com.appblade.framework.customparams.CustomParamDataHelper;
import com.appblade.framework.utils.ExceptionUtils;
import com.appblade.framework.utils.HttpClientProvider;
import com.appblade.framework.utils.HttpUtils;
import com.appblade.framework.utils.IOUtils;
import com.appblade.framework.utils.StringUtils;
import com.appblade.framework.utils.SystemUtils;

public class CrashReportHelper {
	//I/O RELATED
	//Just store the json straight to file
	//private static int maxStoredCrashes = 0;
	//private final boolean dropOldestCrash = true;

	
	private static String newCrashFileName()
	{
		int r = new Random().nextInt(9999);
		String filename = String.format("%s%sex-%d-%d.txt",
				AppBlade.exceptionsDir, File.pathSeparator, System.currentTimeMillis(), r);
		return filename;
	}
	
	
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
				String newFilename = newCrashFileName();
				File file = new File(newFilename);
				if(file.createNewFile())
				{
					BufferedWriter writer = new BufferedWriter(new FileWriter(newFilename));
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

	private static synchronized boolean sendExceptionData(File f) {
		boolean success = false;
		HttpClient client = HttpClientProvider.newInstance(SystemUtils.UserAgent);
		Log.d(AppBlade.LogTag, "sending exception in file " + f.getName());

		try
		{
			FileInputStream fis = new FileInputStream(f);
			String content = StringUtils.readStream(fis);
			String sharedBoundary = AppBlade.genDynamicBoundary();

			Log.d(AppBlade.LogTag, "CRASH content " + content);

			
			final MultipartEntity crashContent = CrashReportHelper.getPostCrashReportBody(content, CustomParamDataHelper.getCustomParamsAsJSON(), sharedBoundary);
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

				request.setEntity(crashContent);

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
		return success;
	}

	private static MultipartEntity getPostCrashReportBody(String content,
			JSONObject customParamsAsJSON, String boundary) {
		MultipartEntity entity = new MultipartEntity(HttpMultipartMode.BROWSER_COMPATIBLE, boundary, null);
		
		try
		{
			ContentBody crashReportBody = new StringBody(content);
			entity.addPart("crash_report", crashReportBody );
			if (customParamsAsJSON != null) {
				ContentBody customParamsBody = new ByteArrayBody(customParamsAsJSON.toString().getBytes("utf-8"),
						 HttpUtils.ContentTypeJson,
						 CustomParamDataHelper.customParamsFileName);
				entity.addPart("custom_params", customParamsBody);
			}
		} 
		catch (IOException e) {
			Log.d(AppBlade.LogTag, e.toString());
		}
		
		return entity;
	}

	
}
