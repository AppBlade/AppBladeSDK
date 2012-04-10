package com.appblade.framework;

import java.lang.Thread.UncaughtExceptionHandler;

public class AppBladeExceptionHandler implements UncaughtExceptionHandler {
	
	private UncaughtExceptionHandler defaultHandler;

	public AppBladeExceptionHandler(UncaughtExceptionHandler defaultHandler) {
		this.defaultHandler = defaultHandler;
	}

	public void uncaughtException(Thread thread, Throwable ex) {
		AppBlade.notify(ex);
		defaultHandler.uncaughtException(thread, ex);
	}

}
