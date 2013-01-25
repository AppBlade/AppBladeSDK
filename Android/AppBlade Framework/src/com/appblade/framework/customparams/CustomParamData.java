package com.appblade.framework.customparams;

import java.util.Iterator;
import org.json.JSONException;
import org.json.JSONObject;
import android.content.Context;

/**
 * Class for handling the access of current Custom Parameters.
 * <p>Currently custom parameters are shared between all API calls, to avoid sending custom parameters when not required they should be cleared after each call. 
 * @author andrew.tremblay@raizlabs
 */
public class CustomParamData extends JSONObject {
	//It feels empty up here without a basic constructor
	public CustomParamData(){
		super();
	}
	
	/**
	 * Initializing with a JSONObject copy the values of that JSONObject into the 
	 * @param jsonObject the data you want to copy into CustomParamData object
	 */
	public CustomParamData(JSONObject jsonObject){
		super();
		if(jsonObject != null){
			Iterator<?> keysToAdd = jsonObject.keys(); 
			while(keysToAdd.hasNext()){
	            Object nextKeyObj = keysToAdd.next();
	            if(nextKeyObj instanceof String)
	            {
					String nextKey = (String) nextKeyObj;
					try {
						this.put(nextKey, jsonObject.get(nextKey));
					} catch (JSONException e) {
						e.printStackTrace();
					}
	            }
			}
		}
	}


	/**
	 * Initializing with a context or JSONObject will kick off a load for all existing values
	 * @param context Context for the stored data location.
	 */
	public CustomParamData(Context context){
		super();
		this.refreshFromStoredData();
	}

	
	//helper functions for parameter data
	/**
	 * Stores data of the object in the given context
	 * @param context Context for the stored data location.
	 */
	public synchronized void storeCurrentData(Context context)
	{
		CustomParamDataHelper.storeCurrentCustomParams(context, this);
	}
	
	/**
	 * Removes all existing keys and values and loads the stored variables.
	 * @see #com.appblade.framework.customparams.CustomParamDataHelper.getCustomParamsAsJSON()
	 * @return a reference to itself with the new values and keys.
	 */
	public synchronized CustomParamData refreshFromStoredData()
	{
		JSONObject latestParams = CustomParamDataHelper.getCustomParamsAsJSON();
		//clobber the keys, replace with latest params
		Iterator<?> keysToRemove = this.keys();
		Iterator<?> keysToAdd = latestParams.keys(); 
		while(keysToRemove.hasNext()){
            Object nextKeyObj = keysToAdd.next();
            if(nextKeyObj instanceof String)
            {
				String nextKey = (String) nextKeyObj;
				this.remove(nextKey);
            }
		}
		while(keysToAdd.hasNext()){
            Object nextKeyObj = keysToAdd.next();
            if(nextKeyObj instanceof String)
            {
            	String nextKey = (String) nextKeyObj;
    			try {
    				this.put(nextKey, latestParams.get(nextKey));
    			} catch (JSONException e) {
    				e.printStackTrace();
    			}
            }
		}
		return this; //return new self
	}
}
