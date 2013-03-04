package com.appblade.framework.authenticate;

import java.io.InputStream;
import java.security.KeyStore;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

import org.apache.http.client.HttpClient;
import org.apache.http.conn.ClientConnectionManager;
import org.apache.http.conn.scheme.Scheme;
import org.apache.http.conn.scheme.SchemeRegistry;
import org.apache.http.conn.ssl.SSLSocketFactory;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.impl.conn.tsccm.ThreadSafeClientConnManager;

import com.appblade.framework.AppBlade;
import com.appblade.framework.utils.StringUtils;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.DialogInterface.OnCancelListener;
import android.content.Intent;
import android.util.Log;

/**
 * Helper class for functions related to authorization. These functions
 * shouldn't need to be called directly, call {@link
 * AppBlade.authorize(Activity)} instead.
 * 
 * @author rich.stern@raizlabs
 * @author andrew.tremblay@raizlabs
 * */
public class AuthHelper {

	/**
	 * Checks whether the given activity is authorized, does nothing else. <br>
	 * For the login flow see {@link #checkAuthorization(Activity, boolean)};
	 * @param activity Activity to check authorization/prompt dialog. 
	 * @returns true if the current activity is authorized, false in all other cases.
	 */
	public static boolean isAuthorized(Activity activity)
	{
		boolean toRet = false;   // assume not authorized
		String accessToken = RemoteAuthHelper.getAccessToken(activity);
		if(!StringUtils.isNullOrEmpty(accessToken)) {  //we have a token 
			KillSwitch.reloadSharedPrefs(activity); //set latest variables, for best accuracy.
			toRet = KillSwitch.shouldUpdate(); // set if we're in the TTL
		}
		return toRet;
	}
	
	
	/**
	 * Checks whether the given activity is authorized, prompts an optional dialog beforehand. 
	 * @param activity Activity to check authorization/prompt dialog. 
	 * @param shouldPrompt boolean of whether an "Authorization Required" dialog should be shown to the user first.
	 */
	public static void checkAuthorization(final Activity activity,
			boolean shouldPrompt) {
		if (shouldPrompt) {
			AlertDialog.Builder builder = new AlertDialog.Builder(activity);
			builder.setMessage("Authorization Required");
			builder.setPositiveButton("Continue",
					new DialogInterface.OnClickListener() {

						public void onClick(DialogInterface dialog, int which) {
							authorize(activity);
						}
					});
			builder.setNegativeButton("No thanks",
					new DialogInterface.OnClickListener() {
						public void onClick(DialogInterface dialog, int which) {
							dialog.dismiss();
							activity.finish();
						}
					});
			builder.setOnCancelListener(new OnCancelListener() {

				public void onCancel(DialogInterface dialog) {
					dialog.dismiss();
					activity.finish();
				}
			});
			builder.setCancelable(false);
			builder.show();
		} else {
			authorize(activity);
		}

	}

	/**
	 * Function to authorize the given activity. <br>
	 * First checks if the user has an accessToken already with {@link
	 * RemoteAuthHelper.getAccessToken(Activity)}<br>
	 * If an accessToken exists, calls {@link KillSwitch.authorize(Activity)} If
	 * we don't have an accessToken, we start a {@link RemoteAuthorizeActivity}
	 * from the given activity.
	 * 
	 * @param activity
	 *            Activity to check for an accessToken and/or call a
	 *            RemoteAuthorizeActivity Intent.
	 */
	public static void authorize(Activity activity) {
		String accessToken = RemoteAuthHelper.getAccessToken(activity);

		if (!StringUtils.isNullOrEmpty(accessToken)) {
			KillSwitch.authorize(activity);
		} else {
			Intent intent = new Intent(activity, RemoteAuthorizeActivity.class);
			intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			activity.startActivity(intent);
		}
	}

	public static void acceptDebugSSL() {
		try {
			SSLContext ctx = SSLContext.getInstance("TLS");
			ctx.init(null, new TrustManager[] { new X509TrustManager() {
				public void checkClientTrusted(X509Certificate[] chain,
						String authType) {
				}

				public void checkServerTrusted(X509Certificate[] chain,
						String authType) {
				}

				public X509Certificate[] getAcceptedIssuers() {
					return new X509Certificate[] {};
				}
			} }, null);
			HttpsURLConnection.setDefaultSSLSocketFactory(ctx
					.getSocketFactory());
		} catch (Exception e) {
			Log.e(AppBlade.LogTag, "Debug SSL could not be initialized");
			e.printStackTrace();
		}
	}

	public static DefaultHttpClient sslClient(HttpClient client) {
		try {
			X509TrustManager tm = new X509TrustManager() {
				public void checkClientTrusted(X509Certificate[] xcs,
						String string) throws CertificateException {
				}

				public void checkServerTrusted(X509Certificate[] xcs,
						String string) throws CertificateException {
				}

				public X509Certificate[] getAcceptedIssuers() {
					return null;
				}
			};
			SSLContext ctx = SSLContext.getInstance("TLS");
			ctx.init(null, new TrustManager[] { tm }, null);
			SSLSocketFactory ssf = new MySSLSocketFactory(ctx);
			ssf.setHostnameVerifier(SSLSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER);
			ClientConnectionManager ccm = client.getConnectionManager();
			SchemeRegistry sr = ccm.getSchemeRegistry();
			sr.register(new Scheme("https", ssf, 443));
			return new DefaultHttpClient(ccm, client.getParams());
		} catch (Exception ex) {
			ex.printStackTrace();
			return null;
		}
	}

}
