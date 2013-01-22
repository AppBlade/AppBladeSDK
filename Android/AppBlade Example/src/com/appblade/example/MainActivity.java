package com.appblade.example;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.AlertDialog.Builder;
import android.content.DialogInterface;
import android.os.Bundle;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnClickListener;

import com.appblade.framework.AppBlade;
import com.appblade.framework.authenticate.KillSwitch;
import com.appblade.framework.authenticate.RemoteAuthHelper;

public class MainActivity extends Activity {

	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);

		initControls();
	}

	public void onResume() {
		super.onResume();
		AppBlade.startSession(this.getApplicationContext());
		AppBlade.authorize(this);

		AppBlade.setCustomParameter(getApplicationContext(), "AppState",
				"Resumed");
	}

	public void onPause() {
		super.onPause();
		AppBlade.endSession(getApplicationContext());
	}

	private void initControls() {
		View btnDivideByZero = findViewById(R.id.btnDivideByZero);
		View btnClearAuthData = findViewById(R.id.btnClearAuthData);
		View btnFeedback = findViewById(R.id.btnFeedback);

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

		btnFeedback.setOnClickListener(new OnClickListener() {
			public void onClick(View v) {
				MainActivity.this.doFeedbackWithScreenshot();
			}
		});
	}

	@Override
	public boolean onTouchEvent(MotionEvent event) {
		int action = event.getAction();
		switch (action & MotionEvent.ACTION_MASK) {
		case MotionEvent.ACTION_POINTER_DOWN:
			if (event.getPointerCount() == 3) {
				doFeedbackWithScreenshot();
				return true;
			}
		}

		return super.onTouchEvent(event);
	}

	private void doFeedbackWithScreenshot() {
		AppBlade.setCustomParameter(getApplicationContext(), "AppState",
				"Did A Feedback");

		AppBlade.doFeedbackWithScreenshot(this, this);
	}

}