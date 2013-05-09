package com.notappblade.updatetest;

import android.app.Application;
import com.appblade.framework.AppBlade;

public class AppBladeApplication extends Application {
	@Override
	public void onCreate() {
		super.onCreate();
		AppBlade.registerWithAssetFile(this.getApplicationContext());
	}
}
