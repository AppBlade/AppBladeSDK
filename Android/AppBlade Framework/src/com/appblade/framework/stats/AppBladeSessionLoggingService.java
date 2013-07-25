package com.appblade.framework.stats;

import com.appblade.framework.AppBlade;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;

public class AppBladeSessionLoggingService extends Service {
	public Context mContext;
	public AppBladeSessionServiceConnection appbladeSessionServiceConnection;
	
	public AppBladeSessionLoggingService()
	{
        super();
		appbladeSessionServiceConnection = new AppBladeSessionServiceConnection();
	}
	
	public AppBladeSessionLoggingService(Context context)
	{
        super();
		appbladeSessionServiceConnection = new AppBladeSessionServiceConnection();

		Log.v(AppBlade.LogTag, "Service contructed");
	}
	
		
	@Override
	public void onCreate() {
		Log.v(AppBlade.LogTag, "Service created");
	}
	
	
	@Override
	public void onStart(Intent intent, int startid) {
		Log.v(AppBlade.LogTag, "Service started");
	}


	
	@Override
	public void onDestroy() {
		Log.v(AppBlade.LogTag, "Service ended");
	}
	
	@Override
	public IBinder onBind(Intent intent) {
		Log.v(AppBlade.LogTag, "Service onBind");
		AppBlade.startSession(this);
		
		return null; //we don't need an IBinder
	}

	@Override
	public boolean onUnbind (Intent intent) {
		Log.v(AppBlade.LogTag, "Service unBind");
		AppBlade.endSession(this);

		return false; // we don't need onRebind
	}
}
