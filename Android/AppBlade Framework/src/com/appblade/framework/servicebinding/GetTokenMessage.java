package com.appblade.framework.servicebinding;

import android.os.Message;

import com.appblade.framework.AppInfo;
import com.appblade.framework.servicebinding.AppBladeServiceConstants.Messages;

/**
 * Message implementation which requests a token from the service.
 * 
 * @author Dylan James
 */
public class GetTokenMessage implements IAppBladeMessage {

	TokenRequest request;
	
	/**
	 * Creates a {@link GetTokenMessage} based off the given project
	 * secret and app info.
	 * @param projectSecret The project secret
	 * @param info The info about the app making the request
	 */
	public GetTokenMessage(String projectSecret, AppInfo info) {
		// Create the token request object from this info
		request = new TokenRequest(projectSecret, info);
	}
	
	public Message getMessage() {
		Message message = Message.obtain();
		message.what = Messages.GetToken;
		// Set the request as our data which will send it all to the
		// service
		message.setData(TokenRequest.toBundle(request));
		
		return message;
	}
}
