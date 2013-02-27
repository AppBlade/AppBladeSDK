package com.appblade.framework.stats;

import com.appblade.framework.AppBlade;

import android.app.Activity;

/**
 * Activity that will bind itself to the AppBladeSessionLoggingService, for communication with AppBlade.
 * @author andrew.tremblay
 */
public class AppBladeSessionActivity extends Activity {
	
	@Override
	protected void onResume() {
		super.onResume();
		AppBlade.bindToSessionService(this);

	}

	@Override
	protected void onStop() {
		super.onStop();
		AppBlade.unbindFromSessionService(this);
	}
}
