package com.appblade.framework.crashreporting;

public class CrashReportData {
	public Throwable exception;
	
	public CrashReportData(Throwable e) {
		exception = e;
	}

}
