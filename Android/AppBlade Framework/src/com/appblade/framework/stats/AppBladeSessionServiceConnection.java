package com.appblade.framework.stats;

import com.appblade.framework.AppBlade;

import android.content.ComponentName;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.util.Log;

public class AppBladeSessionServiceConnection implements ServiceConnection {
	public AppBladeSessionServiceConnection()
	{
		super();
	}	
	
	public void onServiceConnected(ComponentName name, IBinder service) {
		// Do nothing. We only need the bind count at the moment.
		Log.d(AppBlade.LogTag, "Service Connected");
	}

	public void onServiceDisconnected(ComponentName name) {
		// Do nothing. We only need the bind count at the moment.
		Log.d(AppBlade.LogTag, "Service Disconnected");

	}


}
