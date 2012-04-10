package com.appblade.example;

import com.appblade.framework.AppBlade;

import android.app.Application;

public class MyApplication extends Application {

	@Override
	public void onCreate() {
		super.onCreate();
	
		// Populate with tokens from your application settings
		// see README for details	
		String token = "";
		String secret = "";
		String uuid = "";
		String issuance = "";
		
		AppBlade.register(this, token, secret, uuid, issuance);
	}

}
