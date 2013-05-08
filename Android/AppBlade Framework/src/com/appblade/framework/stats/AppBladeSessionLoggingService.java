package com.appblade.framework.stats;

import com.appblade.framework.AppBlade;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.IBinder;


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

		AppBlade.Log( "Service contructed");
	}
	
		
	@Override
	public void onCreate() {
		AppBlade.Log( "Service created");
	}
	
	
	@Override
	public void onStart(Intent intent, int startid) {
		AppBlade.Log( "Service started");
	}


	
	@Override
	public void onDestroy() {
		AppBlade.Log( "Service ended");
	}
	
	@Override
	public IBinder onBind(Intent intent) {
		AppBlade.Log( "Service onBind");
		AppBlade.startSession(this);
		
		return null; //we don't need an IBinder
	}

	@Override
	public boolean onUnbind (Intent intent) {
		AppBlade.Log( "Service unBind");
		AppBlade.endSession(this);

		return false; // we don't need onRebind
	}
}
