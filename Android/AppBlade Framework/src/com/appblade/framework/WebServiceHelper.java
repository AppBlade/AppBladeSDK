package com.appblade.framework;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.Locale;
import java.util.Random;

import org.apache.http.HttpRequest;

import com.appblade.framework.utils.Base64;
import com.appblade.framework.utils.StringUtils;
import com.appblade.framework.utils.SystemUtils;

import android.content.pm.PackageInfo;
import android.os.Build;
import android.util.Log;

/**
 * Helper class containing functions for building AppBlade service requests.
 * <br>
 * Current API level is 2.0
 * 
 * @author andrew.tremblay@raizlabs
 * @author rich.stern@raizlabs
 */
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
	
	/**
	 * Builds an HMAC Authentication header for the given API call. 
	 * @param appInfo AppInfo of the current device and apk
	 * @param urlPath String of the service path for the AppBlade API
	 * @param contents String contents of the raw body of the request, can be empty or null
	 * @param method HTTP method for the request, <ul> Supported HTTP Methods:
	 * <li>POST
	 * <li>GET
	 * <li>PUT
	 * </ul>
	 * @return String of an HMAC header in the format <br><code>HMAC id="...", nonce="...", body-hash="...", ext="...", mac="..."</code>
	 */
	public static String getHMACAuthHeader(AppInfo appInfo, String urlPath, String contents, HttpMethod method) {
		//do we need this AppInfo to be passed here since AppBlade already has what we declared within AppBlade.appInfo? Probably not, but well keep in the event that we'll have larger services in place that will need it. 
			String requestBodyRaw = null;
		if(!StringUtils.isNullOrEmpty(contents))
			requestBodyRaw = String.format(Locale.US, "%s?%s", urlPath, contents);
		else
			requestBodyRaw = urlPath;
				
		byte[] requestBodyRawSha256 = StringUtils.sha256(requestBodyRaw);
		String requestBodyHash = Base64.encodeToString(requestBodyRawSha256, 0).trim();

		int seconds = (int) ((System.currentTimeMillis() / 1000) - StringUtils.safeParse(appInfo.Issuance, 0));
		String nonce = String.format(Locale.US, "%d:%s", seconds, getRandomNonceString(WebServiceHelper.NonceRandomStringLength));
		
		String methodName = method.toString();
		Log.d(AppBlade.LogTag, String.format("getHMACAuthHeader:methodName: %s", methodName));
		
		String requestBody = String.format("%s%n%s%n%s%n%s%n%s%n%s%n%s%n",
				nonce, methodName, requestBodyRaw, appInfo.CurrentEndpoint, WebServiceHelper.getCurrentPortAsString(), requestBodyHash, appInfo.Ext);
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

	/**
	 * Adds common AppBlade headers to the given HttpRequest.
	 * <ul>Headers include, whenever possible:
	 * <li> bundle_version The {@link PackageInfo.versionName} taken from {@link AppBlade.getPackageInfo()} 
	 * <li> executable_uuid {@link com.appblade.framework.utils.SystemUtils.hashedExecutableUuid(PackageInfo pi) }
	 * <li> static_resource_uuid {@link com.appblade.framework.utils.SystemUtils.hashedStaticResourcesUuid(PackageInfo pi) }
	 * <li> certificate_uuid {@link com.appblade.framework.utils.SystemUtils.hashedCertificateUuid(PackageInfo pi) }
	 * <li> android_release The {@link android.os.Build.VERSION.RELEASE} of the OS
	 * <li> android_api The {@link android.os.Build.VERSION.SDK} of the OS
	 * <li> device_mfg The {@link android.os.Build.MANUFACTURER} of the OS
	 * <li> device_model The {@link android.os.Build.MODEL} of the OS
	 * <li> device_id The {@link android.os.Build.ID} of the OS
	 * <li> device_brand The {@link android.os.Build.ID} of the OS
	 * <li> device_fingerprint The {@link android.os.Build.FINGERPRINT} of the OS
	 * </ul>
	 * @param request The HttpRequest to which we've added the above headers. 
	 */
	@SuppressWarnings("deprecation")
	public static void addCommonHeaders(HttpRequest request) {
		if(AppBlade.hasPackageInfo()) {
			PackageInfo pi = AppBlade.getPackageInfo();
			request.addHeader("bundle_version", pi.versionName);
			
			String executable_uuid = SystemUtils.hashedExecutableUuid(pi);
			if(executable_uuid != null){
				request.addHeader("executable_uuid",  executable_uuid);			
				Log.d(AppBlade.LogTag, "executable_uuid " + request.getFirstHeader("executable_uuid"));
			}
			String static_resource_uuid = SystemUtils.hashedStaticResourcesUuid(pi);
			if(static_resource_uuid != null){
				request.addHeader("static_resource_uuid", static_resource_uuid );			
				Log.d(AppBlade.LogTag, "static_resource_uuid " + request.getFirstHeader("static_resource_uuid"));
			}
			String certificate_uuid = SystemUtils.hashedCertificateUuid(pi);
			if(certificate_uuid != null){
				request.addHeader("certificate_uuid", SystemUtils.hashedCertificateUuid(pi) );			
				Log.d(AppBlade.LogTag, "certificate_uuid " + request.getFirstHeader("certificate_uuid"));
			}
		}
		
		request.addHeader("android_release", Build.VERSION.RELEASE);
		request.addHeader("android_api", Build.VERSION.SDK);
		request.addHeader("device_mfg", Build.MANUFACTURER);
		request.addHeader("device_model", Build.MODEL);
		request.addHeader("device_id", Build.ID);
		request.addHeader("device_brand", Build.BRAND);
		request.addHeader("device_fingerprint", Build.FINGERPRINT);
	}

	/**
	 * Helper function to generate a randomized alphanumeric String of a given length
	 * @param length number of random characters.
	 * @return A randomized alphanumeric String of a given length.
	 */
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

	/**
	 * URL builder function. Uses the CurrentServiceScheme and CurrentEndpoint of {@link AppBlade.appInfo}.
	 * @param path Strign of the relative path of the endpoint you want to hit.
	 * @return Full URL of the given path with service scheme and host name pre-appended.
	 */
	public static String getUrl(String path) {
		return String.format("%s%s%s", AppBlade.appInfo.CurrentServiceScheme, AppBlade.appInfo.CurrentEndpoint, path);
	}
	
	/**
	 * Uses {@link #getCurrentPort()}
	 * @return String of the current port, usually 443.
	 */
	public static String getCurrentPortAsString() {
		return String.format(Locale.US, "%d", WebServiceHelper.getCurrentPort());
	}
	
	/**
	 * Calculates the current port that was defined on setup. 
	 * <br>If no port was defined, checks for the default port based off of the given service scheme (http/https)
	 * <br>If no scheme was defined, it assumes https (port 443)
	 * @return integer representing the port to user when communicating with the end point. Usually 443.
	 */
	public static int getCurrentPort() {
		Log.d(AppBlade.LogTag, "Current endpoint " + AppBlade.appInfo.CurrentEndpoint);
		Log.d(AppBlade.LogTag, "Current service scheme " + AppBlade.appInfo.CurrentServiceScheme);
		int portToReturn = 443; //assume secure until otherwise said so
		
		if(AppBlade.appInfo.CurrentEndpoint != null && AppBlade.appInfo.CurrentEndpoint.equals(AppInfo.DefaultAppBladeHost)){
			if(!AppBlade.appInfo.CurrentServiceScheme.equals(AppInfo.DefaultServiceScheme))
			{
				portToReturn = 80;
			}//no check for https here since we're 443 by default
		}
		else  //custom defined endpoint, make sure we're giving the right port
		{
			try {
				URL aURL = new URL(String.format("%s%s", AppBlade.appInfo.CurrentServiceScheme, AppBlade.appInfo.CurrentEndpoint));
				if(aURL.getPort() > 0)
				{
					Log.d(AppBlade.LogTag, "Port! " + aURL.getPort());
					portToReturn = aURL.getPort();
				}
				else
				{
					//no specified port, check the protocol
					if(aURL.getProtocol().equals("http"))
					{
						portToReturn = 80;
					}//no https check required since we're already 443 by default
				}
			} catch (MalformedURLException e) {
				e.printStackTrace();
			}
		}
		
		return portToReturn;
	}


	
	
}
