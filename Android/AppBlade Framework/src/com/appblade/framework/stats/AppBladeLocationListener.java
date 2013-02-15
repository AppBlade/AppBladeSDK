package com.appblade.framework.stats;

import com.appblade.framework.AppBlade;

import android.content.Context;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.location.LocationProvider;
import android.os.Bundle;
import android.util.Log;

/**
 * Currently in our stats class since that's the only place it's used. May change to a more global place in the future.<br>
 *    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"></uses-permission>
 * @author andrew.tremblay
 */
public class AppBladeLocationListener implements LocationListener {
	public static String lastLongitude;
	public static String lastLatitude;
	public static String lastLocationTime;

	LocationManager lm;
	
    public void subscribeToLocationUpdates(Context context) {
        this.lm = (LocationManager)context.getSystemService(Context.LOCATION_SERVICE);
        this.lm.requestLocationUpdates(LocationManager.GPS_PROVIDER, 0, 0, this);
        
        onLocationChanged(lm.getLastKnownLocation(LocationManager.GPS_PROVIDER));
    }
	
	public void onLocationChanged(Location location) {
		Log.d(AppBlade.LogTag, "User is now using AppBlade Location Service.");

	    if (location != null) {
	    	lastLocationTime = String.valueOf(location.getTime());
			lastLongitude =  String.valueOf(location.getLatitude());
			lastLatitude = String.valueOf(location.getLongitude());
			Log.d(AppBlade.LogTag, "AppBlade Location Service reports location: " + location);
			Log.d(AppBlade.LogTag, "AppBlade Location Service reports Lat: " + lastLatitude + "  Long: " +lastLongitude);

			if(AppBlade.sessionLocationEnabled && AppBlade.currentSession != null){
		    	AppBlade.currentSession.longitude = lastLongitude;
				AppBlade.currentSession.latitude = lastLatitude;

				Log.d(AppBlade.LogTag, "AppBlade Location Service reports Lat: " + lastLatitude + "  Long: " +lastLongitude);

		    }
	    }
	}
	public void onProviderDisabled(String provider) {
		Log.d(AppBlade.LogTag, "User disabled AppBlade Location Service.");
	    if(AppBlade.sessionLocationEnabled && AppBlade.currentSession != null){
	    	//Be polite. You didn't see anything.  
	    	AppBlade.currentSession.latitude = null;
			AppBlade.currentSession.longitude = null;
			lastLongitude = null;
			lastLatitude = null;
			

	    }
	}
	public void onProviderEnabled(String provider) {
		Log.d(AppBlade.LogTag, "User is now using AppBlade Location Service.");
	}
	public void onStatusChanged(String provider, int status, Bundle extras) {
		if(status == LocationProvider.OUT_OF_SERVICE){
			Log.d(AppBlade.LogTag, provider + " is out of service. AppBlade Location might not be accurate");
		}
		if(status == LocationProvider.TEMPORARILY_UNAVAILABLE){
			Log.d(AppBlade.LogTag, provider + " is temporarily unavailable. AppBlade Location might not be accurate");
		}
	}
}
