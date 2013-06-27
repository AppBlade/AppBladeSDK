package com.appblade.framework.servicebinding;

import java.util.LinkedList;
import java.util.Queue;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.util.Log;

import com.appblade.framework.AppBlade;
import com.appblade.framework.AppInfo;
import com.appblade.framework.servicebinding.AppBladeServiceConstants.Keys;
import com.appblade.framework.servicebinding.AppBladeServiceConstants.Messages;

public class AppBladeServiceManager implements ServiceConnection {

	private static final AppBladeServiceManager INSTANCE = new AppBladeServiceManager();
	public static AppBladeServiceManager get() { return INSTANCE; }


	/**
	 * Messenger bound to the service which is used to send it messages.
	 */
	private Messenger appMessenger;
	
	/**
	 * Messenger which listens to messages from the service. This is
	 * sent to the service so that it can reply back to us. This is
	 * bound to a background thread so message processing doesn't block
	 * any other threads
	 */
	private Messenger appReceiver;
	/**
	 * Handler which handles incoming messages on a background thread.
	 * Can also be used to post actions to our background thread.
	 */
	private ClientMessageHandler receiverHandler;
	
	/**
	 * Keeps track of our token and synchronization
	 */
	private TokenLock tokenLock;
	private int serviceVersion;

	/**
	 * Queue of messages to be sent
	 */
	private Queue<Message> messageQueue;
	
	
	private AppBladeServiceManager() {
		tokenLock = new TokenLock();
		messageQueue = new LinkedList<Message>();
		
		// Start a new thread to handle incoming messages so we don't have to
		// block the main thread or anything else
		new Thread("AppBlade Message Receiver") {
			@Override
			public void run() {
				// This will be a looper thread
				Looper.prepare();
				
				// Instantiate a new receiver so messages are processed on this thread
				receiverHandler = new ClientMessageHandler();
				// Create the messenger that handles incoming messages which uses
				// the above handler and therefore this thread.
				appReceiver = new Messenger(receiverHandler);

				// Loop - wait for messages to be handled
				Looper.loop();
			}
		}.start();
	}

	
	
	// ***************
	// *** Binding ***
	// ***************
	
	/**
	 * Binds to the service using the given context
	 * @param context
	 */
	public void bind(Context context) {
		// Bind the service which responds to the the ACTION_BIND to this
		// (ServiceConnection), creating it automatically if necessary
		context.bindService(
				new Intent(AppBladeServiceConstants.ACTION_BIND_APPBLADE_SERVICE),
				this,
				Context.BIND_AUTO_CREATE);
	}

	
	/**
	 * @return True if we are currently bound to the service
	 */
	boolean isBound() {
		return appMessenger != null;
	}
	
	/**
	 * Blocks until the service is bound
	 */
	protected void waitUntilBound() {
		synchronized (this) {
			while (!isBound()) {
				try {
					wait();
				} catch (InterruptedException e) {
					// Just keep waiting
				}
			}
		}
	}
	
	

	// **************
	// *** Tokens ***
	// **************
	
	/**
	 * @return The current token or null if we don't have one - this WILL NOT
	 * block waiting for one.
	 * @see #obtainToken(String, AppInfo)
	 */
	public String getCurrentToken() {
		return tokenLock.getToken();
	}
	
	/**
	 * Blocks until we have a valid token from the service
	 * @return The obtained token
	 * @see #getCurrentToken()
	 */
	public String waitForToken() {
		return tokenLock.waitForToken();
	}
	

	/**
	 * Requests a token from the AppBlade service using the given information.
	 * @param projectSecret
	 * @param appInfo
	 * @see #getCurrentToken()
	 */
	public void obtainToken(String projectSecret, AppInfo appInfo) {
		GetTokenMessage message = new GetTokenMessage(projectSecret, appInfo);
		sendMessageWithDefaultReceiver(message.createMessage());
	}
	
	
	void onTokenReceived(String token) {
		AppBlade.Log_d("Obtained token: " + token);
		tokenLock.onTokenObtained(token);
	}

	
	
	// *****************
	// *** Messaging ***
	// *****************
	
	/**
	 * Sends a message, setting our default message receiver to handle
	 * responses. This will enqueue the message if we are not connected
	 * to the service.
	 * @param message The message to send
	 * @return True if the message was sent, false if it was enqueud.
	 */
	protected boolean sendMessageWithDefaultReceiver(Message message) {
		// Huge race condition/edge case where our background thread
		// isn't finished setup. This should NEVER happen, but just in case
		while (appReceiver == null) {
			try {
				Thread.sleep(25);
			} catch (InterruptedException e) { }
		}
		
		message.replyTo = appReceiver;
		return rawSendMessage(message);
	}
	
	/**
	 * Sends a message without binding our default receiver. If a receiver
	 * is not set, any response may not be handled by the service. This
	 * will enqueue the message if we are not connected to the service or
	 * the send fails.
	 * @param message
	 * @return True if the message was sent, false if it was enqueued.
	 */
	protected boolean rawSendMessage(Message message) {
		synchronized (this) {
			// If we're bound, try sending the message
			if (isBound() && uncheckedSendMessage(message)) {
				return true;
			} else {
				// If either fails, enqueue it to be handled later
				messageQueue.add(message);
				return false;
			}
		}
	}

	/**
	 * Sends a message without binding a receiver or checking if we're bound
	 * @param message
	 * @return True if the message was sent successfully
	 */
	private boolean uncheckedSendMessage(Message message) {
		try {
			appMessenger.send(message);
			return true;
		} catch (RemoteException e) {
			Log.w(getClass().getName(), "Failed to send message!", e);
			return false;
		}
	}

	
	/**
	 * Sends any messages which are currently enqueued if we're bound to the
	 * service. This will abort if any of the messages fail to send.
	 */
	protected void flushMessageQueue() {
		// Make sure we're bound
		if (isBound()) {
			// Loop through all queued messages
			while (messageQueue.peek() != null) {
				Message message = messageQueue.poll();
				if (message != null) {
					// If a send fails, abort
					if (!rawSendMessage(message)) {
						return;
					}
				}
			}
		}
	}
	
	/**
	 * Sends any currently enqueued messages on our background thread
	 */
	protected void flushMessageQueueAsync() {
		if (messageQueue.size() > 0) {
			// Post to our handler so this runs in the background
			receiverHandler.post(flushRunnable);
		}
	}
	
	private Runnable flushRunnable = new Runnable() {
		public void run() {
			flushMessageQueue();
		}
	};
	
	
	

	public void onServiceDisconnected(ComponentName name) {
		synchronized (this) {
			// This really shouldn't happen... AppBlade app crashed?
			// TODO - We may want a fallback - keep the Application Context and rebind?
			Log.wtf(AppBladeServiceManager.class.getName(), "The service to the app was disconnected.");
			appMessenger = null;
		}
	}

	public void onServiceConnected(ComponentName name, IBinder service) {
		synchronized (this) {
			// Create a Messenger to send messages to the service
			appMessenger = new Messenger(service);
			
			// Flush any pending messages
			flushMessageQueueAsync();
			
			// Wake up anyone who may be waiting for this...
			this.notifyAll();
		}
	}


	/**
	 * Class which handles all incoming messages. This needs to be static so it
	 * doesn't leak references. Luckily, the service manager is a singleton
	 * @author Dylan James
	 *
	 */
	private static class ClientMessageHandler extends Handler {		
		@Override
		public void handleMessage(Message msg) {
			AppBladeServiceManager serviceManager = AppBladeServiceManager.get();
			// Switch on the message "what" identifer to determine the type of
			// message
			switch (msg.what) {
			case Messages.ReturnToken:
				Bundle data = msg.getData();
				if (data != null) {					
					String token = data.getString(Keys.Token);
					
					serviceManager.serviceVersion = data.getInt(Keys.ServiceVersion);
					serviceManager.onTokenReceived(token);
				}
				break;
			default:
				super.handleMessage(msg);
			}
		}
	}
}
