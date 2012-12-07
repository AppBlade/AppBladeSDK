package com.appblade.framework.stats;

import java.util.List;

import android.content.Context;
import android.os.AsyncTask;
import android.widget.Toast;

public class PostSessionTask extends AsyncTask<List<SessionData>, Void, Void>{

	Context context;
	List<SessionData> data;
	Boolean success;
	
	private static final String SUCCESS_MESSAGE = "SessionData Uploaded Successfully!";
	private static final String FAIL_MESSAGE = "SessionData Upload Failed";
	
	public PostSessionTask(Context context) {
		this.context = context;
	}
	
	@Override
	protected Void doInBackground(List<SessionData>... params) {
		data = params[0];
		success = SessionHelper.postSessions(data);
		return null;
	}
	
	@Override
	protected void onPostExecute(Void result) {
		String toastMessage = FAIL_MESSAGE;
		if (success) {
			toastMessage = SUCCESS_MESSAGE;
			if(context != null){
				SessionData lastSession = data.get(data.size()-1);
				SessionHelper.removeSessionsEndedBefore(context, lastSession.ended);
			}
		}
		
		if(context != null){
			Toast.makeText(context, toastMessage, Toast.LENGTH_SHORT).show();
		}
	}

}
