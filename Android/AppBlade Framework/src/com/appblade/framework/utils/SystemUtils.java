package com.appblade.framework.utils;

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
}