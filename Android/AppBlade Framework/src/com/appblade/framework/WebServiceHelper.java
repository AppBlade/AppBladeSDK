package com.appblade.framework;

import java.io.IOException;
import java.nio.charset.Charset;
import java.text.SimpleDateFormat;
import java.util.Random;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import org.apache.http.HttpRequest;

import com.appblade.framework.utils.Base64;
import com.appblade.framework.utils.StringUtils;
import com.appblade.framework.utils.SystemUtils;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.os.Build;
import android.util.Log;


public class WebServiceHelper {
	
	public enum HttpMethod {
		POST,
		GET, 
		PUT
	}
	
	static final int NonceRandomStringLength = 74;
	
	public static final String ServicePathCrashReportsFormat = "/api/2/projects/%s/devices/%s/crash_reports";
	public static final String ServicePathFeedbackFormat = "/api/projects/%s/devices/%s/feedback";
	public static final String ServicePathSessionFormat =  "/api/user_sessions";
	public static final String ServicePathKillSwitchFormat = "/api/2/projects/%s/devices/%s";
	public static final String ServicePathOauthTokens = "/oauth/tokens";
	
	//do we need this AppInfo here since AppBlade already has what we declared within AppBlade.appInfo?
	public static String getHMACAuthHeader(AppInfo appInfo, String urlPath, String contents, HttpMethod method) {
		
		String requestBodyRaw = null;
		if(!StringUtils.isNullOrEmpty(contents))
			requestBodyRaw = String.format("%s?%s", urlPath, contents);
		else
			requestBodyRaw = urlPath;
				
		byte[] requestBodyRawSha256 = StringUtils.sha256(requestBodyRaw);
		String requestBodyHash = Base64.encodeToString(requestBodyRawSha256, 0).trim();

		int seconds = (int) ((System.currentTimeMillis() / 1000) - StringUtils.safeParse(appInfo.Issuance, 0));
		String nonce = String.format("%d:%s", seconds, getRandomNonceString(WebServiceHelper.NonceRandomStringLength));
		
		String methodName = method.name().trim();
		Log.d(AppBlade.LogTag, String.format("getHMACAuthHeader:methodName: %s", methodName));
		
		String requestBody = String.format("%s%n%s%n%s%n%s%n%s%n%s%n%s%n",
				nonce, methodName, requestBodyRaw, appInfo.CurrentEndpoint, "443", requestBodyHash, appInfo.Ext);
		String mac = StringUtils.hmacSha256(appInfo.Secret, requestBody).trim();
		
		byte[] normalizedRequestBodySha256 = StringUtils.sha256(requestBody);
		String normalizedRequestBodyHash = Base64.encodeToString(normalizedRequestBodySha256, 0);

		Log.d(AppBlade.LogTag, String.format("requestBody: %s", requestBody));
		Log.d(AppBlade.LogTag, String.format("requestBody length: %d", requestBody.length()));
		Log.d(AppBlade.LogTag, String.format("requestBody sha256+base64: %s", normalizedRequestBodyHash));
		Log.d(AppBlade.LogTag, String.format("requestBody sha256+base64 length: %d", normalizedRequestBodyHash.length()));
		Log.d(AppBlade.LogTag, String.format("mac: %s", mac));
		
		StringBuilder builder = new StringBuilder();
		builder.append("HMAC ");
		StringUtils.append(builder, "id=\"%s\", ", appInfo.Token);
		StringUtils.append(builder, "nonce=\"%s\", ", nonce);
		StringUtils.append(builder, "body-hash=\"%s\", ", requestBodyHash);
		StringUtils.append(builder, "ext=\"%s\", ", appInfo.Ext);
		StringUtils.append(builder, "mac=\"%s\"", mac);
		
		String authHeader = builder.toString();
		return authHeader;
	}

	private static String getRandomNonceString(int length) {
		String letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
		StringBuilder builder = new StringBuilder();
		Random random = new Random();
		for(int i = 0; i < length; i++)
		{
			builder.append(letters.charAt(random.nextInt(letters.length())));
		}
		return builder.toString();
	}

	public static String getUrl(String path) {
		return String.format("%s%s%s", AppBlade.appInfo.CurrentServiceScheme, AppBlade.appInfo.CurrentEndpoint, path);
	}
	
	public static void addCommonHeaders(HttpRequest request) {
		if(AppBlade.hasPackageInfo()) {
			PackageInfo pi = AppBlade.getPackageInfo();
			request.addHeader("bundle_version", pi.versionName);
//			request.addHeader("executable_uuid", SystemUtils.generateUniqueID(pi));			
			request.addHeader("executable_uuid", SystemUtils.hashedExecutableUuid(pi) );			
			Log.d(AppBlade.LogTag, "Request Header " + request.getFirstHeader("executable_uuid"));
			request.addHeader("static_resource_uuid", SystemUtils.hashedStaticResourcesUuid(pi) );			
			Log.d(AppBlade.LogTag, "Request Header " + request.getFirstHeader("static_resource_uuid"));
			request.addHeader("certificate_uuid", SystemUtils.hashedCertificateUuid(pi) );			
			Log.d(AppBlade.LogTag, "Request Header " + request.getFirstHeader("certificate_uuid"));
		}
		

		
		request.addHeader("android_release", Build.VERSION.RELEASE);
		request.addHeader("android_api", Build.VERSION.SDK);
		request.addHeader("device_mfg", Build.MANUFACTURER);
		request.addHeader("device_model", Build.MODEL);
		request.addHeader("device_id", Build.ID);
		request.addHeader("device_brand", Build.BRAND);
		request.addHeader("device_fingerprint", Build.FINGERPRINT);
	}


	
	
}
