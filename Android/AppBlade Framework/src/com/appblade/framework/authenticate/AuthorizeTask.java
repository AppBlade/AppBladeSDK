package com.appblade.framework.authenticate;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;

import org.apache.http.HttpRequest;
import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpRequestBase;
import org.apache.http.message.BasicNameValuePair;
import org.json.JSONException;
import org.json.JSONObject;

import com.appblade.framework.AppBlade;
import com.appblade.framework.WebServiceHelper;
import com.appblade.framework.utils.HttpClientProvider;
import com.appblade.framework.utils.HttpUtils;
import com.appblade.framework.utils.IOUtils;
import com.appblade.framework.utils.StringUtils;
import com.appblade.framework.utils.SystemUtils;

import android.content.Context;
import android.os.AsyncTask;
import android.util.Log;

public class AuthorizeTask extends AsyncTask<String, String, Void> {
	Context context;
	String url;
	HttpRequestBase request;
	
	public AuthorizeTask(Context context)
	{
		this.context = context;
		this.url = WebServiceHelper.getUrl(WebServiceHelper.ServicePathTokenRefreshFormat);
		this.request = new HttpGet();
	}
	
	public AuthorizeTask(Context context, boolean confirm) {
		this.context = context;

		if(confirm)
		{		
			this.url = WebServiceHelper.getUrl(WebServiceHelper.ServicePathTokenRefreshFormat);
			this.request = new HttpPost();
		}
		else
		{
			this.url = WebServiceHelper.getUrl(WebServiceHelper.ServicePathTokenRefreshFormat);
			this.request = new HttpGet();
		}
	}

	@Override
	protected void onPreExecute() {

	}
	

	@Override
	protected Void doInBackground(String... params) {
		HttpClient client = HttpClientProvider.newInstance(SystemUtils.UserAgent);
		try {
			this.request.setURI(new URI(this.url));
			WebServiceHelper.addCommonHeaders(this.request);
			HttpResponse response = client.execute(this.request);
			handleResponse(response);
		}
		catch (URISyntaxException e) { e.printStackTrace(); }
		catch (UnsupportedEncodingException e) { e.printStackTrace(); }
		catch (ClientProtocolException e) { e.printStackTrace(); }
		catch (IOException e) { e.printStackTrace(); }
		finally {
			IOUtils.safeClose(client);
		}
		return null;
	}

	
	private void handleResponse(HttpResponse response) {
		Log.v(AppBlade.LogTag, "authorize response " + response.getStatusLine());
		if(HttpUtils.isOK(response)) {
			try {
				String data = StringUtils.readStream(response.getEntity().getContent());
				Log.v(AppBlade.LogTag, "authData recieved " + data);
				JSONObject json = new JSONObject(data);
				
				String accessToken = json.getString("access_token");
				
				// Currently unused
				String token_type = json.getString("token_type");
				String refresh_token = json.getString("refresh_token");
				int expires = json.getInt("expires_in");
				
				RemoteAuthHelper.store(context, token_type, accessToken, refresh_token, expires);
			}
			catch (IOException ex) { Log.w(AppBlade.LogTag, "handleResponse(HttpResponse) Error storing AuthToken ", ex); }
			catch (JSONException ex) { Log.w(AppBlade.LogTag, "handleResponse(HttpResponse) Error parsing JSON ", ex); }
		}
	}
	
}
