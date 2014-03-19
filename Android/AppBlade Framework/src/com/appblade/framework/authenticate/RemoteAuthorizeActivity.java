package com.appblade.framework.authenticate;

import android.app.Activity;
import android.app.ProgressDialog;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;


import com.appblade.framework.AppBlade;
import com.appblade.framework.WebServiceHelper;


/**
 * Activity to prompt the user to authorize themselves to use the app. <br>
 * Prompts a WebView that talks to AppBlade where the user signs in with their valid credentials.<br>
 * WARNING: Uses javascript. If you are using a custom endpoint make sure you trust the site you are accessing.<br>
 */
public class RemoteAuthorizeActivity extends Activity {
	
	private static final String EndpointAuthNew = "/oauth/authorization/new?client_id=%s&response_type=code";
	
	ProgressDialog progress;
	AuthJavascriptInterface jsInterface;
	
	WebView webview;
	
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        webview = new WebView(this);
        setContentView(webview);
        
        initControls();
    }

    /**
     * Initializes the WebView and defines the WebClient behavior.
     */
	private void initControls() {
        String path = String.format(EndpointAuthNew, AppBlade.appInfo.Token);
        final String authUrl = WebServiceHelper.getUrl(path);
        Log.v(AppBlade.LogTag, "Loading URL in WebView "  + authUrl);
        this.jsInterface = new AuthJavascriptInterface(RemoteAuthorizeActivity.this);

        webview.getSettings().setJavaScriptEnabled(true);
        webview.setScrollBarStyle(View.SCROLLBARS_INSIDE_OVERLAY);
        webview.addJavascriptInterface(this.jsInterface, "Android");
        webview.setWebChromeClient(new WebChromeClient() {
        	@Override
			public void onProgressChanged(WebView view, int progress) {
        		// Activities and WebViews measure progress with different scales.
        		// The progress meter will automatically disappear when we reach 100%
        		setProgress(progress * 100);
        	}
        });

        webview.setWebViewClient(new WebViewClient() {
			@Override
			public void onLoadResource(WebView view, String url) {
				if(url.contains("secure.livechatinc.com"))
				{
					
				}else{
					Log.d("AppBlade", url);
				}
				
				super.onLoadResource(view, url);
			}
			@Override
			public void onPageFinished(WebView view, String url) {
				super.onPageFinished(view, url);
				if(progress != null && progress.isShowing())
					progress.dismiss();
			}
			@Override
			public void onPageStarted(WebView view, String url, Bitmap favicon) {
				super.onPageStarted(view, url, favicon);
				
				if(progress == null || !progress.isShowing())
					progress = ProgressDialog.show(RemoteAuthorizeActivity.this, null, "loading...");
			}
        });
        
		webview.loadUrl(authUrl);
	}
}
