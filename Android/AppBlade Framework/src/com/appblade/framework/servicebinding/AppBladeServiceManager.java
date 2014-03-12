package com.appblade.framework.servicebinding;

import java.util.HashSet;
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
	 * Interface for a listener which listens to changes in the service
	 * state.
	 */
	public interface ServiceStateListener {
		/**
		 * Called when we temporarily lost the connection to the service but
		 * have now successfully reconnected. You may want to resend messages
		 * because we don't know when or why the service stopped.
		 */
		public void onServiceReconnected();
		/**
		 * Called when we lost the connection to the service and were unable
		 * to re-establish the connection.
		 */
		public void onServiceLost();
		/**
		 * Called when we determine that the service is unavailable.
		 */
		public void onServiceUnavailable();
	}
	
	
	/**
	 * Manager which keeps track of {@link ServiceStateListener}s
	 */
	private ServiceStateManager stateManager;

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
	 * Retrieves the {@link Handler} that is bound to our background receiver
	 * thread. You can use this to {@link Handler#post(Runnable)} actions to
	 * this background thread.
	 * 
	 * Note that since the action is run on the receiver thread, blocking it
	 * will block messages from being received, so you should only perform
	 * relatively quick actions. The main purpose is to allow other message
	 * handlers to bind to this thread as well so that they wait here instead
	 * of needing a separate Looper thread.
	 * 
	 * @return The {@link Handler} bound to the receiver thread.
	 */
	public Handler getReceiverThreadHandler() {
		return receiverHandler;
	}
	
	/**
	 * Keeps track of our token and synchronization
	 */
	private TokenLock tokenLock;
	private int serviceVersion;
	
	private boolean serviceUnavailable;
	/**
	 * @return True if we tried to bind to the service and failed
	 */
	public boolean isServiceUnavailable() { return serviceUnavailable; }
	
	/**
	 * Context we keep to attempt service reconnections.
	 * This NEEDS to be an application context
	 */
	private Context context;

	/**
	 * Queue of messages to be sent
	 */
	private Queue<Message> messageQueue;
	
	
	private AppBladeServiceManager() {
		tokenLock = new TokenLock();
		messageQueue = new LinkedList<Message>();
		stateManager = new ServiceStateManager();
		
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
	 * Tries to bind to the service using the given context
	 * @param context
	 * @return True if the service was bound, false if it was not found
	 * (not installed) or an exception was thrown.
	 */
	public boolean bind(Context context) {
		boolean success = innerBind(context);
		if (!success) {
			// The service is unavailable
			stateManager.onServiceUnavailable();
		}
		
		return success;
	}
	
	/**
	 * Attempts to bind using the given context. Does not handle state changes.
	 * @param context
	 * @return True if the service was bound, false if it was not found
	 * (not installed) or an exception was thrown.
	 */
	private boolean innerBind(Context context) {
		// Make sure we do everything through the application context
		context = context.getApplicationContext();
		// Store the application context for later rebind attempts
		this.context = context;
		try {
			// Bind the service which responds to the the ACTION_BIND to this
			// (ServiceConnection), creating it automatically if necessary
			boolean bound =  context.bindService(
					new Intent(AppBladeServiceConstants.ACTION_BIND_APPBLADE_SERVICE),
					this,
					Context.BIND_AUTO_CREATE);
			serviceUnavailable = !bound;
			return bound;
		} catch (Exception ex) {
			// If anything goes wrong, we failed. Possibly a security exception
			AppBlade.Log_w("Error connecting to the AppBlade Service", ex);
			serviceUnavailable = true;
			return false;
		}
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
	
	

	// ************************
	// *** State Management ***
	// ************************

	/**
	 * Subscribes the given {@link ServiceStateListener} to changes in the
	 * services state
	 * @param listener
	 */
	public void addStateListener(ServiceStateListener listener) {
		stateManager.addListener(listener);
	}
	
	/**
	 * Unsubscribes the given {@link ServiceStateListener} from changes
	 * in the services state
	 * @param listener
	 */
	public void removeStateListener(ServiceStateListener listener) {
		stateManager.removeListener(listener);
	}
	
	/**
	 * Called when the service is reconnected
	 */
	protected void onServiceReconnected() {
		stateManager.onServiceReconnected();
	}
	
	/**
	 * Called when the service is lost
	 */
	protected void onServiceLost() {
		stateManager.onServiceLost();
	}
	
	public void onServiceDisconnected(ComponentName name) {
		synchronized (this) {
			appMessenger = null;
			
			boolean reconnected = false;
			// If we have a context, attempt to rebind
			if (context != null) {
				// Use innerBind since we're handling state changes
				reconnected = innerBind(context);
			}
			
			// If we managed to reconnect, notify listeners
			if (reconnected) {
				onServiceReconnected();
			} else {
				// Otherwise, notify listeners that we lost the service
				AppBlade.Log_w("The connection to the AppBlade Service was severed and could not be recreated", null);
				onServiceLost();
			}
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
		sendMessage(message);
	}
	
	
	void onTokenReceived(String token) {
		AppBlade.Log_d("Obtained token: " + token);
		tokenLock.onTokenObtained(token);
	}

	
	
	// *****************
	// *** Messaging ***
	// *****************
	
	/**
	 * Cancels the given {@link Message} if it is queued, returning
	 * true if it is removed. If it was only sent once and this returns
	 * true, it is guaranteed that it was never sent.
	 * @param message
	 * @return True if the message was removed from the queue
	 */
	public boolean cancelMessage(Message message) {
		return messageQueue.remove(message);
	}
	
	/**
	 * Sends a message, setting the default message receiver to handle
	 * responses if the {@link Message#replyTo} field is not set. This
	 * will enqueue the message if we are not connected to the service.
	 * 
	 * @param message The message to send
	 * @return True if the message was sent, false if it was enqueued.
	 */
	public boolean sendMessage(IAppBladeMessage message) {
		return sendMessage(message.getMessage());
	}
	
	/**
	 * Sends a message, setting the default message receiver to handle
	 * responses if the {@link Message#replyTo} field is not set. This
	 * will enqueue the message if we are not connected to the service.
	 * 
	 * @param message The message to send
	 * @return True if the message was sent, false if it was enqueued.
	 */
	public boolean sendMessage(Message message) {
		if (message.replyTo == null) {
			return sendMessageWithDefaultReceiver(message);
		}
		return rawSendMessage(message);
	}
	
	/**
	 * Sends a message, setting our default message receiver to handle
	 * responses. This will enqueue the message if we are not connected
	 * to the service.
	 * @param message The message to send
	 * @return True if the message was sent, false if it was enqueued.
	 */
	protected boolean sendMessageWithDefaultReceiver(IAppBladeMessage message) {
		return sendMessageWithDefaultReceiver(message.getMessage());
	}
	
	/**
	 * Sends a message, setting our default message receiver to handle
	 * responses. This will enqueue the message if we are not connected
	 * to the service.
	 * @param message The message to send
	 * @return True if the message was sent, false if it was enqueued.
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
	

	/**
	 * Class which handles all incoming messages. This needs to be static so it
	 * doesn't leak references. Luckily, the service manager is a singleton
	 * @author Dylan James
	 *
	 */
	private static class ClientMessageHandler extends AppBladeMessageHandler {		
		@Override
		public void onMessageReceived(Message msg) {
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
	
	
	/**
	 * Class which handles service state changes and manages listeners and
	 * notifies them of changes.
	 */
	private static class ServiceStateManager {
		/**
		 * Current list of listeners
		 */
		private LinkedList<ServiceStateListener> listeners;
		
		/**
		 * Temporary lists used during transactions
		 * See {@link #performAction(ListenerAction)} for details
		 */
		private HashSet<ServiceStateListener> toAdd, toRemove;
		
		/**
		 * Flag which idnicates we're currently sending notifications
		 */
		private boolean isNotifying;
		
		private interface ListenerAction {
			void performAction(ServiceStateListener listener);
			
			static final ListenerAction Reconnected = new ListenerAction() {
				public void performAction(ServiceStateListener listener) {
					listener.onServiceReconnected();
				}
			};
			
			static final ListenerAction Lost = new ListenerAction() {
				public void performAction(ServiceStateListener listener) {
					listener.onServiceLost();
				}
			};
			
			static final ListenerAction Unavailable = new ListenerAction() {
				public void performAction(ServiceStateListener listener) {
					listener.onServiceUnavailable();
				}
			};
		}
		
		public ServiceStateManager() {
			listeners = new LinkedList<ServiceStateListener>();
			toAdd = new HashSet<ServiceStateListener>();
			toRemove = new HashSet<ServiceStateListener>();
			
			isNotifying = false;
		}
		
		/**
		 * Subscribes the given listener to updates
		 * @param listener
		 */
		public void addListener(ServiceStateListener listener) {
			synchronized (this) {
				// If we're notifying, add it to the temp list instead
				// See performAction for details
				if (isNotifying) {
					toAdd.add(listener);
				} else {
					// Otherwise just add it
					listeners.add(listener);
				}
			}
		}
		
		/**
		 * Unsubscribes the given listener from updates
		 * @param listener
		 */
		public void removeListener(ServiceStateListener listener) {
			synchronized (this) {
				// If we're notifying, add it to the temp list instead
				// See performAction for details
				if (isNotifying) {
					toRemove.add(listener);
				} else {
					// Otherwise just remove it
					listeners.remove(listener);
				}
			}
		}
		
		/**
		 * Call this to notify listeners that the service was reconnected
		 */
		public void onServiceReconnected() {
			performAction(ListenerAction.Reconnected);
		}
		
		/**
		 * Call this to notify listeners that the service was lost
		 */
		public void onServiceLost() {
			performAction(ListenerAction.Lost);
		}
		
		public void onServiceUnavailable() {
			performAction(ListenerAction.Unavailable);
		}
		
		private void performAction(ListenerAction action) {
			synchronized (this) {
				// Flag that we're doing a notify
				isNotifying = true;
				
				// Notify all listeners
				// Since we're using an iterator, we cannot modify
				// this list. As such, during this loop, all functions
				// should push to the toAdd and toRemove list. These
				// lists will be processed once the loop is completed
				for (ServiceStateListener listener : listeners) {
					// If the temp list indicates that we're going
					// to remove this listener, don't bother telling it
					if (!toRemove.contains(listener)) {
						action.performAction(listener);
					}
				}
				
				isNotifying = false;
				
				// Loop through both lists and perform their actions
				for (ServiceStateListener listener : toAdd) {
					addListener(listener);
				}
				
				for (ServiceStateListener listener : toRemove) {
					removeListener(listener);
				}
				
				// Clear the temp lists since we've handled them
				toAdd.clear();
				toRemove.clear();
			}
		}
	}
}
