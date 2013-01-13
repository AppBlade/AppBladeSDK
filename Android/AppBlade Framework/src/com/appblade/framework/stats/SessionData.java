package com.appblade.framework.stats;

import java.sql.Timestamp;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Comparator;
import java.util.Date;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * object representing a single Session.
 * Contains date a session ended and date a session began. All other data about the app and the device is included in the headers.
 * Note that the custom parameters ({@link com.appblade.framework.customparams.CustomParamData}) are not included in Session calls. 
 * @author andrew.tremblay@raizlabs
 */
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
	
	//*****************storage input
	/**
	 * @param storedString String formatted as "[startTime in (yyyy-MM-dd HH:mm:ss.SSS)], [endTime in (yyyy-MM-dd HH:mm:ss.SSS)]"
	 */
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

	
	//*****************FILE I/O
	/**
	 * Gets the current object as a formatted string for storage. (start and end time stored as timestamps)
	 * @return String formatted as "[startTime as (yyyy-MM-dd HH:mm:ss.SSS)], [endTime as (yyyy-MM-dd HH:mm:ss.SSS)]"
	 */
	public String sessionAsStoredString(){ 
		//should match what constructor SessionData(String storedString) needs for parsing
	    java.sql.Timestamp timeStampBegan = new 
	    		 Timestamp(this.began.getTime());
	    java.sql.Timestamp timeStampEnded = new 
	    		 Timestamp(this.ended.getTime());
	    


		return timeStampBegan.toString() + storageDividerKey + timeStampEnded.toString();
	}
		
	/**
	 * Compare method so we can confirm another object is essentially the same.
	 * internally compares both start and end times, if they are both the same, theobjects are equal.
	 */
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
	
	
	//*****************API REALATED
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
	/**
	 * Formats the current objects as JSON
	 * @return JSONObject containing <code>started_at</code> and <code>ended_at</code> values.
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
