package com.appblade.framework.customparams;

import java.util.Iterator;

import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;

public class CustomParamData extends JSONObject {
	//It feels empty up here without a constructor
	public CustomParamData(){
		super();
	}
	
	//helper functions for parameter data
	public void storeCurrentData(Context context)
	{
		CustomParamDataHelper.storeCurrentCustomParams(context, this);
	}
	
	@SuppressWarnings("unchecked")
	public CustomParamData refreshFromStoredData(Context context)
	{
		CustomParamData latestParams = CustomParamDataHelper.getCurrentCustomParams(context);
		//clobber the keys, replace with latest params
		Iterator<String> keysToRemove = this.keys();
		Iterator<String> keysToAdd = latestParams.keys(); 
		while(keysToRemove.hasNext()){
			String nextKey = (String) keysToRemove.next();
			this.remove(nextKey);
		}
		while(keysToAdd.hasNext()){
			String nextKey = (String) keysToAdd.next();
			try {
				this.put(nextKey, latestParams.get(nextKey));
			} catch (JSONException e) {
				e.printStackTrace();
			}
		}
		return this; //return new self
	}
}
