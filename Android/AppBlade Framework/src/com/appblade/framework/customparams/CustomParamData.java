package com.appblade.framework.customparams;

import java.util.Iterator;

import org.json.JSONException;
import org.json.JSONObject;

import com.appblade.framework.AppBlade;

import android.content.Context;
import android.util.Log;

public class CustomParamData extends JSONObject {
	//It feels empty up here without a basic constructor
	public CustomParamData(){
		super();
	}
	
	//initializing with a context or JSONObject will kick off a load for all existing values
	public CustomParamData(JSONObject jsonObject){
		super();
		Iterator<?> keysToAdd = jsonObject.keys(); 
		while(keysToAdd.hasNext()){
            Object nextKeyObj = keysToAdd.next();
            if(nextKeyObj instanceof String)
            {
				String nextKey = (String) keysToAdd.next();
				try {
					this.put(nextKey, jsonObject.get(nextKey));
				} catch (JSONException e) {
					e.printStackTrace();
				}
            }
		}
	}


	public CustomParamData(Context context){
		super();
		this.refreshFromStoredData();
	}

	
	//helper functions for parameter data
	public void storeCurrentData(Context context)
	{
		CustomParamDataHelper.storeCurrentCustomParams(context, this);
	}
	
	public CustomParamData refreshFromStoredData()
	{
		JSONObject latestParams = CustomParamDataHelper.getCustomParamsAsJSON();
		//clobber the keys, replace with latest params
		Iterator<?> keysToRemove = this.keys();
		Iterator<?> keysToAdd = latestParams.keys(); 
		while(keysToRemove.hasNext()){
            Object nextKeyObj = keysToAdd.next();
            if(nextKeyObj instanceof String)
            {
				String nextKey = (String) keysToRemove.next();
				this.remove(nextKey);
            }
		}
		while(keysToAdd.hasNext()){
			try {
	            Object nextKeyObj = keysToAdd.next();
	            if(nextKeyObj instanceof String)
	            {
	    			String nextKey = (String) keysToAdd.next();	            	
					this.put(nextKey, latestParams.get(nextKey));
	            }
			} catch (JSONException e) {
				e.printStackTrace();
			}
		}
		return this; //return new self
	}
}
