package com.appblade.framework.customparams;

import java.io.InputStream;

import org.json.JSONException;
import org.json.JSONObject;

import com.appblade.framework.utils.StringUtils;

import android.content.Context;

public class CustomParamDataHelper {
	//I/O RELATED
	public static String customParamsFolder = "/appBlade"; 
	public static String customParamsFileName = "customParams.txt";
	//API RELATED
	public static String customParamsIndexMIMEType = "text/json"; 

	
	//Just store the json straight to file
	public static String jsonFileURL(Context context)
	{
		return customParamsFileName;
	}
	
	
	public static CustomParamData getCurrentCustomParams(Context context)
	{
		//don't need to do much currently since all it is is a JSON object
		return (CustomParamData)getCustomParamsAsJSON(context);
	}
	
	// JSON Parsing
	public static JSONObject getCustomParamsAsJSON(Context context){
        InputStream is = CustomParamDataHelper.class.getResourceAsStream( jsonFileURL(context) );
        String jsonTxt = StringUtils.readStream( is );

        JSONObject json = null;
		try {
			json = new JSONObject( jsonTxt );
		} catch (JSONException e) {
			e.printStackTrace();
		}        
        return json;
	}
	
}
