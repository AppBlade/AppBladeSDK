package com.appblade.framework.stats;

import java.sql.Timestamp;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Comparator;
import java.util.Date;

import org.json.JSONException;
import org.json.JSONObject;

import android.text.format.DateFormat;


public class SessionData implements Comparator<Object> {
	public static String sessionBeganKey = "started_at";
	public static String sessionEndedKey = "ended_at";
	public static String storageDividerKey = ", ";
	
	public Date began;
	public Date ended;
	
	
	public SessionData(){
		this.began = new Date();
		this.ended = null;
	}
	
	public SessionData(Date _began, Date _ended){
		this.began = _began;
		this.ended = _ended;
	}
	
	//storage in/out
	public SessionData(String storedString){
		//storedString should match the output of sessionAsStoredString
        // Copy the content into the array
        String[] tokens = storedString.split(storageDividerKey);
        SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS");
		try {
			this.began = format.parse(tokens[0]);
			this.ended = format.parse(tokens[1]);
		} catch (ParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			this.began = new Date();
			this.ended = new Date();
		}
	}

	
	//FILE I/O
	public String sessionAsStoredString(){ 
		//should match what constructor SessionData(String storedString) needs for parsing
	    java.sql.Timestamp timeStampBegan = new 
	    		 Timestamp(this.began.getTime());
	    java.sql.Timestamp timeStampEnded = new 
	    		 Timestamp(this.ended.getTime());
	    


		return timeStampBegan.toString() + storageDividerKey + timeStampEnded.toString();
	}
		
	public int compare(Object o1, Object o2)
	{
		SessionData session1 = (SessionData)o1;
		SessionData session2 = (SessionData)o2;
		if( session1 != null && session2 != null 
				&& session1.began.equals(session2.began) && session1.ended.equals(session2.ended) )
		{
			return 0;
		}
		return 1;
	}	
	
	
	//API REALATED
	/*
	 * 	{	
	 * 		"device_id": "8989ffBB", 
	 * 		"project_id": "87FF98", 
	 * 		"executable_uuid":"0123013", 
	 * 		"sessions" : [
	 * ************************** THIS PART >>>
	 * 		{
	 * 			"started_at": "2007-03-01T13:00:00Z", 
	 * 			"ended_at": "2007-03-01T13:04:30Z"
	 * 		}
	 * **************************  << THAT PART
	 * **************************  POSSIBLY MULTIPLE ONES
	 * 		]
	 * 	}
	 */
	public JSONObject formattedSessionAsJSON()
	{
		JSONObject json = new JSONObject();
	    java.sql.Timestamp timeStampBegan = new 
	    		 Timestamp(this.began.getTime());
	    java.sql.Timestamp timeStampEnded = new 
	    		 Timestamp(this.ended.getTime());
		
		try {
			json.put("started_at",timeStampBegan);
			json.put("ended_at", timeStampEnded); 
		} catch (JSONException e) {
			e.printStackTrace();
		} 
		return json;
	}

	


}
