package com.appblade.framework.utils;

import java.io.IOException;
import java.io.InputStream;
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
	
	//"[Package Name]:[Version Name]:[Version Code]:[Timestamp of the last time classes.dex was edited]"
	@Deprecated
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
			long time = (ze.getTime() / 1000);  //time classes.dex was built will remain the same throughout installs (removing last 4 zeros to match appblade)
			toRet = toRet + time;
		} catch (IOException e) {
			e.printStackTrace();
			//error grabbing build time. append "debug" instead
			toRet = toRet + "debug";
		}
		return toRet;
	
	}
	
	public static String  hashedUuidOfPackageFile(PackageInfo pi, String filename){
		String toRet = null;
		ApplicationInfo ai = pi.applicationInfo;
		ZipFile zf;
		try {
			zf = new ZipFile(ai.sourceDir);
			ZipEntry ze = zf.getEntry(filename);
			InputStream streamToHash = zf.getInputStream(ze);
			toRet = StringUtils.sha256FromInputStream(streamToHash);
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		return toRet;

	}
	public static String hashedExecutableUuid(PackageInfo pi){
		return hashedUuidOfPackageFile(pi, "classes.dex");
	}
	public static String hashedStaticResourcesUuid(PackageInfo pi){
		return hashedUuidOfPackageFile(pi, "resources.arsc");
	}
	public static String hashedCertificateUuid(PackageInfo pi){
		return hashedUuidOfPackageFile(pi, "META-INF/CERT.RSA");
	}

	
}