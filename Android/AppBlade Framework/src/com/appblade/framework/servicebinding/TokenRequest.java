package com.appblade.framework.servicebinding;

import android.os.Bundle;

import com.appblade.framework.AppBlade;
import com.appblade.framework.AppInfo;
import com.appblade.framework.servicebinding.AppBladeServiceConstants.Keys;

/**
 * Class which stores all the information needed to request a token.
 * This is basically a convenience class which allows us to stuff all
 * the data into one {@link Bundle} and pull it back out. (Messages
 * only support a single bundle) 
 * 
 * @author Dylan James
 */
public class TokenRequest {
	/**
	 * The project secret
	 */
	public String projectSecret;
	/**
	 * The info about the app requesting access
	 */
	public AppInfo appInfo;
	
	/**
	 * The version code of the SDK requesting access
	 * This corresponds to {@link AppBlade#SDKVersion}
	 */
	public int sdkVersion;
	
	/**
	 * Creates a {@link TokenRequest} based off the given data
	 * @param projectSecret
	 * @param info
	 */
	public TokenRequest(String projectSecret, AppInfo info) {
		this.projectSecret = projectSecret;
		this.appInfo = info;
		this.sdkVersion = AppBlade.SDKVersion;
	}
	
	private TokenRequest() { }
	
	/**
	 * Stuffs all the information in the given {@link TokenRequest} into a
	 * {@link Bundle} so it may be easily passed around and recreated via
	 * {@link #fromBundle(Bundle)}
	 * @param request The {@link TokenRequest} to store in the {@link Bundle}
	 * @return A {@link Bundle} containing all the information needed to
	 * recreate the {@link TokenRequest}
	 */
	public static Bundle toBundle(TokenRequest request) {
		Bundle bundle = new Bundle();
		
		bundle.putString(Keys.ProjectSecret, request.projectSecret);
		bundle.putBundle(Keys.AppInfo, AppInfo.toBundle(request.appInfo));
		bundle.putInt(Keys.SDKVersion, request.sdkVersion);
		
		return bundle;
	}
	
	/**
	 * Restores a {@link TokenRequest} from the given {@link Bundle} created
	 * by {@link #toBundle(TokenRequest)}
	 * @param bundle The {@link Bundle} containing the {@link TokenRequest} info
	 * @return The {@link TokenRequest} created from the {@link Bundle}
	 */
	public static TokenRequest fromBundle(Bundle bundle) {
		TokenRequest request = new TokenRequest();
		
		request.projectSecret = bundle.getString(Keys.ProjectSecret);
		request.appInfo = AppInfo.fromBundle(bundle.getBundle(Keys.AppInfo));
		request.sdkVersion = bundle.getInt(Keys.SDKVersion);
		
		return request;
	}
}
