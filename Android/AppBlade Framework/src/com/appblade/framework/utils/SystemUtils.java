package com.appblade.framework.utils;

import java.io.IOException;
import java.io.InputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import com.appblade.framework.AppBlade;
import com.appblade.framework.AppInfo;

import android.content.ContentResolver;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;

/**
 * A class to help check for permissions and generate hashes for files in the apk. Used mostly for identifiers for AppBlade.
 * @author andrew.tremblay@raizlabs
 */
public class SystemUtils {
	public static final String UserAgent = "Android";
	
	/**
	 * A helper method check for whether a specific permission was requested by the package.
	 * @param pkg The PackageInfo that might have requested the permission. 
	 * @param requested String name of the permission.
	 * @return true if the name of the permission was found in {@link android.content.pm.PackageInfo.requestedPermissions}.
	 */
	public static boolean hasPermission(PackageInfo pkg, String requested) {
		String[] permissions = pkg.requestedPermissions;
		for (String permission : permissions) {
			if (permission.equals(requested))
				return true;
		}
		return false;
	}
	
	/**
	 * We will probably slowly phase this in to handle device identifiers, and patch it quite often whenever we have to deal with manufacturer edge cases.
	 * <br>Right now though, this is the most concise method to generate a udid that's consistent across wipes and updates whenever possible.
	 * @return A unique-enough device identifier for when we need that. Should not yet relied be upon to be unique in all cases. 
	 */
	public static String getBestUniqueDeviceID(ContentResolver cr) 
	{
		String toRet = getReadableFINGERPRINT();
		if(cr != null)
		{
			String android_id = Settings.Secure.getString(cr, Settings.Secure.ANDROID_ID); ; //Not factory reset safe. But will hold up across boots and updates, might be "android_id"
			//not secure with rooted phones (but then again, nothing is) [adb shell sqlite3 /data/data/com.android.providers.settings/databases/settings.db "UPDATE secure SET value='IDHERE' WHERE name='android_id'"]
			String stupidVerison = "9774d56d682e549c"; //for the infamous Droid2 bug of API 7 that broke everything (https://groups.google.com/forum/?fromgroups=#!topic/android-developers/U4mOUI-rRPY)
			if(!stupidVerison.equals(android_id) && !StringUtils.isNullOrEmpty(android_id ))
			{
				toRet = android_id; //holds up across boots, but not guaranteed for wipes (or even updates) can be "unknown" in certain cases
				//note other solutions like Wifi MAC-address and the phones Telephony IMEI were considered but are too unreliable at the moment.
				//MAC address might not be reported if Wifi is turned off, and IMEI might not be available without a SIM card
				//Also TelephonyManager requires another permission: android.permission.READ_PHONE_STATE 
				//Similar things occur with BluetoothAdapter.getDefaultAdapter().getAddress()			
			}
		}
		return toRet;
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
			zf.close();
		} catch (IOException e) {
			e.printStackTrace();
			//error grabbing build time. append "debug" instead
			toRet = toRet + "debug";
		}
		return toRet;
	}
	
	/**
	 * A helper method to generate a SHA256 hash of a given file inside a package.
	 * @param pi The PackageInfo that will provide the source directory in which to look. 
	 * @param filename String name of the file, from within the base source directory, that we want to generate our hash.
	 * @return The (SHA256) of the given filename, or null if the file could not be found.
	 */
	public static String hashedUuidOfPackageFile(PackageInfo pi, String filename){
		String toRet = null;
		ApplicationInfo ai = pi.applicationInfo;
		ZipFile zf;
		try {
			zf = new ZipFile(ai.sourceDir);
			ZipEntry ze = zf.getEntry(filename);
			if(ze != null){
				InputStream streamToHash = zf.getInputStream(ze);
				toRet = StringUtils.sha256FromInputStream(streamToHash);
			}
			zf.close();
		} catch (IOException e) {
			Log.v(AppBlade.LogTag, "Error reading "+filename);
			e.printStackTrace();
		}
		
		return toRet;

	}


	/**
	 * A hash representing the manifest file included in the APK, the value will change when the file does and not at any other time.
	 * @param pi
	 * @return The (SHA256) of AndroidManifest.xml, the file representing all settings, permissions, and version values in the apk.
	 */
	public static String hashedManifestFileUuid(PackageInfo pi){
		return hashedUuidOfPackageFile(pi, "AndroidManifest.xml");  //use this instead of META-INF/MANIFEST.MF, not enough data there.
	}

	
	/**
	 * A hash representing all classes in the APK, the value will change when the classes do and not at any other time.
	 * @param pi
	 * @return The (SHA256) of classes.dex, the file representing all compiled classes in the apk.
	 */
	public static String hashedExecutableUuid(PackageInfo pi){
		return hashedUuidOfPackageFile(pi, "classes.dex");
	}

	/**
	 * A hash representing all resources in the APK, the value will change when the resources do and not at any other time.
	 * @param pi
	 * @return The (SHA256) of resources.arsc, the compiled file for all resources in the apk.
	 */
	public static String hashedStaticResourcesUuid(PackageInfo pi){
		return hashedUuidOfPackageFile(pi, "resources.arsc");
	}
	
	/**
	 * Builds run through eclipse will be signed with the debug certificate. 
	 * How to detect the debug certificate properly is a matter of some debate.
	 * @param pi
	 * @return The (SHA256) hash of either a CERT.DSA or a CERT.RSA file in the META-INF folder.
	 */
	public static String hashedCertificateUuid(PackageInfo pi){
		String toRet = "unsigned";
		if(AppInfo.isSigned(pi)){
			toRet = hashedUuidOfPackageFile(pi, "META-INF/CERT.DSA");
			if(toRet == null){
				toRet = hashedUuidOfPackageFile(pi, "META-INF/CERT.RSA");				
			}
			if(toRet == null){
				toRet = StringUtils.sha256OfNull; //hash of null
			}
		} 
		return toRet;
	}

	/**
	 * Grabs the fingerprint of the device and swaps out the non-web-friendly characters to match the appblade slug
	 * @return Build.FINGERPRINT without the "/"s, "."s, and ":"s (swapped with "__", "-", and "-" respectively).
	 */
	public static String getReadableFINGERPRINT() {
		return Build.FINGERPRINT.replace("/", "__").replace(".", "-").replace(":", "-"); //make it so the fingerprint doesn't break routes
	}
	
	/**
	 * Formats packages into a File-system-readable apk name. 
	 * @param packageName a package name, either from packageInfo or from an AppBlade server response. (com.appblade.example)
	 * @return The formatted package name with the periods replaced by underscores (com_appblade_example)
	 */
	public static String getReadableApkFileNameFromPackageName(String packageName) {
		String identifierSanitized = packageName.replaceAll("\\.", "_");
		return String.format("%s%s", identifierSanitized, ".apk");
	}
	

	


	
}