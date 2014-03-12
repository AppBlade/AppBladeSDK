package com.appblade.framework.servicebinding;

import android.os.Message;

/**
 * Interface for an AppBlade message. 
 * 
 * @author Dylan James
 */
public interface IAppBladeMessage {
	/**
	 * @return The {@link Message} to be sent
	 */
	public Message getMessage();
}
