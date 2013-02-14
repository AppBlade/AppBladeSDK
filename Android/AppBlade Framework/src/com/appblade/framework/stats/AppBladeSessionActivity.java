package com.appblade.framework.stats;

import com.appblade.framework.AppBlade;

import android.app.Activity;

/**
 * Activity that will bind itself to the AppBladeSessionLoggingService, for communication with AppBlade.
 * @author andrew.tremblay
 */
public class AppBladeSessionActivity extends Activity {
	public AppBladeSessionServiceConnection appbladeSessionServiceConnection;
	
	
	@Override
	protected void onResume() {
		super.onResume();
		AppBlade.bindToSessionService(AppBladeSessionActivity.this);
	}

	@Override
	protected void onPause() {
		super.onPause();
		AppBlade.unbindFromSessionService(AppBladeSessionActivity.this);
	}
}
