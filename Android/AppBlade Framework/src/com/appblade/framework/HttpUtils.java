package com.appblade.framework;

import org.apache.http.HttpResponse;

public class HttpUtils {

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
