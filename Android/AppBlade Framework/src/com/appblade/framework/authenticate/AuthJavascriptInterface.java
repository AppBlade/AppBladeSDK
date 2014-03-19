package com.appblade.framework.authenticate;

import android.app.Activity;
import android.util.Log;
import android.webkit.JavascriptInterface;

import com.appblade.framework.AppBlade;
import com.appblade.framework.authenticate.AuthTokensDownloadTask.OnPostExecuteListener;

public class AuthJavascriptInterface {
	Activity mActivity = null;
	
	public AuthJavascriptInterface(Activity activity)
	{
		super();
		mActivity = activity;
	}
	
	/**
	 * Javascript interface that will download the AuthTokens to local storage (inside RemoteAuthHelper) on notification. It confirms the storage by reauthorizing through AppBlade.
	 */
	
	@JavascriptInterface
	public void notifyAuthCode(final String code) {
			final String message = String.format("js interface called from Android.notifyAuthCode code: %s", code);
			Log.v(AppBlade.LogTag, message);
			
			if(mActivity != null){
				Log.v(AppBlade.LogTag, String.format("storing token"));

				mActivity.runOnUiThread(new Runnable() {
					public void run() {
						AuthTokensDownloadTask task = new AuthTokensDownloadTask(mActivity);
						task.setOnPostExecuteListener(new OnPostExecuteListener() {
							public void onPostExecute() {
								Log.v(AppBlade.LogTag, String.format("reauthorizing"));

								AppBlade.authorize(mActivity, true);
							}
						});
						task.execute(code);
					}
				});
			}
			else
			{
				Log.v(AppBlade.LogTag, "mActivity null, no token");
			}
		}
}
