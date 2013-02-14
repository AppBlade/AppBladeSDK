package com.appblade.framework.stats;

import com.appblade.framework.AppBlade;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.IBinder;

public class AppBladeSessionLoggingService extends Service {
	Context mContext;
	
	public AppBladeSessionLoggingService(Context context)
	{
		mContext = context;
	}
	
	@Override
	public IBinder onBind(Intent intent) {
		AppBlade.startSession(mContext);
		return null; //we don't need an IBinder
	}

	@Override
	public boolean onUnbind (Intent intent) {
		AppBlade.endSession(mContext);
		return false; // we don't need onRebind
	}
}
