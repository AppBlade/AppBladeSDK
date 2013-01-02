package com.appblade.framework;


import java.io.IOException;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import com.appblade.framework.utils.StringUtils;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.os.Build;

public class AppInfo {
	
	static final String DefaultUDID = "0000000000000000000000000000000000000000";
	public static String DefaultAppBladeHost = "AppBlade.com";
	public static String DefaultServiceScheme = "https://";

	public String Token;
	public String Secret;
	public String AppId;
	public String Issuance;
	public String Ext = DefaultUDID;
	public String CurrentEndpoint = DefaultAppBladeHost;
	public String CurrentServiceScheme = DefaultServiceScheme;
	
	PackageInfo PackageInfo;
	private String systemInfo;
	
	public synchronized String getSystemInfo()
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
	
	
	//a good check to see if we are in eclipse, since that doesn't sign apks before uploading to attached devices
	public static boolean isSigned(PackageInfo pi) {
		boolean toRet = false;
		if(pi != null){
			ApplicationInfo ai = pi.applicationInfo;
			ZipFile zf;
				try {
					zf = new ZipFile(ai.sourceDir);
					ZipEntry ze = zf.getEntry("META-INF/CERT.DSA");
					toRet = (ze != null);
				} catch (IOException e) {
					e.printStackTrace();
				}
		}
		return toRet;
	}
	
	//There is apparently a better way to do this by checking if the debug certificate is included, but right now checking that the cert is missing's our best bet 
	public static boolean isInEmulator(PackageInfo pi) {
		boolean toRet = false;
		if(pi != null){
			ApplicationInfo ai = pi.applicationInfo;
			ZipFile zf;
				try {
					zf = new ZipFile(ai.sourceDir);
					ZipEntry ze = zf.getEntry("META-INF/CERT.DSA");
					toRet = (ze != null);
				} catch (IOException e) {
					e.printStackTrace();
				}
		}
		return toRet;
	}

	
	public boolean isValid() {
		return
				!StringUtils.isNullOrEmpty(AppId) &&
				!StringUtils.isNullOrEmpty(Token) &&
				!StringUtils.isNullOrEmpty(Secret) &&
				!StringUtils.isNullOrEmpty(Issuance);
	}

}
