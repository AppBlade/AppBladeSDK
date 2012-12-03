package com.appblade.framework.stats;

import java.util.Date;
import java.util.Hashtable;



public class SessionData implements java.io.Serializable {
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	public static String sessionBeganKey = "started_at";
	public static String sessionEndedKey = "ended_at";
	
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
	 * 		]
	 * 	}
	 */
	public Hashtable<String, String> formattedSession()
	{
		Hashtable<String, String> table = new Hashtable<String, String>();
		table.put(sessionBeganKey, began.toGMTString());
		table.put(sessionEndedKey, ended.toGMTString());
		return table;
	}
}
