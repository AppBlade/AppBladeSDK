package com.appblade.framework.servicebinding;

import android.os.Handler;
import android.os.Message;
import android.os.Messenger;


/**
 * {@link IAppBladeMessage} implementation which sends one message and handles
 * a response message or messages.
 * 
 * @author Dylan James
 *
 */
public class TwoWayMessage implements IAppBladeMessage {
	
	/**
	 * Class which provides a way to handle response messages.
	 * 
	 * @author Dylan James
	 */
	public static class ResponseHandler {		
		private Messenger messenger;
		/**
		 * @return The {@link Messenger} to use for responses.
		 */
		public Messenger getMessenger() { return messenger; }
				
		/**
		 * Creates a {@link ResponseHandler} which will send any response
		 * messages to the given {@link Handler}
		 * @param handler The {@link Handler} to send responses to
		 */
		public ResponseHandler(Handler handler) {
			this(new Messenger(handler));
		}
		
		/**
		 * Creates a {@link ResponseHandler} which will send any response
		 * messages to the given {@link Messenger}.
		 * @param messenger The {@link Messenger} to send responses to 
		 */
		public ResponseHandler(Messenger messenger) {
			this.messenger = messenger;
		}
	}

	
	/**
	 * The message we are going to send
	 */
	IAppBladeMessage outgoingMessage;
	
	/**
	 * The object responsible for providing a way to handle the response
	 */
	ResponseHandler responseHandler;
	
	/**
	 * Constructor which sets up an outgoing message, but no response handler.
	 * IF YOU USE THIS you should almost DEFINITELY set {@link #responseHandler}
	 * manually, or you WILL NOT receive responses.
	 * 
	 * @param message The {@link IAppBladeMessage} to send
	 */
	protected TwoWayMessage(IAppBladeMessage message) { 
		this.outgoingMessage = message;
	}
	
	/**
	 * Creates a {@link TwoWayMessage} which sends the given message and
	 * sends responses to the given handler.
	 * @param message The {@link IAppBladeMessage} to send
	 * @param handler The {@link ResponseHandler} to send responses to
	 */
	public TwoWayMessage(IAppBladeMessage message, ResponseHandler handler) {
		outgoingMessage = message;
		responseHandler = handler;
	}
	
	
	public Message getMessage() {
		// Send our outgoing message
		Message message = outgoingMessage.getMessage();
		
		// Set the reply field to be whatever our response handler returns as the messenger
		if (responseHandler != null) {
			message.replyTo = responseHandler.getMessenger();
		}
		
		return message;
	}
	
}
