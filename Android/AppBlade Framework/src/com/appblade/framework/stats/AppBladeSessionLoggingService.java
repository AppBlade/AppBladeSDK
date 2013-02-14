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
		mContext = null;
		appbladeSessionServiceConnection = new AppBladeSessionServiceConnection();
	}
	
	public AppBladeSessionLoggingService(Context context)
	{
        super();
		mContext = context;
		appbladeSessionServiceConnection = new AppBladeSessionServiceConnection();

		Log.d(AppBlade.LogTag, "Service contructed");
	}
	
		
	@Override
	public void onCreate() {
		Log.d(AppBlade.LogTag, "Service created");
	}
	
	
	@Override
	public void onStart(Intent intent, int startid) {
		Log.d(AppBlade.LogTag, "Service started");
	}


	
	@Override
	public void onDestroy() {
		Log.d(AppBlade.LogTag, "Service ended");
	}
	
	@Override
	public IBinder onBind(Intent intent) {
		Log.d(AppBlade.LogTag, "Service onBind");
		if(mContext != null){
			Log.d(AppBlade.LogTag, "Service starting session");
			AppBlade.startSession(mContext);
		}

		return null; //we don't need an IBinder
	}

	@Override
	public boolean onUnbind (Intent intent) {
		Log.d(AppBlade.LogTag, "Service unBind");
		if(mContext != null){
			Log.d(AppBlade.LogTag, "Service ending session");
			AppBlade.endSession(mContext);
		}
		
		return false; // we don't need onRebind
	}
}
