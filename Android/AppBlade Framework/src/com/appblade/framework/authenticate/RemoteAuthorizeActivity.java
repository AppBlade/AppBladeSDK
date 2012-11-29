package com.appblade.framework.authenticate;

import android.app.Activity;
import android.app.ProgressDialog;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.util.Log;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import com.appblade.framework.AppBlade;
import com.appblade.framework.WebServiceHelper;
import com.appblade.framework.authenticate.AuthTokensDownloadTask.OnPostExecuteListener;

public class RemoteAuthorizeActivity extends Activity {
	
	private static final String EndpointAuthNew = "/oauth/authorization/new?client_id=%s&response_type=code";
	
	ProgressDialog progress;
	JavascriptInterface jsInterface;
	
	WebView webview;
	
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        webview = new WebView(this);
        setContentView(webview);
        
        initControls();
    }

	private void initControls() {
        String path = String.format(EndpointAuthNew, AppBlade.appInfo.Token);
        final String authUrl = WebServiceHelper.getUrl(path);
        jsInterface = new JavascriptInterface();

        webview.getSettings().setJavaScriptEnabled(true);
        webview.setScrollBarStyle(WebView.SCROLLBARS_INSIDE_OVERLAY);
        webview.addJavascriptInterface(jsInterface, "Android");
        webview.setWebChromeClient(new WebChromeClient() {
        	public void onProgressChanged(WebView view, int progress) {
        		// Activities and WebViews measure progress with different scales.
        		// The progress meter will automatically disappear when we reach 100%
        		setProgress(progress * 100);
        	}
        });

        webview.setWebViewClient(new WebViewClient() {

			@Override
			public void onLoadResource(WebView view, String url) {
//				Log.d(AppBlade.LogTag, String.format("onLoadResource url: %s", url));
				super.onLoadResource(view, url);
			}

			@Override
			public void onPageFinished(WebView view, String url) {
				Log.d(AppBlade.LogTag, String.format("onPageFinished url: %s", url));
				super.onPageFinished(view, url);
				
				if(progress != null && progress.isShowing())
					progress.dismiss();
			}

			@Override
			public void onPageStarted(WebView view, String url, Bitmap favicon) {
				Log.d(AppBlade.LogTag, String.format("onPageStarted url: %s", url));
				super.onPageStarted(view, url, favicon);
				
				if(progress == null || !progress.isShowing())
					progress = ProgressDialog.show(RemoteAuthorizeActivity.this, null, "loading...");
			}
        	
        });
        
		webview.loadUrl(authUrl);
	}
	
	class JavascriptInterface {
		public void notifyAuthCode(final String code) {
			final String message = String.format("JavascriptInterface.notifyAuthCode code: %s", code);
			Log.d(AppBlade.LogTag, message);
			
			runOnUiThread(new Runnable() {
				
				public void run() {
					AuthTokensDownloadTask task = new AuthTokensDownloadTask(RemoteAuthorizeActivity.this);
					task.setOnPostExecuteListener(new OnPostExecuteListener() {
						
						public void onPostExecute() {
							AppBlade.authorize(RemoteAuthorizeActivity.this, true);
						}
					});
					task.execute(code);
				}
			});
		}
	}

}
