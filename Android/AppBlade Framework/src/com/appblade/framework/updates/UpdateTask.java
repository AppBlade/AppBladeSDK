package com.appblade.framework.updates;

import java.io.IOException;

import org.apache.http.HttpResponse;
import org.json.JSONException;
import org.json.JSONObject;

import com.appblade.framework.AppBlade;
import com.appblade.framework.utils.HttpUtils;
import com.appblade.framework.utils.StringUtils;

import android.app.Activity;
import android.app.ProgressDialog;
import android.os.AsyncTask;
import android.util.Log;

/**
 * Class to check for updates asychronously, will automatically kick off a download in the event that one is available and confirmation prompting is disabled.<br>
 * If the requireAuthCredentials flag is set to true (default is false) then the update check will hard-check for authentication of the activity first. Potentially prompting a login dialog.
 * @author andrewtremblay
 */
public class UpdateTask extends AsyncTask<Void, Void, Void> {
	Activity activity;
	ProgressDialog progress;
	public boolean requireAuthCredentials = false; // default anonymous
	public boolean promptDownloadConfirm = true; // default noisy
	
	
	public UpdateTask(Activity _activity, boolean hardCheckAuthenticate, boolean promptForDownload) {
		this.activity = _activity;
		//this.requireAuthCredentials = hardCheckAuthenticate; 
		this.promptDownloadConfirm = promptForDownload;
	}


	
	@Override
	protected void onPreExecute() {
		//check if we already have an apk downloaded but haven't installed. No need to redownload if we do.
	}
	
	@Override
	protected Void doInBackground(Void... params) {
		HttpResponse response = UpdatesHelper.getUpdateResponse(this.requireAuthCredentials);
		
		if(response != null){
			Log.d(AppBlade.LogTag, String.format("Response status:%s", response.getStatusLine()));
		}
		handleResponse(response);
		return null;
	}

	/**
	 * Handles the response back from the server. Gets new ttl and an optional update notification. 
	 * @see UpdatesHelper
	 * @param response
	 */
	private void handleResponse(HttpResponse response) {
		if(HttpUtils.isOK(response)) {
			try {
				String data = StringUtils.readStream(response.getEntity().getContent());
				Log.d(AppBlade.LogTag, String.format("UpdateTask response OK %s", data));
				JSONObject json = new JSONObject(data);
				int timeToLive = json.getInt("ttl");
				if(json.has("update")) {
					JSONObject update = json.getJSONObject("update");
					if(update != null) {
						if(this.promptDownloadConfirm)
						{
							UpdatesHelper.confirmUpdate(this.activity, update);
						}
						else
						{
							UpdatesHelper.processUpdate(this.activity, update);								
						}
					}
				}
			}
			catch (IOException ex) { ex.printStackTrace(); }
			catch (JSONException ex) { ex.printStackTrace(); }
		}
	}
}
