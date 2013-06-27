package com.appblade.framework.servicebinding;

public class AppBladeServiceConstants {
	public static final String ACTION_BIND_APPBLADE_SERVICE = "com.appblade.android.appbladeservice.bind";

	
	public static class Keys {
		public static final String Token = "token";
		public static final String AppInfo = "appInfo";
		public static final String ProjectSecret = "projectSecret";
		public static final String SDKVersion = "sdkVersion";
		public static final String ServiceVersion = "serviceVersion";
	}
	
	public static class Messages {
		public static final int GetToken = 200;
		public static final int ReturnToken = 201;
	}
}
