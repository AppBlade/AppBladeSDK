package com.appblade.framework.customparams;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;

import org.json.JSONException;
import org.json.JSONObject;

import com.appblade.framework.AppBlade;
import com.appblade.framework.utils.StringUtils;

import android.content.Context;
import android.util.Log;

public class CustomParamDataHelper {
	//I/O RELATED
	//Just store the json straight to file
	public static String customParamsFolder = "/appBlade"; 
	public static String customParamsFileName = "customParams.json";
	//API RELATED
	public static String customParamsIndexMIMEType = "text/json"; 

	public static String jsonFileURL(Context context)
	{
		return customParamsFolder;
	}
	public static String jsonFileURI(Context context)
	{
		return jsonFileURL(context)+"/"+customParamsFileName;
	}
	
	
	public static CustomParamData getCurrentCustomParams(Context context)
	{
		//don't need to do much currently since all it is is a JSON object, 
		//other features may include behaviors we'll need in separate behavior, ttl for example
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
	
	
	public static void storeCurrentCustomParams(Context context, CustomParamData customParams)
	{
		String stringJSON = ((JSONObject) customParams).toString();
		//confirm file existence
	    try{
	    	final File parent = new File(jsonFileURL(context));
	    	if(!parent.exists())
	    	{
	    		System.err.println("Parent directories do not exist");
		    	if (!parent.mkdirs())
		    	{
		    	   System.err.println("Could not create parent directories");
		    	}
	    	}
	    	final File someFile = new File(jsonFileURL(context), customParamsFileName);
	    	if(!someFile.exists()){
	        	Log.d(AppBlade.LogTag, "customParams file does not exist yet. creating Sessions file.");
	    		someFile.createNewFile();
	    	}
	    }catch (IOException ex) {
	    	Log.d(AppBlade.LogTag, "Error making customParams file");
	    	ex.printStackTrace();
	    }
	    
        try {
            //open the buffered writer
        	BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(customParamsFileName));
    		Log.d(AppBlade.LogTag, "writing customParams "+stringJSON);
            bufferedWriter.write(stringJSON);
	        //Close the BufferedWriter
			bufferedWriter.flush();
			bufferedWriter.close();
        } catch (FileNotFoundException ex) {
            ex.printStackTrace();
        } catch (IOException ex) {
            ex.printStackTrace();
        }
	}
}
