package com.appblade.framework;


import android.content.pm.PackageInfo;
import android.os.Build;

class AppInfo {
	
	static final String DefaultUDID = "0000000000000000000000000000000000000000";
	public static String DefaultAppBladeHost = "AppBlade.com";
	public static String DefaultServiceScheme = "https://";

	String Token;
	String Secret;
	String AppId;
	String Issuance;
	String Ext = DefaultUDID;
	String CurrentEndpoint = DefaultAppBladeHost;
	String CurrentServiceScheme = DefaultServiceScheme;
	
	PackageInfo PackageInfo;
	private String systemInfo;
	
	synchronized String getSystemInfo()
	{
		if(StringUtils.isNullOrEmpty(systemInfo))
			initSystemInfo();
		
		return systemInfo;
	}

	void initSystemInfo() {
		StringBuilder builder = new StringBuilder();

		StringUtils.append(builder, "BOARD:  %s%n", Build.BOARD);
		StringUtils.append(builder, "BRAND:  %s%n", Build.BRAND);
		StringUtils.append(builder, "DEVICE:  %s%n", Build.DEVICE);
		StringUtils.append(builder, "DISPLAY:  %s%n", Build.DISPLAY);
		StringUtils.append(builder, "FINGERPRINT:  %s%n", Build.FINGERPRINT);
		StringUtils.append(builder, "ID:  %s%n", Build.ID);
		StringUtils.append(builder, "MANUFACTURER:  %s%n", Build.MANUFACTURER);
		StringUtils.append(builder, "MODEL:  %s%n", Build.MODEL);
		StringUtils.append(builder, "RELEASE:  %s%n", Build.VERSION.RELEASE);
		StringUtils.append(builder, "SDK_INT:  %d%n", Build.VERSION.SDK_INT);
		
		StringUtils.append(builder, "%n");
		
		if(PackageInfo != null)
		{
			StringUtils.append(builder, "Package name:  %s%n", PackageInfo.packageName);
			StringUtils.append(builder, "Version name:  %s%n", PackageInfo.versionName);
			
			StringUtils.append(builder, "%n");
		}
		
		systemInfo = builder.toString();
	}
	
	public boolean isValid() {
		return
				!StringUtils.isNullOrEmpty(AppId) &&
				!StringUtils.isNullOrEmpty(Token) &&
				!StringUtils.isNullOrEmpty(Secret) &&
				!StringUtils.isNullOrEmpty(Issuance);
	}

}
