package com.appblade.example;


import android.app.AlertDialog;
import android.app.AlertDialog.Builder;
import android.content.DialogInterface;
import android.content.pm.PackageInfo;
import android.os.Bundle;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.TextView;

import com.appblade.framework.stats.AppBladeSessionActivity;
import com.appblade.framework.authenticate.KillSwitch;
import com.appblade.framework.authenticate.RemoteAuthHelper;
import com.appblade.framework.AppBlade;

public class MainActivity extends AppBladeSessionActivity {
	
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
//		AppBlade.authorize(this);

		//AppBlade.authorize(this); //moved to a button call, but it would usually be here
		//AppBlade.checkForUpdates(MainActivity.this); //moved to a button call, but it would usually be here
		
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
		
		//Update Check 
		btnCheckUpdatePrompt.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				AppBlade.checkForUpdates(MainActivity.this);
			}
		});
		btnCheckUpdateSilent.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				AppBlade.checkForUpdates(MainActivity.this, false);
			}
		});
		

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

	



}