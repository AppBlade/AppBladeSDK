package com.appblade.framework.crashreporting;

import java.io.BufferedWriter;
import java.io.ByteArrayOutputStream;
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

/**
 * Holder for functions related to storing and handling crashes.
 * Note there is no handling currently for how many crashes can be stored locally, you can delete them manually from your app settings. 
 * @author andrew.tremblay@raizlabs
 * @see AppBLadeExceptionHandler
 */
public class CrashReportHelper {
	/**
	 * Store the passed CrashReportData object and attempt to post it to AppBlade.
	 * Stored CrashReportData will be removedonly on success. 
	 * @param data The CrashReportData containing the exception we want to report. 
	 * @return false
	 * @see PostCrashReportTask
	 */
	public static Boolean postCrashes(CrashReportData data) {
		writeExceptionToDisk(data.exception); //removed only on success see sendExceptionData(File)
		postExceptionsToServer(); //every call will attempt to post EVERY exception in the exception directory to AppBlade.Removing them on success. 
		return false;
	}

	/**
	 * Iterates through every file in the exception directory and attempts a POST to AppBlade with the each. <br>  
	 * Handled asynchronously within {@link PostCrashReportTask} 
	 */
	public static void postExceptionsToServer() {
		File exceptionDir = new File(AppBlade.exceptionsDir);
		if(exceptionDir.exists() && exceptionDir.isDirectory()) {
			File[] exceptions = exceptionDir.listFiles();
			for(File f : exceptions) {
				if(f.exists() && f.isFile()) {
					sendExceptionData(f);
				}
			}
		}
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
				AppBlade.Log("writing to " + newFilename);
				if(file.createNewFile())
				{
					BufferedWriter writer = new BufferedWriter(new FileWriter(newFilename));
					writer.write(systemInfo);
					writer.write(stackTrace);
					writer.close();
					AppBlade.Log("wrote to " + file.getName());
				}
			}
		}
		catch(Exception ex)
		{
			AppBlade.Log( String.format("Ex: %s, %s", ex.getClass().getCanonicalName(), ex.getMessage()));
		}
	}

	/**
	 * Handles the reading,sending and deletion (on success) of a file ()
	 * @param f CrashReport stored file to send to the AppBade server.
	 * @return true on successful send, will also delete() the File. 
	 */
	private static synchronized boolean sendExceptionData(File f) {
		boolean success = false;
		HttpClient client = HttpClientProvider.newInstance(SystemUtils.UserAgent);
		AppBlade.Log( "sending exception in file " + f.getName());

		try
		{
			FileInputStream fis = new FileInputStream(f);
			String content = StringUtils.readStream(fis);
			String sharedBoundary = AppBlade.genDynamicBoundary();
			
			final MultipartEntity crashContent = CrashReportHelper.getPostCrashReportBody(content, CustomParamDataHelper.getCustomParamsAsJSON(), sharedBoundary);
			if(!StringUtils.isNullOrEmpty(content))
			{
				String urlPath = String.format(WebServiceHelper.ServicePathCrashReportsFormat);
				String url = WebServiceHelper.getUrl(urlPath);

				HttpPost request = new HttpPost();
				request.setURI(new URI(url));
				
				ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
				crashContent.writeTo(outputStream);
				String multipartRawContent = outputStream.toString();

				String authHeader = WebServiceHelper.getHMACAuthHeader(AppBlade.appInfo, urlPath, multipartRawContent, HttpMethod.POST);
				request.addHeader("Content-Type", HttpUtils.ContentTypeMultipartFormData + "; boundary=" + sharedBoundary);
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
			AppBlade.Log( String.format("%s %s", ex.getClass().getSimpleName(), ex.getMessage()));
		}

		IOUtils.safeClose(client);

		// delete the file
		if(success && f.exists())
		{
			f.delete();
		}
		return success;
	}

	private static MultipartEntity getPostCrashReportBody(String content, JSONObject customParamsAsJSON, String boundary) {
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
			AppBlade.Log( e.toString());
		}
		
		return entity;
	}
	
	private static String newCrashFileName()
	{
		int r = new Random().nextInt(9999);
		String filename = String.format("%s%sex-%d-%d.txt",
				AppBlade.exceptionsDir, "/", System.currentTimeMillis(), r);
		return filename;
	}
	
}
