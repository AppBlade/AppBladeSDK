package com.appblade.example;

import com.appblade.framework.AppBlade;

import android.app.Application;

public class MyApplication extends Application {

	@Override
	public void onCreate() {
		super.onCreate();
	
		// Populate with tokens from your application settings
		// see README for details
		
		String uuid = "dd70ca7b-a841-48f2-bdee-7fcc0929e9f5";
		String token = "c8223091173a8949c02ec6d5838f487b";
		String secret = "cb29424385cb284b381d76261e538faf";
		String issuance = "1333051907";
		
//		String uuid = "";
//		String token = "";
//		String secret = "";
//		String issuance = "";
		
		AppBlade.register(this, token, secret, uuid, issuance);
	}

}
