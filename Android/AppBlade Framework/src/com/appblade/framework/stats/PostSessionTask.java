package com.appblade.framework.stats;

import java.util.List;

import com.appblade.framework.AppBlade;

import android.content.Context;
import android.os.AsyncTask;
import android.util.Log;
import android.widget.Toast;

/**
 * Task to post sessions asynchronously.
 * On exec(sessions) will post all sessions to AppBlade.
 * @see SessionHelper.postSessions(List<SessionData>)
 * @author andrew.tremblay@raizlabs
 */
public class PostSessionTask extends AsyncTask<List<SessionData>, Void, Void>{

	Context context;
	List<SessionData> data;
	Boolean success;
	int responseCode;

	private static final String SUCCESS_MESSAGE = "SessionData Uploaded Successfully!";
	private static final String FAIL_MESSAGE = "SessionData Upload Failed";
	
	public PostSessionTask(Context context) {
		this.context = context;
	}
	
	@Override
	protected Void doInBackground(List<SessionData>... params) {
		if(params.length == 1){
			data = params[0];
			if(data.size() != 0){
				responseCode = SessionHelper.postSessions(data);
			}else{
				responseCode = 0;
			}
			success = (responseCode/100) == 2;
		}
		return null;
	}
	
	@Override
	protected void onPostExecute(Void result) {
		String toastMessage = FAIL_MESSAGE;
		if (success) {
			toastMessage = SUCCESS_MESSAGE;
			if(context != null){
				Log.d(AppBlade.LogTag, "session posting success. remove successful sessions");
				if(data.size() > 0){
				SessionData lastSession = data.get(data.size()-1);
				SessionHelper.removeSessionsEndedBefore(context, lastSession.ended);
				}
			}
		}else{
			Log.d(AppBlade.LogTag, "error posting session. response Code " + responseCode);					
			if(responseCode == 408){
				Log.d(AppBlade.LogTag, "Timeout, store for later");					
			}else if(responseCode == 0){
				Log.d(AppBlade.LogTag, "no data to send, store for later");					
			}else{
				Log.d(AppBlade.LogTag, "Bad request, blow away the data");					
				if(data.size() > 0){
				SessionData lastSession = data.get(data.size()-1);
				SessionHelper.removeSessionsEndedBefore(context, lastSession.ended);
				}
			}
		}

		
		if(context != null && AppBlade.makeToast){
			Toast.makeText(context, toastMessage, Toast.LENGTH_SHORT).show();
		}
	}

}
