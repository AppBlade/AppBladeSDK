package com.appblade.framework.stats;

import com.appblade.framework.AppBlade;

import android.content.ComponentName;
import android.content.ServiceConnection;
import android.os.IBinder;


public class AppBladeSessionServiceConnection implements ServiceConnection {
	public AppBladeSessionServiceConnection()
	{
		super();
	}	
	
	public void onServiceConnected(ComponentName name, IBinder service) {
		// Do nothing. We only need the bind count at the moment.
		AppBlade.Log( "Service Connected");
	}

	public void onServiceDisconnected(ComponentName name) {
		// Do nothing. We only need the bind count at the moment.
		AppBlade.Log( "Service Disconnected");

	}


}
