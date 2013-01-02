package com.appblade.framework.crashreporting;

public class CrashReportData {
	public Throwable exception;
	//TODO: save a copy of the custom_params json file at moment of crash, report that instead of the file that the user's always changing. 
	
	public CrashReportData(Throwable e) {
		exception = e;
	}

}
