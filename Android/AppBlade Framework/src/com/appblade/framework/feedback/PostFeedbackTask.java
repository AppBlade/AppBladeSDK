package com.appblade.framework.feedback;

import com.appblade.framework.AppBlade;
import com.appblade.framework.customparams.CustomParamData;
import com.appblade.framework.customparams.CustomParamDataHelper;

import android.app.ProgressDialog;
import android.content.Context;
import android.os.AsyncTask;
import android.util.Log;
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
		if(params.length == 1){
			FeedbackData data = params[0];
			CustomParamData paramData = CustomParamDataHelper.getCurrentCustomParams();
			Log.d(AppBlade.LogTag, "customParams " + paramData.toString());
			success = FeedbackHelper.postFeedbackWithCustomParams(data, paramData);
		}
		return null;
	}
	
	@Override
	protected void onPostExecute(Void result) {
		String toastMessage = FAIL_MESSAGE;
		if (success) {
			toastMessage = SUCCESS_MESSAGE;
		}

		if(context != null && AppBlade.makeToast){
			Toast.makeText(context, toastMessage, Toast.LENGTH_SHORT).show();
		}
	}

}
