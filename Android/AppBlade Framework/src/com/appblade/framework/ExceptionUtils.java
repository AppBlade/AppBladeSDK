package com.appblade.framework;

import java.io.File;
import java.io.FileInputStream;

import org.json.JSONObject;

import android.util.Log;


class ExceptionUtils {
	
	static String getStackTrace(Throwable e)
	{
		StringBuilder builder = new StringBuilder();
		
		Throwable current = e;
		StringUtils.append(builder, "%s: %s%n", e.getClass().getCanonicalName(), e.getMessage());
		
		while(current != null)
		{
			StackTraceElement[] stack = current.getStackTrace();
			for(StackTraceElement element : stack)
			{
				if(element.isNativeMethod())
					StringUtils.append(builder, "    %s(Native Method)%n", element.getClassName());
				else
					StringUtils.append(builder, "    %s(%s:%d)%n", element.getClassName(), element.getFileName(), element.getLineNumber());
			}
			
			current = current.getCause();
			if(current != null)
			{
				StringUtils.append(builder, " ### CAUSED BY ### : %s%n", current.toString());
			}
		}
		return builder.toString();
	}
	
	static byte[] buildExceptionBody(File f, String boundary)
	{
		
		byte[] contentByte = String.format("--%s\r\n", boundary).getBytes();
		
		
		try {
			if (AppBlade.customFields != null) {
				byte[] paramsHeaderByte = String.format("Content-Disposition: form-data; name=\"custom_params\"\r\nContent-Type: application/json\r\n\r\n").getBytes();
				contentByte = WebServiceHelper.concatenateByteArrays(contentByte, paramsHeaderByte);
				JSONObject customParams = new JSONObject(AppBlade.customFields);
				
				// from: http://stackoverflow.com/questions/5474916/multipartentity-not-creating-good-request
				byte[] paramsByte = customParams.toString().getBytes();
				contentByte = WebServiceHelper.concatenateByteArrays(contentByte, paramsByte);
				
				byte[] boundaryByte = String.format("\r\n--%s\r\n", boundary).getBytes();
				contentByte = WebServiceHelper.concatenateByteArrays(contentByte, boundaryByte);
			}
			
			byte[] exceptionHeaderByte = String.format("Content-Disposition: form-data; name=\"file\"; filename=\"report.crash\"\r\nContent-Type: text/plain\r\n\r\n").getBytes();
			
			contentByte = WebServiceHelper.concatenateByteArrays(contentByte, exceptionHeaderByte);
			
			FileInputStream fis = new FileInputStream(f);
			String content = StringUtils.readStream(fis);
			
			byte[] exceptionByte = content.getBytes();
			
			contentByte = WebServiceHelper.concatenateByteArrays(contentByte, exceptionByte);
		
		}
		catch(Exception ex)
		{
			Log.d(AppBlade.LogTag, String.format("Build Exception Body Error: %s %s", ex.getClass().getSimpleName(), ex.getMessage()));
		}
		
		byte[] boundaryEndByte = String.format("\r\n--%s--", boundary).getBytes();
		contentByte = WebServiceHelper.concatenateByteArrays(contentByte, boundaryEndByte);
		
		
		return contentByte;
	}

}
