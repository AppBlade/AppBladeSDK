package com.appblade.framework.feedback;

import android.app.ProgressDialog;
import android.content.Context;
import android.os.AsyncTask;
import android.widget.Toast;

public class PostFeedbackTask extends AsyncTask<FeedbackData, Void, Void>{

	Context context;
	ProgressDialog progress;
	
	Boolean success;
	
	private static final String SUCCESS_MESSAGE = "Feedback Uploaded Successfully!";
	private static final String FAIL_MESSAGE = "Feedback Upload Failed";
	
	public PostFeedbackTask(Context context) {
		this.context = context;
	}
	
	@Override
	protected Void doInBackground(FeedbackData... params) {
		FeedbackData data = params[0];
		success = FeedbackHelper.postFeedback(data);
		return null;
	}
	
	@Override
	protected void onPostExecute(Void result) {
		String toastMessage = FAIL_MESSAGE;
		if (success) {
			toastMessage = SUCCESS_MESSAGE;
		}

		if(context != null){
			Toast.makeText(context, toastMessage, Toast.LENGTH_SHORT).show();
		}
	}

}
