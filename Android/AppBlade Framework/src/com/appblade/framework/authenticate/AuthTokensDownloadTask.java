package com.appblade.framework.authenticate;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;

import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
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

import android.app.ProgressDialog;
import android.content.Context;
import android.os.AsyncTask;
import android.util.Log;

public class AuthTokensDownloadTask extends AsyncTask<String, String, Void> {

	ProgressDialog progress;
	Context context;
	OnPostExecuteListener onPostExecuteListener;
	
	public AuthTokensDownloadTask(Context context) {
		this.context = context;
	}
	
	public void setOnPostExecuteListener(OnPostExecuteListener listener) {
		onPostExecuteListener = listener;
	}

	@Override
	protected void onPreExecute() {
		progress = ProgressDialog.show(context, null, "Authorizing...");
	}
	
	@Override
	protected Void doInBackground(String... params) {
		
		String code = params[0];
		HttpClient client = HttpClientProvider.newInstance(SystemUtils.UserAgent);
		
		try {
			String url = WebServiceHelper.getUrl(WebServiceHelper.ServicePathOauthTokens);
			HttpPost request = new HttpPost();
			request.setURI(new URI(url));
			WebServiceHelper.addCommonHeaders(request);
			
			List<NameValuePair> postParams = new ArrayList<NameValuePair>();
			postParams.add(new BasicNameValuePair("code", code));
			postParams.add(new BasicNameValuePair("client_id", AppBlade.appInfo.Token));
			postParams.add(new BasicNameValuePair("client_secret", AppBlade.appInfo.Secret));
			request.setEntity(new UrlEncodedFormEntity(postParams));
			
			HttpResponse response = client.execute(request);
			handleResponse(response);
		}
		catch (URISyntaxException e) { }
		catch (UnsupportedEncodingException e) { }
		catch (ClientProtocolException e) { }
		catch (IOException e) { }
		finally {
			IOUtils.safeClose(client);
		}
		
		
		return null;
	}

	private void handleResponse(HttpResponse response) {
		if(HttpUtils.isOK(response)) {
			try {
				String data = StringUtils.readStream(response.getEntity().getContent());
				Log.d(AppBlade.LogTag, data);
				JSONObject json = new JSONObject(data);
				
				String accessToken = json.getString("access_token");
				
				// Currently unused
//				int expires = json.getInt("expires_in");
//				String token_type = json.getString("token_type");
//				String refresh_token = json.getString("refresh_token");
				
				RemoteAuthHelper.store(context, accessToken);
			}
			catch (IOException ex) { }
			catch (JSONException ex) { }
		}
	}

	@Override
	protected void onCancelled() {
		if(progress != null && progress.isShowing())
			progress.dismiss();
	}

	@Override
	protected void onPostExecute(Void result) {
		if(progress != null && progress.isShowing())
			progress.dismiss();
		
		if(onPostExecuteListener != null)
			onPostExecuteListener.onPostExecute();
	}
	
	public interface OnPostExecuteListener {
		public void onPostExecute();
	}

}
