package com.appblade.example;

import com.appblade.framework.AppBlade;

import android.app.Application;

public class MyApplication extends Application {

	@Override
	public void onCreate() {
		super.onCreate();
	
		// Populate with tokens from your application settings
		// see README for details
		//copy this into your Application class 
		//remember: you must still integrate the appblade library  
		String uuid = "72143191-43cd-4d5a-a996-cfc10b25441a";
		String token = "d6ed480ad269f6899083f24a2abf3265";
		String secret = "7b8d05dd90f463736766591ce2654d88";
		String issuance = "1328631126";
		
		AppBlade.register(this, token, secret, uuid, issuance, "https://appblade.com");
//		AppBlade.useSessionLoggingService(this.getApplicationContext());
		AppBlade.registerExceptionHandler();
	}

}
