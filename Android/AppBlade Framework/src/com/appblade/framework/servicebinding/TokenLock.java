package com.appblade.framework.servicebinding;

/**
 * Helper class which keeps track of a token and allows waiting/blocking for a
 * token for synchronization purposes. Note: null is not considered a valid token.
 * @author Dylan James
 *
 */
public class TokenLock {
	
	private String token;
	/**
	 * @return The current token. This WILL NOT block and wait for it, it simply
	 * returns the current value;
	 */
	public String getToken() { return token; }
	
	/**
	 * @return True if we have a token
	 */
	public boolean hasToken() { return token != null; }
	
	/**
	 * Creates a new lock in the locked state - there is no token yet.
	 */
	public TokenLock() { }
	
	
	/**
	 * Call this when a token is obtained. This will set the token and unblock
	 * anyone who is waiting for the token.
	 * @param token The obtained token
	 */
	public void onTokenObtained(String token) {
		synchronized (this) {			
			this.token = token;
			this.notifyAll();
		}
	}
	
	/**
	 * Call this when a token is revoked. This will reset the token and put
	 * this into a no-token state, blocking anyone who waits on it until
	 * a token is obtained again.
	 */
	public void onTokenRevoked() {
		synchronized (this) {
			this.token = null;
		}
	}
	
	/**
	 * Blocks until a token is obtained, or returns immediately if we already
	 * have one.
	 * @return The obtained token.
	 */
	public String waitForToken() {
		synchronized (this) {
			while (token == null) {
				try {
					wait();
				} catch (InterruptedException e) {
					// This is ok - Just need to recheck token condition
					// May need to wait again
				}
			}
		}
		return token;
	}
}
