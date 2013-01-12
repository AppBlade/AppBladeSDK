package com.appblade.framework;

import java.lang.Thread.UncaughtExceptionHandler;

/**
 * AppBladeExceptionHandler
 * AppBlade's default UncaughtExceptionHandler.
 *  Same as a regular ExceptionHandler, but calls {@link AppBlade.notify(Throwable)} to store and send the exception to AppBlade on uncaughtException(Thread thread, Throwable ex)
 * @author andrew.tremblay@raizlabs.com
 */		
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
