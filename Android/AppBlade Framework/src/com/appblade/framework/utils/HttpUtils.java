package com.appblade.framework.utils;

import org.apache.http.Header;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpHead;


public class HttpUtils {
	
	public final static String HeaderLastModified = "Last-Modified";
	public final static String HeaderContentLength = "Content-Length";
	public final static String HeaderContentType = "Content-Type";
	public final static String HeaderAccept = "Accept";

	public final static String ContentTypeJson = "application/json";
	public final static String ContentTypeJpeg = "image/jpeg";
	public final static String ContentTypeMultipartFormData = "multipart/form-data";
	public final static String ContentTypeOctetStream = "application/octet-stream";

	public static long getHeaderAsLong(String url, String name) {
		long val = 0;
		Header header = getHeader(url, name);
		if(header != null) {
			String asString = header.getValue();
			if(!StringUtils.isNullOrEmpty(asString))
				val = Long.valueOf(asString);
		}
		return val;
	}
	
	public static Header getHeader(String url, String name) {
		Header header = null;
		HttpResponse response = null;
		try
		{
			HttpClient client = HttpClientProvider.newInstance("Android");
			HttpHead request = new HttpHead(url);
		    response = client.execute(request);
		}
		catch(Exception ex) { }
		if(response != null) {
			header = response.getFirstHeader(name);
		}
		return header;
	}

	public static boolean isOK(HttpResponse response) {
		return
				response != null &&
				response.getStatusLine() != null &&
				response.getStatusLine().getStatusCode() / 100 == 2;
	}

	public static boolean isUnauthorized(HttpResponse response) {
		return
				response != null &&
				response.getStatusLine() != null &&
				response.getStatusLine().getStatusCode() / 100 == 4;
	}

}
