package com.appblade.framework.crashreporting;

import com.appblade.framework.AppBlade;

import android.app.ProgressDialog;
import android.content.Context;
import android.os.AsyncTask;
import android.widget.Toast;

public class PostCrashReportTask extends AsyncTask<CrashReportData, Void, Void>{

	Context context;
	ProgressDialog progress;
	
	Boolean success;
	
	private static final String SUCCESS_MESSAGE = "Crash Uploaded Successfully!";
	private static final String FAIL_MESSAGE = "Crash Upload Failed";
	
	public PostCrashReportTask(Context context) {
		this.context = context;
	}
	
	@Override
	protected Void doInBackground(CrashReportData... params) {
		if(params.length == 1){
			CrashReportData data = params[0];
			success = CrashReportHelper.postCrashes(data);
		}
		return null;
	}
	
	@Override
	protected void onPostExecute(Void result) {
		String toastMessage = FAIL_MESSAGE;
		if (success) {
			toastMessage = SUCCESS_MESSAGE;
		}
		
		if(this.context != null && AppBlade.makeToast){
			Toast.makeText(this.context, toastMessage, Toast.LENGTH_SHORT).show();
		}
	}
	
}


