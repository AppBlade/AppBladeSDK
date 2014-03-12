package com.appblade.framework.feedback;

import com.appblade.framework.AppBlade;
import com.appblade.framework.customparams.CustomParamData;
import com.appblade.framework.customparams.CustomParamDataHelper;

import android.app.ProgressDialog;
import android.content.Context;
import android.os.AsyncTask;

import android.widget.Toast;

/**
 * Class for asynchronously posting feedback to AppBlade. <br>
 * Running exec will post all current stored custom params. 
 * @see #FeedbackHelper.postFeedbackWithCustomParams(FeedbackData data, CustomParamData paramData)
 * @see #CustomParamDataHelper.getCurrentCustomParams()
 * @author andrew.tremblay@raizlabs
 */
public class PostFeedbackTask extends AsyncTask<FeedbackData, Void, Boolean>{

	Context context;
	ProgressDialog progress;
	
	Boolean success;
	
	private static final String SUCCESS_MESSAGE = "Feedback Uploaded Successfully!";
	private static final String FAIL_MESSAGE = "Feedback Upload Failed";
	
	public PostFeedbackTask(Context context) {
		this.context = context;
	}
	
	@Override
	protected Boolean doInBackground(FeedbackData... params) {
		if(params.length == 1){
			FeedbackData data = params[0];
			CustomParamData paramData = CustomParamDataHelper.getCurrentCustomParams();
			AppBlade.Log( "customParams " + paramData.toString());
			success = FeedbackHelper.postFeedbackWithCustomParams(data, paramData);
			
			if(success){
				data.clearData();
			}
		}
		return success;
	}
	
	@Override
	protected void onPostExecute(Boolean result) {
		String toastMessage = FAIL_MESSAGE;
		if (success) {
			toastMessage = SUCCESS_MESSAGE;
		}

		if(context != null && AppBlade.makeToast){
			Toast.makeText(context, toastMessage, Toast.LENGTH_SHORT).show();
		}
	}

}
