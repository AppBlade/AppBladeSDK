package com.appblade.example;

import java.io.IOException;

import org.apache.http.HttpResponse;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.app.AlertDialog.Builder;
import android.content.DialogInterface;
import android.content.pm.PackageInfo;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.TextView;

import com.appblade.framework.stats.AppBladeSessionActivity;
import com.appblade.framework.updates.UpdatesHelper;
import com.appblade.framework.authenticate.KillSwitch;
import com.appblade.framework.authenticate.RemoteAuthHelper;
import com.appblade.framework.utils.HttpUtils;
import com.appblade.framework.utils.StringUtils;
import com.appblade.framework.AppBlade;

public class MainActivity extends AppBladeSessionActivity {

	static View updateSpinner = null;
	
	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);
		
		String versionString = "Version: " + getAppVersion();
		TextView versionTextView = (TextView)findViewById(R.id.versionText);
		versionTextView.setText(versionString);
		initControls();
	}

	public void onResume() {
		super.onResume();
		//AppBlade.authorize(this);
		AppBlade.setCustomParameter(getApplicationContext(), "AppState", "Resumed");
		
	}

	public void onPause() {
		super.onPause();
	}

	private void initControls() {
		View btnDivideByZero = findViewById(R.id.btnDivideByZero);
		View btnDivideByZeroUncaught = findViewById(R.id.btnDivideByZeroUncaught);

		View btnFeedback = findViewById(R.id.btnFeedback);
		View btnFeedbackNoScreenshot = findViewById(R.id.btnFeedbackNoImage);

		View btnStartSession = findViewById(R.id.btnSessionStart);
		View btnEndSession = findViewById(R.id.btnSessionEnd);

		View btnClearAuthData = findViewById(R.id.btnClearAuthData);
		
		View btnCheckUpdatePrompt = findViewById(R.id.btnCheckUpdateLoud);
		View btnCheckUpdateSilent = findViewById(R.id.btnCheckUpdateQuiet);
		updateSpinner = findViewById(R.id.progressSpinnerUpdateCheck);
		//Exception Reporting
		btnDivideByZero.setOnClickListener(new OnClickListener() {
			@SuppressWarnings("unused")
			public void onClick(View v) {
				try {
					int divideByZero = 1 / 0;
				} catch (ArithmeticException ex) {
					AppBlade.notify(ex);
				} catch (Exception ex) {
					// General exceptions not reported
				}
			}
		});
		btnDivideByZeroUncaught.setOnClickListener(new OnClickListener() {
			@SuppressWarnings("unused")
			public void onClick(View v) {
				int divideByZero = 1 / 0;
			}
		});

		//Feedback Counting
		btnFeedback.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				AppBlade.doFeedbackWithScreenshot(MainActivity.this, MainActivity.this);
			}
		});
		btnFeedbackNoScreenshot.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				AppBlade.doFeedback(MainActivity.this);
			}
		});
		
		//Session Counting
		btnStartSession.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				AppBlade.startSession(MainActivity.this);
			}
		});
		btnEndSession.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				AppBlade.endSession(MainActivity.this);
			}
		});
		
		//Authentication
		btnClearAuthData.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				RemoteAuthHelper.clear(MainActivity.this);
				KillSwitch.clear(MainActivity.this);
				AlertDialog.Builder builder = new Builder(MainActivity.this);
				builder.setMessage("Auth data cleared");
				builder.setPositiveButton("OK",
						new DialogInterface.OnClickListener() {
							public void onClick(DialogInterface dialog,
									int which) {
								AppBlade.authorize(MainActivity.this, false);
							}
						});
				builder.show();
			}
		});
		btnClearAuthData.setVisibility(View.GONE);
		
		//Update Check 
		btnCheckUpdatePrompt.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				//AppBlade.checkForUpdates(MainActivity.this);
				//^ this would be the only call we would need usually, but this is the example app, let's get FANCY
				checkUpdateWithSpinner(true);
			}
		});
		btnCheckUpdateSilent.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				//AppBlade.checkForUpdates(MainActivity.this, false);
				//^ this would be the only call we would need usually, but this is the example app, let's get FANCY
				checkUpdateWithSpinner(false);
			}
		});
		
		btnCheckUpdatePrompt.setVisibility(View.GONE);
		btnCheckUpdateSilent.setVisibility(View.GONE);

	}

	
	
	
	
	
	
	
	@Override
	public boolean onTouchEvent(MotionEvent event) {
		int action = event.getAction();
		switch (action & MotionEvent.ACTION_MASK) {
		case MotionEvent.ACTION_POINTER_DOWN:
			if (event.getPointerCount() == 3) {
				doFeedbackWithScreenshotAndSetCustomParams();
				return true;
			}
		}

		return super.onTouchEvent(event);
	}

	private void doFeedbackWithScreenshotAndSetCustomParams() {
		AppBlade.setCustomParameter(getApplicationContext(), "AppState",
				"Did A Feedback From Touch Event");

		AppBlade.doFeedbackWithScreenshot(this, this);
	}
	
	
	private String getAppVersion() {
		String toRet = "Not Found";
		PackageInfo info = AppBlade.getPackageInfo();
		if(info != null)
		{
			toRet = info.versionName;
		}
		return toRet;
	}

	
	protected void checkUpdateWithSpinner(boolean promptDownloadConfirm) {
		new CustomUpdateTask(this, promptDownloadConfirm).execute(); //exactly the same code with the exception of the new spinner logic
	}


	static class CustomUpdateTask extends AsyncTask<Void, Void, Void> {
		Activity activity;
		ProgressDialog progress;
		public boolean promptDownloadConfirm = true; // default noisy
		
		
		public CustomUpdateTask(Activity _activity, boolean promptForDownload) {
			this.activity = _activity;
			this.promptDownloadConfirm = promptForDownload;
		}


		
		@Override
		protected void onPreExecute() {
			//check if we already have an apk downloaded but haven't installed. No need to redownload if we do.
			updateSpinner.setVisibility(View.VISIBLE);
		}
		
		@Override
		protected Void doInBackground(Void... params) {
			HttpResponse response = UpdatesHelper.getUpdateResponse(false);
			if(response != null){
				Log.d(AppBlade.LogTag, String.format("Response status:%s", response.getStatusLine()));
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
					Log.d(AppBlade.LogTag, String.format("UpdateTask response OK %s", data));
					JSONObject json = new JSONObject(data);
					int timeToLive = json.getInt("ttl");
					if(json.has("update")) {
						JSONObject update = json.getJSONObject("update");
						if(update != null) {
							if(this.promptDownloadConfirm)
							{
								UpdatesHelper.confirmUpdate(this.activity, update);
							}
							else
							{
								UpdatesHelper.processUpdate(this.activity, update);								
							}
						}
					}
					this.activity.runOnUiThread(new Runnable(){
						public void run() {
							updateSpinner.setVisibility(View.INVISIBLE);
						}
					});
				}
				catch (IOException ex) { ex.printStackTrace(); }
				catch (JSONException ex) { ex.printStackTrace(); }
			}
		}
	}


}