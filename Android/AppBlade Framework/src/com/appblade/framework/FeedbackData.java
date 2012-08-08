package com.appblade.framework;

import java.util.Hashtable;

import android.graphics.Bitmap;

public class FeedbackData {
	
	public static final String NOTES_KEY 			= "notes";
	public static final String CONSOLE_KEY 			= "console";
	public static final String SCREENSHOT_NAME_KEY 	= "screenshot_name";
	public static final String PARAMS_KEY 			= "params";
	
	public String Notes;
	public String Console;
	public Bitmap Screenshot;
	public String ScreenshotName;
	public Hashtable<String, String> CustomParams;
	public String SavedName;
}
