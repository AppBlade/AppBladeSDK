package com.appblade.framework.updates;

import android.app.Activity;
import android.app.ProgressDialog;

public class DownloadProgressDialog extends ProgressDialog {
	public DownloadProgressDialog(Activity activity) {
		super(activity);
		setMessage("Downloading...");
		setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
		setProgress(0);
		setCancelable(true);
	}
	
	public interface DownloadProgressDelegate {
		public void showProgress();
		public void updateProgress(int value);
		public void dismissProgress();
		public void setOnCancelListener(OnCancelListener listener);
	}	
}
