package com.appblade.framework.servicebinding;

import android.os.Message;

public class AppBladeServiceConstants {
	/**
	 * The Intent action for binding to the AppBlade Service
	 */
	public static final String ACTION_BIND_APPBLADE_SERVICE = "com.appblade.android.appbladeservice.bind";

	/**
	 * Standard keys used for putting/retrieving data from bundles
	 * or other tables
	 */
	public static class Keys {
		public static final String Token = "token";
		public static final String AppInfo = "appInfo";
		public static final String ProjectSecret = "projectSecret";
		public static final String SDKVersion = "sdkVersion";
		public static final String ServiceVersion = "serviceVersion";
	}
	
	/**
	 * Constants for {@link Message#what} field which identifies the message
	 */
	public static class Messages {
		/**
		 * Message which is a request for a token
		 * @see Messages#ReturnToken
		 */
		public static final int GetToken = 200;
		/**
		 * Message which is the returned token
		 * @see Messages#GetToken
		 */
		public static final int ReturnToken = 201;
	}
}
