package com.appblade.framework;


import java.io.IOException;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import com.appblade.framework.utils.StringUtils;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.os.Build;
import android.os.Bundle;
import android.telephony.TelephonyManager;


/**
 * AppInfo
 * Class that stores AppBlade registration information as well as other useful app information, incluing PackageInfo, whether the package is signed, and whether the app is being run in the emulator.
 * @author andrew.tremblay@raizlabs
 *
 */
public class AppInfo {
	static final String DefaultUDID = "0000000000000000000000000000000000000000";
	public static String DefaultAppBladeHost = "AppBlade.com";
	public static String DefaultServiceScheme = "https://";

	public String DeviceSecret;
	public String ProjectSecret;
	public String CurrentEndpoint = DefaultAppBladeHost;
	public String CurrentEndpointNoPort = DefaultAppBladeHost;
	public String CurrentServiceScheme = DefaultServiceScheme;
	
	PackageInfo PackageInfo;
	private String systemInfo;
	public String storedANDROID_ID;
	

	
	
	
	/**
	 * Initializes systemInfo string if it does not yet exist.
	 * @return String of all current interesting device information, see initSystemInfo() for a breakdown.
	 */
	public synchronized String getSystemInfo()
	{
		if(StringUtils.isNullOrEmpty(systemInfo))
		{
			initSystemInfo();
		}
		return systemInfo;
	}

	/**
	 * Initializer for all interesting device information. Will include Package information if that is available.
	 */
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
	/**
	 * Static call to check if we are signed (a.k.a. running in eclipse), checks for the existence of a certificate and only returns true on its existence. 
	 * This would be a good check to call if you didn't want errors, sessions, or feedback to be logged while you were just developing the app locally.
	 * @param pi the package info we are checking, usually just AppInfo.PackageInfo
	 * @return whether we are signed, which is the same as saying whether we are running the apk locally.
	 */
	public static boolean isSigned(PackageInfo pi) {
		boolean toRet = false;
		if(pi != null){
			ApplicationInfo ai = pi.applicationInfo;
			ZipFile zf;
				try {
					zf = new ZipFile(ai.sourceDir);
					//check for the existence of a DSA or RSA file, which will be the public key of whatever we're supposedly signed with 
					ZipEntry ze = zf.getEntry("META-INF/CERT.DSA");
					ZipEntry zr = zf.getEntry("META-INF/CERT.RSA");
					//TODO: enumerate through META-INF and check for *.RSA/*DSA, since we can be signed with multiple files and there's no guarantee for names. 99.999% of people will just sign once though. 
					toRet = (ze != null) || (zr != null);
				} catch (IOException e) {
					e.printStackTrace();
				}
		}
		return toRet;
	}
	
	/**
	 * Static call to check if we are running in the emulator (a.k.a. development),
	 * @param context The Context we are checking to be running in the emulator
	 * @return whether we are in an emulator
	 */
	public static boolean isInEmulator(Context context) {
		boolean toRet = false;
		TelephonyManager tm = (TelephonyManager)context.getSystemService(Context.TELEPHONY_SERVICE);
		String networkOperator = tm.getNetworkOperatorName();
		AppBlade.Log( "networkOperator "+networkOperator);
		if("Android".equals(networkOperator)) {
		    // Emulator
			toRet = true;
		}
		else {
		    // Device
		}
		return toRet;
	}

	/**
	 * Checks validity (existence) of AppBlade variables. If we don't have that we prety much can't do anything. 
	 * @return if we are valid 
	 */
	public boolean isValid() {
		return
				!StringUtils.isNullOrEmpty(DeviceSecret) &&
				!StringUtils.isNullOrEmpty(ProjectSecret);
	}

	
	
	
	// **********************
	// ****** Bundling ******
	// **********************	
	
	// THESE CONSTANTS SHOULD NEVER CHANGE
	// Otherwise there may be incompatibilities between SDK and the AppBlade App
	// If the structure changes, keys should be added, but old ones should probably be kept
	// for compatibility in case we ever need them
	//
	// The functions should stay the same as well, or at least consider that keys may be
	// missing in future/previous versions of the bundling

	/**
	 * Class of key constants used for bundling {@linkd AppInfo}s.
	 * @author Dylan James
	 *
	 */
	public static final class BundleKeys {
		public static final String DeviceSecret = "DeviceSecret";
		public static final String ProjectSecret = "ProjectSecret";
		public static final String CurrentEndpoint = "CurrentEndpoint";
		public static final String CurrentEndpointNoPort = "CurrentEndpointNoPort";
		public static final String CurrentServiceScheme = "CurrentServiceScheme";
		
		public static final String PackageInfo = "PackageInfo";
		public static final String SystemInfo = "SystemInfo";
		public static final String StoredAndroidID = "StoredAndroidID";		
	}
	
	/**
	 * Creates a bundle containing all the persistent information in the given
	 * {@link AppInfo}. This can be used for persistence or for IPC.
	 *  
	 * @param appInfo The {@link AppInfo} to convert into a bundle.
	 * @return A {@link Bundle} which contains the information needed to recreate
	 * the {@link AppInfo}.
	 */
	public static Bundle toBundle(AppInfo appInfo) {
		Bundle bundle = new Bundle();
		
		bundle.putString(BundleKeys.DeviceSecret, appInfo.DeviceSecret);
		bundle.putString(BundleKeys.ProjectSecret, appInfo.ProjectSecret);
		bundle.putString(BundleKeys.CurrentEndpoint, appInfo.CurrentEndpoint);
		bundle.putString(BundleKeys.CurrentEndpointNoPort, appInfo.CurrentEndpointNoPort);
		bundle.putString(BundleKeys.CurrentServiceScheme, appInfo.CurrentServiceScheme);

		bundle.putParcelable(BundleKeys.PackageInfo, appInfo.PackageInfo);
		bundle.putString(BundleKeys.SystemInfo, appInfo.systemInfo);
		bundle.putString(BundleKeys.StoredAndroidID, appInfo.storedANDROID_ID);
		
		return bundle;
	}
	
	/**
	 * Reads an {@link AppInfo} out of the information contained inside the given
	 * {@link Bundle}. This can be used to restore persisted {@link AppInfo}s.
	 * @param bundle The {@link Bundle} to read the data from.
	 * @return The {@link AppInfo} representing the data inside the given bundle.
	 */
	public static AppInfo fromBundle(Bundle bundle) {
		AppInfo appInfo = new AppInfo();
		
		appInfo.DeviceSecret = bundle.getString(BundleKeys.DeviceSecret);
		appInfo.ProjectSecret = bundle.getString(BundleKeys.ProjectSecret);
		appInfo.CurrentEndpoint = bundle.getString(BundleKeys.CurrentEndpoint);
		appInfo.CurrentEndpointNoPort = bundle.getString(BundleKeys.CurrentEndpointNoPort);
		appInfo.CurrentServiceScheme = bundle.getString(BundleKeys.CurrentServiceScheme);
		
		appInfo.PackageInfo = bundle.getParcelable(BundleKeys.PackageInfo);
		appInfo.systemInfo = bundle.getString(BundleKeys.PackageInfo);
		appInfo.storedANDROID_ID = bundle.getString(BundleKeys.StoredAndroidID);
		
		return appInfo;
	}
}
