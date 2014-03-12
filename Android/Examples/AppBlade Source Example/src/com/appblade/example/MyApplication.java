package com.appblade.example;

import com.appblade.framework.AppBlade;

import android.app.Application;

public class MyApplication extends Application {

	@Override
	public void onCreate() {
		super.onCreate();
//		AppBlade.registerWithAssetFile(this);
		AppBlade.registerViaService(this, "testProjectSecret");

		AppBlade.registerExceptionHandler();
	}

}
