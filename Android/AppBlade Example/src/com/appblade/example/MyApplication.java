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
		String uuid = "3243f338-2a5f-44df-b8b6-09264d4b66ab";
		String token = "c45a434195a05650955193180869c9aa";
		String secret = "f865fdd96f1ed6b3e6db0063762c84db";
		String issuance = "1358808370";
		AppBlade.register(this, token, secret, uuid, issuance);
//		AppBlade.useSessionLoggingService(this.getApplicationContext());
		AppBlade.registerExceptionHandler();
	}

}
