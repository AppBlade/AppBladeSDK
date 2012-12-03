package com.appblade.framework.stats;

import android.content.Context;
import android.os.AsyncTask;
import android.widget.Toast;

public class PostSessionTask extends AsyncTask<SessionData, Void, Void>{

	Context context;
	SessionData data;
	Boolean success;
	
	private static final String SUCCESS_MESSAGE = "SessionData Uploaded Successfully!";
	private static final String FAIL_MESSAGE = "SessionData Upload Failed";
	
	public PostSessionTask(Context context) {
		this.context = context;
	}
	
	@Override
	protected Void doInBackground(SessionData... params) {
		data = params[0];
		success = SessionHelper.postSession(data);
		
		return null;
	}
	
	@Override
	protected void onPostExecute(Void result) {
		String toastMessage = FAIL_MESSAGE;
		if (success) {
			toastMessage = SUCCESS_MESSAGE;
			SessionHelper.removeSession(data);
		}
		
		if(context != null){
			Toast.makeText(context, toastMessage, Toast.LENGTH_SHORT).show();
		}
	}

}
