package com.appblade.framework.servicebinding;

import android.os.Message;

import com.appblade.framework.AppInfo;
import com.appblade.framework.servicebinding.AppBladeServiceConstants.Messages;

public class GetTokenMessage implements IAppBladeMessage {

	TokenRequest request;
	
	public GetTokenMessage(String projectSecret, AppInfo info) {
		request = new TokenRequest(projectSecret, info);
	}
	
	public Message createMessage() {
		Message message = Message.obtain();
		message.what = Messages.GetToken;
		message.setData(TokenRequest.toBundle(request));
		return message;
	}
}
