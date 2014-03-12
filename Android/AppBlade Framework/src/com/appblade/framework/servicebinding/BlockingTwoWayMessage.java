package com.appblade.framework.servicebinding;

import java.lang.ref.WeakReference;

import com.appblade.framework.servicebinding.AppBladeServiceManager.ServiceStateListener;

import android.os.Message;

/**
 * Extension of a {@link TwoWayMessage} which allows blocking until a response
 * comes through.
 * 
 * Note that if you do not keep a reference to this object, it may be GC'ed and
 * your logic never run. In the blocking case, this will always be okay, but
 * don't use this for "fire and forget" messages. ONLY use this for blocking calls.
 * 
 * IE - the expected usage is to declare this inside a method and not as an instance
 * variable. Then call {@link #sendAndAwaitResponse()}. This will keep everything valid
 * until the response is returned. And everything you allocate will be freed after your
 * variable is freed on return. 
 * 
 * See {@link DelegateResponseHandler} for more info and rationale.
 * 
 * @author Dylan James
 */
public class BlockingTwoWayMessage extends TwoWayMessage implements ServiceStateListener {

	/**
	 * Interface which is responsible for handling response messages.
	 * 
	 * @author Dylan James
	 */
	public interface ResponseDelegate {
		/**
		 * Called when a response message is received. Processing should
		 * be done here, but note that no other messages may be processed
		 * while this is running, so keep it quick!
		 * 
		 * @param message The {@link Message} which was received in response
		 * @return True if this was a terminating response and the
		 * {@link BlockingTwoWayMessage} should un-block. False to keep waiting.
		 */
		public boolean handleMessage(Message message);
	}
	
	/**
	 * Delegate who will handle responses
	 */
	private ResponseDelegate delegate;
	
	private boolean started;
	private boolean completed;
	private boolean success;
	private boolean isWaiting() { return (started && !completed); }
	
	/**
	 * Holds the message we are sending during blocking so that it may be
	 * cancelled
	 */
	private Message tempMessage;
	
	/**
	 * Creates a {@link BlockingTwoWayMessage} which sends the given message
	 * and sends responses to the given {@link ResponseHandler}
	 * @param message The message to send
	 * @param delegate The delegate which will be used to handle responses
	 */
	public BlockingTwoWayMessage(IAppBladeMessage message, ResponseDelegate delegate) {
		super(message);
		this.delegate = delegate;
		completed = false;
		started = false;
		success = false;
	}
	
	
	/**
	 * Sends this message using the {@link AppBladeServiceManager} and blocks
	 * until a terminating response is received (as determined by the
	 * {@link ResponseDelegate} passed in the constructor).
	 * @see ResponseDelegate#handleMessage(Message)
	 * @return True if the message was sent and received a response. False if
	 * no response could be obtained (e.g. the service was lost.). This doesn't
	 * necessarily mean the service didn't receive our message, but we have
	 * no acknowledgment.
	 */
	public boolean sendAndAwaitResponse() {
		synchronized (this) {
			completed = false;
			started = true;
			
			AppBladeServiceManager serviceManager = AppBladeServiceManager.get();
			// Subscribe to updates while we're blocking
			serviceManager.addStateListener(this);
			
			// If the service isn't available, fail
			if (serviceManager.isServiceUnavailable()) {
				completed = true;
				return false;
			}
			
			// Post our setup to the AppBladeServiceManagers receiver thread
			// This will cause our handler to be created (and therefore run) on
			// the background receiver thread. Therefore, it is ok to block
			// this thread as messages will still be processed elsewhere
			serviceManager.getReceiverThreadHandler().post(sendMessageRunnable);
			
			// Block until the completed flag is raised
			while (!completed) {
				try {
					wait();
				} catch (InterruptedException e) {
					// Check and keep waiting
				}
			}
			
			// We're done, so we don't need to listen to updates anymore
			serviceManager.removeStateListener(this);
			
			tempMessage = null;
			
			// If the success flag isn't raised, we failed to obtain a response
			return success;
		}
	}
	
	private Runnable sendMessageRunnable = new Runnable() {
		public void run() {
			// Create a response handler on this thread
			responseHandler = new ResponseHandler(new DelegateResponseHandler(BlockingTwoWayMessage.this));
			if (tempMessage == null) {
				tempMessage = getMessage();
			}
			// Send the message
			AppBladeServiceManager.get().sendMessage(tempMessage);
		}
	};
	
	
	public void onServiceReconnected() {
		synchronized (this) {
			// If we're waiting for a response, we resend the message
			// to make sure the service responds
			if (isWaiting()) {
				// Cancel the existing message if we can
				attemptToCancel();
				sendMessageRunnable.run();
			}
		}
	}


	public void onServiceLost() {
		// Cancel the existing message if we can
		attemptToCancel();
		// Unlock, leaving the success flag alone
		unlock();
	}
	
	public void onServiceUnavailable() {
		// Cancel the existing message if we can
		attemptToCancel();
		// Unlock, leaving the success flag alone
		unlock();
	}
	
	protected boolean attemptToCancel() {
		if (tempMessage != null) {
			return AppBladeServiceManager.get().cancelMessage(tempMessage);
		}
		return false;
	}
	
	/**
	 * Called when a terminating message is received and we should complete,
	 * unlocking and unblocking this message
	 */
	private void unlock() {
		synchronized (this) {
			completed = true;
			this.notifyAll();
		}
	}
	
	
	/**
	 * Called when a message is received
	 * @param message The received message
	 */
	void handleMessage(Message message) {
		// If we have a delegate and it deems the message to be a terminating
		// message, unlock
		if (delegate != null && delegate.handleMessage(message)) {
			synchronized (this) {
				// Flag that we were successful
				success = true;
				unlock();
			}
		}
	}
	
	/**
	 * Our background handler which will send messages back to us.
	 * 
	 * This class needs to be static so that it doesn't keep an implicit
	 * reference to the outer class, otherwise it may leak our class.
	 * This implies that the outer class may be GC'ed and never called
	 * if another reference is not kept.
	 * 
	 * If it was not static, the outer class, and all its references may
	 * be leaked. This would mean anyone who uses the class would need to
	 * be aware and worry about keeping dangerous references (Contexts etc)
	 * in the classes they pass in. Keeping this static, the outer class
	 * will not be leaked internally, so even if they pass dangerous references
	 * in, we will still let them be GC'ed as normal.
	 * 
	 * If used in a blocking fashion, where the class is declared inline,
	 * waited on, and no reference leaked, this will not leak anything more than
	 * the method would leak otherwise. Since this is the intended use case,
	 * it's easier for the user to use this without worrying about extra leaks.
	 */
	public static class DelegateResponseHandler extends AppBladeMessageHandler {
		// Keep a WeakReference so our outer class can still be GC'ed
		private WeakReference<BlockingTwoWayMessage> messageRef;
		
		/**
		 * Creates a {@link DelegateResponseHandler} that will pass
		 * messages back to the given {@link BlockingTwoWayMessage}.
		 * @param message
		 */
		public DelegateResponseHandler(BlockingTwoWayMessage message) {
			messageRef = new WeakReference<BlockingTwoWayMessage>(message);
		}
		
		@Override
		public void onMessageReceived(Message msg) {
			BlockingTwoWayMessage handler = messageRef.get();
			// If our message reference is still valid, send it a message
			if (handler != null) {
				handler.handleMessage(msg);
			} else {
				// This probably shouldn't happen...
				// If it does, it means nothing has a reference to our message
				// So who is waiting for it?
			}
		}
	}
}
