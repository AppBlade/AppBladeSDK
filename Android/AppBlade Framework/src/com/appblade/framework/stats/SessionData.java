package com.appblade.framework.stats;

import java.sql.Timestamp;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Comparator;
import java.util.Date;
import java.util.Locale;

import org.json.JSONException;
import org.json.JSONObject;

import com.appblade.framework.utils.StringUtils;

/**
 * object representing a single Session.
 * Contains date a session ended and date a session began. All other data about the app and the device is included in the headers.
 * Note that the custom parameters ({@link com.appblade.framework.customparams.CustomParamData}) are not included in Session calls. 
 * @author andrew.tremblay@raizlabs
 */
public class SessionData implements Comparator<Object> {
	public static String sessionBeganKey = "started_at";
	public static String sessionEndedKey = "ended_at";
	public static String sessionLocationLatKey = "latitude";
	public static String sessionLocationLongKey = "longitude";
	public static String sessionCustomParamsKey = "custom_params";

	
	public static String storageDividerKey = ", ";
	
	public Date began;
	public Date ended;
	public String latitude;
	public String longitude;
	public JSONObject customParams;
	
	
	public SessionData(){
		this.began = new Date();
		this.ended = null;
	}
	
	public SessionData(Date _began, Date _ended, String _latitude, String _longitude, JSONObject _customParams){
		this.began = _began;
		this.ended = _ended;
		this.latitude = _latitude;
		this.longitude = _longitude;
		this.customParams = _customParams;
	}

	
	//*****************   Constructor for storage handling
	/**
	 * @param storedString String formatted as "[startTime in (yyyy-MM-dd HH:mm:ss.SSS)], [endTime in (yyyy-MM-dd HH:mm:ss.SSS)], [latitude], [longitude] (optional but paired)
	 */
	public SessionData(String storedString){
		//storedString should match the output of sessionAsStoredString
        // Copy the content into the array
        String[] tokens = storedString.split(storageDividerKey);
        SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US);
		try {
			if(tokens.length > 2){
				this.began = format.parse(tokens[0]);
				this.ended = format.parse(tokens[1]);
				this.latitude = tokens[2];
				this.longitude = tokens[3];
				this.customParams = StringUtils.parseStringToJSONObject(tokens[4]);
			}else if(tokens.length == 2){
				this.began = format.parse(tokens[0]);
				this.ended = format.parse(tokens[1]);
		    	this.latitude = "nothingStored";
		    	this.longitude = "nothingStored";
		    	this.customParams = new JSONObject();
			}else{
				this.began = new Date();
				this.ended = new Date();
			}
		} catch (ParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			this.began = new Date();
			this.ended = new Date();
		}
	}

	
	//*****************FILE I/O RELATED
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
	    
	    if(this.latitude == null || this.longitude == null)
		{
	    	this.latitude = "nothingToStore";
	    	this.longitude = "nothingToStore";
	    }
	    
	    String toRet = timeStampBegan.toString() + storageDividerKey + timeStampEnded.toString();
	    toRet = toRet + storageDividerKey + this.latitude + storageDividerKey + this.longitude;
	    
	    
	    if(this.customParams == null)
	    {
	    	this.customParams = new JSONObject();
	    }
	    
	    toRet = toRet + storageDividerKey + this.customParams.toString(); 
	    
		return toRet;
	}
		
	public boolean hasLocation()
	{
		return !StringUtils.isNullOrEmpty(this.latitude) && !StringUtils.isNullOrEmpty(this.longitude);
	}
	
	
	//*****************API RELATED
	/*
	 * 	{	
	 * 		"device_id": "8989ffBB", 
	 * 		"project_id": "87FF98", 
	 * 		"executable_uuid":"0123013", 
	 * 		"sessions" : [
	 * ************************** THIS PART >>>
	 * 		{
	 * 			<sessionBeganKey>: 	"2007-03-01T13:00:00Z", 
	 * 			<sessionEndedKey>: 	"2007-03-01T13:04:30Z",
	 * 			<sessionLocationLatKey>: 	"123123412", 
	 * 			<sessionLocationLongKey>:	"5543254234",
	 * 			<sessionCustomParamsKey>: {  whatever custom_params we had when this session was ended  }
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
			json.put(sessionBeganKey,timeStampBegan);
			json.put(sessionEndedKey, timeStampEnded); 
			json.put(sessionLocationLatKey, this.latitude);
			json.put(sessionLocationLongKey, this.longitude); 		    	
			json.put(sessionCustomParamsKey, this.customParams); 		    	
		} catch (JSONException e) {
			e.printStackTrace();
		} 
		return json;
	}

	

	
	/**
	 * Compare method so we can confirm another object is essentially the same. <br>
	 * Internally compares both start and end times, if they are both the same, the objects are considered equal.<br>
	 * If not the same, the one with the earlier [began] is first.<br>
	 * If both begans are equal, the one with the earlier [ended] is first.
	 * Does not check for optional variables. (For efficiency)
	 */
	public int compare(Object o1, Object o2)
	{
		int compareValue;
		SessionData session1 = (SessionData)o1;
		SessionData session2 = (SessionData)o2;
		if( session1 != null && session2 != null)
		{
			if(session1.began.equals(session2.began)){
				compareValue = session1.ended.compareTo(session2.ended);
			}else{
				compareValue = session1.began.compareTo(session2.began);
			}
		}else{
			compareValue = 0; //nulls equal each other
		}
		return compareValue;
	}	
}
