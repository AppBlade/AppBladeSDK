package com.appblade.framework.utils;

import java.io.IOException;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;

public class SystemUtils {
	
	public static boolean hasPermission(PackageInfo pkg, String requested) {
		String[] permissions = pkg.requestedPermissions;
		for (String permission : permissions) {
			if (permission.equals(requested))
				return true;
		}
		return false;
	}
	
	public static String generateUniqueID(PackageInfo pi) {
		String toRet = "";
		toRet = pi.packageName + ":";
		toRet = toRet + pi.versionName + ":";
		toRet = toRet + pi.versionCode + ":";
		//pi.lastUpdateTime API 9 and higher. grab this straight from the dex
		ApplicationInfo ai = pi.applicationInfo;
		ZipFile zf;
		try {
			zf = new ZipFile(ai.sourceDir);
			ZipEntry ze = zf.getEntry("classes.dex");
			long time = ze.getTime();  //time classes.dex was built will remain the same throughout installs
			toRet = toRet + time;
		} catch (IOException e) {
			e.printStackTrace();
			//error grabbing build time. append "debug" instead
			toRet = toRet + "debug";
		}
		return toRet;
	}

}