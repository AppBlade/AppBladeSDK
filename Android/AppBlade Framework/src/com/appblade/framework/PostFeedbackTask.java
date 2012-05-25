package com.appblade.framework;

import android.app.ProgressDialog;
import android.content.Context;
import android.os.AsyncTask;

public class PostFeedbackTask extends AsyncTask<FeedbackData, Void, Void>{

	Context context;
	ProgressDialog progress;
	
	public PostFeedbackTask(Context context) {
		this.context = context;
	}
	
	@Override
	protected void onPreExecute() {
		progress = ProgressDialog.show(context, null, "Sending Feedback...");
	}
	
	@Override
	protected Void doInBackground(FeedbackData... params) {
		FeedbackData data = params[0];
		AppBlade.postFeedback(data);
		
		return null;
	}
	
	@Override
	protected void onPostExecute(Void result) {
		if (progress != null && progress.isShowing())
			progress.dismiss();
	}

}
