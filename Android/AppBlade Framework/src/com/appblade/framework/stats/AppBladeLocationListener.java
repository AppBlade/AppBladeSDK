package com.appblade.framework.stats;

import android.location.Location;
import android.location.LocationListener;
import android.os.Bundle;
import android.util.Log;

/**
 * Currently in our stats class since that's the only place it's used. May change to a more global place in the future.<br>
 *    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"></uses-permission>
 * @author andrew.tremblay
 */
public class AppBladeLocationListener implements LocationListener {
	public void onLocationChanged(Location location) {
	    if (location != null) {
		    Log.d("LOCATION CHANGED", location.getLatitude() + "");
		    Log.d("LOCATION CHANGED", location.getLongitude() + "");
	    }
	}
	public void onProviderDisabled(String provider) {
		
	}
	public void onProviderEnabled(String provider) {
		
	}
	public void onStatusChanged(String provider, int status, Bundle extras) {
		// TODO Auto-generated method stub
		
	}
}
