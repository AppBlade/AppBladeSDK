package com.appblade.framework.stats;

import org.json.JSONArray;
import org.json.JSONException;

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

	//probably keep an array in here. 
	
	LocationManager lm;
	
    public void subscribeToLocationUpdates(Context context) {
        this.lm = (LocationManager)context.getSystemService(Context.LOCATION_SERVICE);
        this.lm.requestLocationUpdates(LocationManager.GPS_PROVIDER, 0, 0, this);
        onLocationChanged(lm.getLastKnownLocation(LocationManager.GPS_PROVIDER));
    }
	
	public void onLocationChanged(Location location) {
		Log.d(AppBlade.LogTag, "User is now using AppBlade Location Service.");

	    if (location != null) {
			lastLatitude = String.valueOf(location.getLongitude());
			lastLongitude =  String.valueOf(location.getLatitude());
	    	lastLocationTime = String.valueOf(location.getTime());

	    	Log.d(AppBlade.LogTag, "AppBlade Location Service reports location: " + location);
			Log.d(AppBlade.LogTag, "AppBlade Location Service reports Lat: " + lastLatitude + "  Long: " +lastLongitude);

			if(AppBlade.sessionLocationEnabled && AppBlade.currentSession != null){
		    	AppBlade.currentSession.locations.put(AppBladeLocationListener.getLastLocationAsArray());

				Log.d(AppBlade.LogTag, "AppBlade Location Service adds Lat: " + lastLatitude + "  Long: " +lastLongitude + " to the list of " + AppBlade.currentSession.locations.length() + " stored locations");

		    }
	    }
	}
	
	
	public static JSONArray getLastLocationAsArray()
	{
		JSONArray toRet = new JSONArray();
		try {
			toRet.put(0, lastLatitude);
			toRet.put(1, lastLongitude);
			toRet.put(2, lastLocationTime);
		} catch (JSONException e) {
			e.printStackTrace();
		}
		return toRet;
	}
	
	public JSONArray getAllStoredLocations()
	{
		JSONArray toRet = new JSONArray();
		toRet.put(getLastLocationAsArray());
		return toRet;
	}
	
	
	public void onProviderDisabled(String provider) {
		Log.d(AppBlade.LogTag, "User disabled AppBlade Location Service.");
	    if(AppBlade.sessionLocationEnabled && AppBlade.currentSession != null){
	    	//Be polite. You didn't see anything.  
	    	AppBlade.currentSession.locations = new JSONArray();			
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
