package com.appblade.framework.crashreporting;

/**
 * Class for handling the data of a single Crash Report<br>
 * Currently only contains the Throwable of the class, which would be treated as the backtrace on AppBlade. <br>
 *  could also eventually include output from logcat.  <br>
 * TODO: save a copy of the custom_params json file at moment of crash, report that instead of the file that the user's always changing. 
 * @author andrew.tremblay@raizlabs
 */
public class CrashReportData {
	public Throwable exception;
	
	public CrashReportData(Throwable e) {
		exception = e;
	}

}
