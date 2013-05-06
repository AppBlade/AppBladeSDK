package com.notappblade.updatetest;

import android.app.Application;
import com.appblade.framework.AppBlade;

public class AppBladeApplication extends Application {
	@Override
	public void onCreate() {
		super.onCreate();
		String uuid = "56b5ec05-708e-4cb2-bd85-113ae9919852";
		String token = "fa57d5800bda04a5f28b97d31d3ce4c4";
		String secret = "6bfc0425a2414118d5c755eb19a96d73";
		String issuance = "1363045440";
		AppBlade.register(this, token, secret, uuid, issuance);
	}
}
