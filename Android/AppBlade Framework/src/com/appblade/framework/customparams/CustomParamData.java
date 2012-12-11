package com.appblade.framework.customparams;

import java.util.Iterator;

import org.json.JSONObject;

import android.content.Context;

public class CustomParamData extends JSONObject {
	//It feels empty up here without a constructor
	public CustomParamData(){
		super();
	}
	
	//helper functions for parameter data
	public void storeCurrentData()
	{
		
	}
	
	public CustomParamData refreshFromStoredData(Context context)
	{
		//clobber the keys
		Iterator keysToRemove = this.keys();
		
		
		return CustomParamDataHelper.getCurrentCustomParams(context);
	}
}
