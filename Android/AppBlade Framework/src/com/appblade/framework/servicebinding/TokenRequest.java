package com.appblade.framework.servicebinding;

import android.os.Bundle;

import com.appblade.framework.AppBlade;
import com.appblade.framework.AppInfo;
import com.appblade.framework.servicebinding.AppBladeServiceConstants.Keys;

public class TokenRequest {
	public String projectSecret;
	public AppInfo appInfo;
	public int sdkVersion;
	
	public TokenRequest(String projectSecret, AppInfo info) {
		this.projectSecret = projectSecret;
		this.appInfo = info;
		this.sdkVersion = AppBlade.SDKVersion;
	}
	
	private TokenRequest() { }
	
	
	public static Bundle toBundle(TokenRequest request) {
		Bundle bundle = new Bundle();
		
		bundle.putString(Keys.ProjectSecret, request.projectSecret);
		bundle.putBundle(Keys.AppInfo, AppInfo.toBundle(request.appInfo));
		bundle.putInt(Keys.SDKVersion, request.sdkVersion);
		
		return bundle;
	}
	
	public static TokenRequest fromBundle(Bundle bundle) {
		TokenRequest request = new TokenRequest();
		
		request.projectSecret = bundle.getString(Keys.ProjectSecret);
		request.appInfo = AppInfo.fromBundle(bundle.getBundle(Keys.AppInfo));
		request.sdkVersion = bundle.getInt(Keys.SDKVersion);
		
		return request;
	}
}
