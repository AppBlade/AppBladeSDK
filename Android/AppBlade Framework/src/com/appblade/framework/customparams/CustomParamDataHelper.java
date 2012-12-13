package com.appblade.framework.customparams;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
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
	public static String customParamsFileName = "custom_params.json";
	//API RELATED
	public static String customParamsIndexMIMEType = "text/json"; 

	
	public static String jsonFileURI()
	{
		return String.format("%s/%s", AppBlade.customParamsDir, customParamsFileName);
	}
	
	
	public static CustomParamData getCurrentCustomParams()
	{
		//don't need to do much currently since all it is is a JSON object, 
		//other features may include behaviors we'll need in separate behavior, ttl for example
		CustomParamData dataToRet = new CustomParamData();
		dataToRet.refreshFromStoredData();
		return dataToRet;
	}

	// JSON Parsing
	public static JSONObject getCustomParamsAsJSON(String customParamsResourceLocation ){
        JSONObject json = new JSONObject();
        String jsonTxt = null;
		BufferedReader buffreader;
		try {
			buffreader = new BufferedReader(new FileReader(customParamsResourceLocation));
			String line;
			StringBuilder text = new StringBuilder();
			try {
				while (( line = buffreader.readLine()) != null) {
				      text.append(line);
				      text.append(' ');
				}
			} catch (IOException e) {
				return null;
			}
			jsonTxt = text.toString();
		} catch (FileNotFoundException e1) {
			e1.printStackTrace();
		}

		Log.d(AppBlade.LogTag, "Text in cutomparams.json: "+ jsonTxt);
        
        if(jsonTxt != null){
			try {
				json = new JSONObject( jsonTxt );
			} catch (JSONException e) {
				e.printStackTrace();
			}        
        }
        else
        {
        	Log.d(AppBlade.LogTag, "Custom Parameters have not yet been inititalized.");
        }
        return json;
	}

	
	//CAREFUL: for crashes only not sure about AppBlade.rootDir
	public static JSONObject getCustomParamsAsJSON(){
		return getCustomParamsAsJSON(jsonFileURI() );
	}
	
	public static void storeCurrentCustomParams(Context context, CustomParamData customParams)
	{
		String stringJSON = ((JSONObject) customParams).toString();
		//confirm file existence
	    try{
	    	final File parent = new File(AppBlade.customParamsDir);
	    	if(!parent.exists())
	    	{
	    		System.err.println("Parent directories do not exist");
		    	if (!parent.mkdirs())
		    	{
		    	   System.err.println("Could not create parent directories");
		    	}
	    	}
	    	final File someFile = new File(AppBlade.customParamsDir, customParamsFileName);
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
	    	Log.d(AppBlade.LogTag, "open the buffered writer to "+ jsonFileURI());
        	BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(jsonFileURI()));
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
