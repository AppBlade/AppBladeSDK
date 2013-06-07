package com.appblade.framework.updates;

import java.io.IOException;

import org.apache.http.HttpResponse;
import org.json.JSONException;
import org.json.JSONObject;

import com.appblade.framework.AppBlade;
import com.appblade.framework.updates.UpdatesHelper.ProgressDelegate;
import com.appblade.framework.utils.HttpUtils;
import com.appblade.framework.utils.StringUtils;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.content.DialogInterface.OnCancelListener;
import android.os.AsyncTask;
import android.util.Log;

/**
 * Class to check for updates asychronously, will automatically kick off a download in the event that one is available and confirmation prompting is disabled.<br>
 * If the requireAuthCredentials flag is set to true (default is false) then the update check will hard-check for authentication of the activity first. Potentially prompting a login dialog.
 * @author andrewtremblay
 */
public class UpdateTask extends AsyncTask<Void, Void, Void> implements ProgressDelegate {
	protected Activity taskActivity;
	protected ProgressDialog progressDialog;
	public boolean requireAuthCredentials = false; // default anonymous
	public boolean promptDownloadConfirm = true; // default noisy
	
	public UpdateTask(Activity _activity, boolean hardCheckAuthenticate, boolean promptForDownload) {
		this.taskActivity = _activity;
		//this.requireAuthCredentials = hardCheckAuthenticate; 
		this.promptDownloadConfirm = promptForDownload;
	}

	public void showProgress() {
		if ((taskActivity != null) && (progressDialog != null)) {
			taskActivity.runOnUiThread(new Runnable() {
				public void run() {
					progressDialog.show();
				}
			});
		}
	}
	
	public void updateProgress(int value) {
		publishProgress(value);
	}

	public void dismissProgress() {
		if ((taskActivity != null) && (progressDialog != null)) {
			taskActivity.runOnUiThread(new Runnable() {
				public void run() {
					progressDialog.dismiss();
				}
			});
		}
	}
	
	public void setOnCancelListener(OnCancelListener listener) {
		if (progressDialog != null) {
			progressDialog.setOnCancelListener(listener);
		}
	}
	
	protected void publishProgress(Integer... value) {
		if (progressDialog != null) {
			progressDialog.setProgress(value[0].intValue());
		}
	}
	
	@Override
	protected void onPreExecute() {
		//check if we already have an apk downloaded but haven't installed. No need to redownload if we do.
		progressDialog = new ProgressDialog(taskActivity);
		progressDialog.setMessage("Downloading...");
		progressDialog.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
		progressDialog.setProgress(0);
		progressDialog.setCancelable(true);
	}
	
	@Override
	protected Void doInBackground(Void... params) {
		HttpResponse response = UpdatesHelper.getUpdateResponse(this.requireAuthCredentials);
		
		if(response != null){
			Log.v(AppBlade.LogTag, String.format("Response status:%s", response.getStatusLine()));
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
				Log.v(AppBlade.LogTag, String.format("UpdateTask response OK %s", data));
				JSONObject json = new JSONObject(data);
				long timeToLive = json.getLong("ttl")*1000;//update ttl (this comes in as seconds, not millis)
				UpdatesHelper.saveTtl(timeToLive, this.taskActivity);
				//now for the good part
				if(json.has("update")) { 
					JSONObject update = json.getJSONObject("update");
					if(update != null) {
						if(this.promptDownloadConfirm && UpdatesHelper.fileFromJsonNotDownloadedYet(update))
						{
							UpdatesHelper.confirmUpdate(this.taskActivity, update, this);
						}
						else
						{
							UpdatesHelper.processUpdate(this.taskActivity, update, this);
						}
					}
					else
					{
						UpdatesHelper.deleteCurrentFile(this.taskActivity);
					}
				}
				else
				{
					UpdatesHelper.deleteCurrentFile(this.taskActivity);
				}
			}
			catch (IOException ex) { Log.w(AppBlade.LogTag, "IO error when handling update response", ex); }
			catch (JSONException ex) { Log.w(AppBlade.LogTag, "JSON error when handling update response ", ex); }
		}
	}
}
