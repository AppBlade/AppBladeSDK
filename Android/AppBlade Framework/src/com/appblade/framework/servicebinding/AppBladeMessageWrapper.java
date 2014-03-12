package com.appblade.framework.servicebinding;

import android.os.Message;

/**
 * Simple wrapper class which wraps an Android {@link Message} as an
 * {@link IAppBladeMessage}.
 * 
 * @author Dylan James
 *
 */
public class AppBladeMessageWrapper implements IAppBladeMessage {

	private Message message;
	
	public AppBladeMessageWrapper(Message message) {
		this.message = message;
	}
	
	public Message getMessage() {
		return message;
	}

}
