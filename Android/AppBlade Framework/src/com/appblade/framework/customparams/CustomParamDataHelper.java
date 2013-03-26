package com.appblade.framework.customparams;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

import org.json.JSONException;
import org.json.JSONObject;

import com.appblade.framework.AppBlade;

import android.content.Context;
import android.util.Log;

/**
 * Helper functions for storing and loading custom parameters and adding them to HttpRequests.
 * @author andrew.tremblay@raizlabs
 */
public class CustomParamDataHelper {
	//I/O RELATED
	//Just store the json straight to file
	public static String customParamsFileName = "custom_params.json";
	//API RELATED
	public static String customParamsIndexMIMEType = "text/json"; 

	
	/**
	 * The resource location of the share customParams file. Currently stored as JSON.
	 * @return a String of the location of the customParams file.
	 */
	public static String jsonFileURI()
	{
		return String.format("%s%s%s", AppBlade.customParamsDir, "/", customParamsFileName);
	}
	
	
	/**
	 * Initializes a new CustomParamData and calls refreshFromStoredData() on it.		
	 * @return a new CustomParamData object with all stored values.
	 */
	public static synchronized CustomParamData getCurrentCustomParams()
	{
		//don't need to do much currently since all it is is a JSON object, 
		//other features may include behaviors we'll need in separate behavior, ttl for example
		CustomParamData dataToRet = new CustomParamData();
		dataToRet.refreshFromStoredData();
		return dataToRet;
	}

	// JSON Parsing
	/**
	 * Parses a file at the given location, returns a JSONObject. Assumes valid read/write permissions.
	 * @param customParamsResourceLocation String URL of the file in json format to read.
	 * @return a new JSONObject with all stored values. Or an empty JSONObject
	 */
	public static synchronized JSONObject getCustomParamsAsJSON(String customParamsResourceLocation ){
        JSONObject json = new JSONObject();
        String jsonTxt = null;
		BufferedReader buffreader = null;
		try {
			buffreader = new BufferedReader(new FileReader(customParamsResourceLocation));
			String line;
			StringBuilder text = new StringBuilder();
			try {
				while (( line = buffreader.readLine()) != null) {
				      text.append(line);
				}
			} catch (IOException e) {
				return null;
			}
			jsonTxt = text.toString();
		} catch (FileNotFoundException e1) {
			e1.printStackTrace();
		}finally
		{
			try {
				if(buffreader != null)
				{
					buffreader.close();
				}
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

		Log.v(AppBlade.LogTag, "Text in "+customParamsFileName+": "+ jsonTxt);
        
        if(jsonTxt != null){
			try {
				json = new JSONObject( jsonTxt );
			} catch (JSONException e) {
				e.printStackTrace();
			}        
        }
        else
        {
        	Log.v(AppBlade.LogTag, "Custom Parameters have not yet been inititalized.");
        }
        return json;
	}

	/**
	 * Helper method, loads JSONObject from default customParams file location.		
	 * @return a new JSONObject with all stored values in the default file location.
	 * @see #jsonFileURI()
	 */
	public static synchronized JSONObject getCustomParamsAsJSON(){
		return getCustomParamsAsJSON(jsonFileURI() );
	}
	
	/**
	 * Buffer-writes the given custom parameters to the default JSON file location relative to context. .
	 * @param context Unused. but useful for a callback/making sure the write location is still valid.
	 * @param customParams the JSON values to write to the default JSON file location.
	 * @see #jsonFileURI()
	 */
	public static synchronized void storeCurrentCustomParams(Context context, CustomParamData customParams)
	{
		String stringJSON = customParams.toString();
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
	        	Log.v(AppBlade.LogTag, "customParams file does not exist yet. creating Sessions file.");
	    		someFile.createNewFile();
	    	}
	    }catch (IOException ex) {
	    	Log.w(AppBlade.LogTag, "Error making customParams file", ex);
	    }
	    
        try {
            //open the buffered writer
	    	Log.v(AppBlade.LogTag, "open the buffered writer to "+ jsonFileURI());
        	BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(jsonFileURI()));
    		Log.v(AppBlade.LogTag, "writing customParams "+stringJSON);
            bufferedWriter.write(stringJSON);
	        //Close the BufferedWriter
			bufferedWriter.flush();
			bufferedWriter.close();
        } catch (FileNotFoundException ex) {
	    	Log.w(AppBlade.LogTag, "Error finding customParams file", ex);
        } catch (IOException ex) {
	    	Log.w(AppBlade.LogTag, "IO Error making customParams file", ex);
        }
	}
}
