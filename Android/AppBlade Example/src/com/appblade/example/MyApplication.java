package com.appblade.example;

import com.appblade.framework.AppBlade;

import android.app.Application;

public class MyApplication extends Application {

	@Override
	public void onCreate() {
		super.onCreate();
	
		// Populate with tokens from your application settings
		// see README for details	
		String uuid = "ca460dcb-b7c2-43c1-ba50-8b6cda63f369";
		String token = "8f1792db8a39108c14fa8c89663eec98";
		String secret = "c8536a333fb292ba46fc98719c1cfdf6";
		String issuance = "1316609918";
		
		AppBlade.register(this, token, secret, uuid, issuance);
	}

}
