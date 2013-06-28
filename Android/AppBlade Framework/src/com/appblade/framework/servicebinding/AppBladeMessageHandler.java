package com.appblade.framework.servicebinding;

import android.os.Handler;
import android.os.Message;

/**
 * Base class for AppBlade {@link Handler}s. This may provide message validation
 * and forwards any appropriate information to the {@link AppBladeServiceManager}.
 * All Handlers should extend this class so we don't miss anything.
 * 
 * Implementing classes should use {@link #onMessageReceived(Message)} instead of
 * the standard {@link #handleMessage(Message)}
 * 
 * @author Dylan James
 *
 */
public abstract class AppBladeMessageHandler extends Handler {

	AppBladeServiceManager serviceManager;
	
	public AppBladeMessageHandler() {
		serviceManager = AppBladeServiceManager.get();
	}
	
	/**
	 * Implementing classes should override {@link #onMessageReceived(Message)}
	 * instead
	 */
	public final void handleMessage(Message msg) {
		// STUB - Not doing anything now, but good to have the option for later.
		// Better to have everyone inherit from here now in case we ever need to
		// catch certain messages or perform validity checks.
		onMessageReceived(msg);
	}
	
	/**
	 * Called when a valid {@link Message} is received.
	 * @param msg The received {@link Message}
	 */
	protected abstract void onMessageReceived(Message msg);
}
