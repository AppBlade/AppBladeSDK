package com.appblade.framework.stats;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URI;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPut;
import org.apache.http.entity.mime.HttpMultipartMode;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.entity.mime.content.ContentBody;
import org.apache.http.entity.mime.content.StringBody;
import org.json.JSONArray;
import org.json.JSONObject;

import com.appblade.framework.AppBlade;
import com.appblade.framework.WebServiceHelper;
import com.appblade.framework.WebServiceHelper.HttpMethod;
import com.appblade.framework.customparams.CustomParamDataHelper;
import com.appblade.framework.utils.HttpClientProvider;
import com.appblade.framework.utils.HttpUtils;
import com.appblade.framework.utils.IOUtils;
import com.appblade.framework.utils.StringUtils;
import com.appblade.framework.utils.SystemUtils;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

/**
 * Helper class for session reporting functionality.
 * Helps store and send SessionData objects.
 * @author andrew.tremblay@raizlabs
 * @see SessionData
 */
public class SessionHelper {
	//I/O RELATED
	public static String sessionsIndexFileName = "index.txt";
	//API RELATED
	public static String sessionsIndexMIMEType = "text/json"; 

	//LOGIC RELATED
	public static boolean SUCCESS = true; 
	public static boolean FAILURE = false; 

	
	
	//*****************Session Logging 

	/**
	 * Starts a session by reinitializing the curentSession object in the AppBLade singleton.
	 * @param context Context where we will be storing the session data.
	 */
	public static boolean startSession(Context context){
		Log.v(AppBlade.LogTag, "Starting Session");
		AppBlade.currentSession = new SessionData();
		return SUCCESS;
	}
	 
	/**
	 * Ends a session and kicks off a post request.
	 * @param context Context where we will be storing the session data.
	 */
	public static boolean endSession(Context context){
		Log.v(AppBlade.LogTag, "Ending Session");
		if(AppBlade.currentSession != null){
			AppBlade.currentSession.ended = new Date();
						
			AppBlade.currentSession.customParams = CustomParamDataHelper.getCustomParamsAsJSON();
			
			SessionData sessionToStore = new SessionData(AppBlade.currentSession.began, AppBlade.currentSession.ended, AppBlade.currentSession.customParams);
			insertSessionData(context, sessionToStore);
			AppBlade.currentSession = null;
			return SUCCESS;
		}else
		{
			return FAILURE;
		}
	}
	
	/**
	 * Helper function to bind to session service. Better for tracking sessions across the life of the application.
	 * @param activity The Activity to bind to the service.
	 */
	public static boolean bindToSessionService(Activity activity)
	{
		if(AppBlade.sessionLoggingService == null){
			AppBlade.sessionLoggingService = new AppBladeSessionLoggingService(activity);
		}

		if(activity != null && AppBlade.sessionLoggingService.appbladeSessionServiceConnection != null){				
			try
			{
				Intent bindIntent = new Intent();
				bindIntent.setAction("com.appblade.framework.stats.AppBladeSessionLoggingService");
			    boolean succeeded = activity.bindService(bindIntent, AppBlade.sessionLoggingService.appbladeSessionServiceConnection, Context.BIND_AUTO_CREATE);		
			    if(succeeded)
			    {
					Log.v(AppBlade.LogTag, "Success binding the Session.");
					return SUCCESS;
			    }
			    else
			    {
					Log.v(AppBlade.LogTag, "Error binding the Session. Make sure the SessionService is properly in your manifest.");
					return FAILURE;
			    }

			}catch(SecurityException e){
				Log.e(AppBlade.LogTag, "Error binding to Session Logging service: " + StringUtils.exceptionInfo(e));
				e.printStackTrace();
				return FAILURE;
			}
		}
		else
		{
			Log.e(AppBlade.LogTag, "Error unbinding activity. Possible null value.");
			return FAILURE;
		}	
	}
	
	/**
	 * Helper function to unbind from session service. Better for tracking sessions across the life of the application.
	 * @param activity The Activity to bind to the service.
	 */
	public static boolean unbindFromSessionService(Activity activity)
	{
		if(AppBlade.sessionLoggingService != null && activity != null && AppBlade.sessionLoggingService.appbladeSessionServiceConnection != null){
			activity.unbindService(AppBlade.sessionLoggingService.appbladeSessionServiceConnection);
			return SUCCESS;
		}
		else
		{
			Log.e(AppBlade.LogTag, "Error unbinding activity. Possible null value.");
			return FAILURE;
		}
	}

	
	

	
	//*****************API RELATED FUNCTIONS
	/**
	 * Posts the given session to AppBlade, stores it for later on failure. 
	 * @param data SessionData to post.
	 * @return status code of the response from the server (2** = success) or -10000 if an error was thrown.
	 */
	public static int postSession(SessionData data) {
		ArrayList<SessionData> sessionsList = new ArrayList<SessionData>();
		sessionsList.add(data);
		return postSessions(sessionsList);
	}

	/**
	 * Posts all of the given sessions to AppBlade, stores them for later on failure. 
	 * @param sessionsList List of SessionData we want to send to AppBLade
	 * @return status code of the response from the server
	 */
	static int postSessions(List<SessionData> sessionsList) {
		HttpClient client = HttpClientProvider.newInstance(SystemUtils.UserAgent);
		String sharedBoundary = AppBlade.genDynamicBoundary();
		try
		{
			String urlPath = String.format(WebServiceHelper.ServicePathSessionFormat, AppBlade.appInfo.AppId, AppBlade.appInfo.Ext);
			String url = WebServiceHelper.getUrl(urlPath);

			final MultipartEntity content = SessionHelper.getPostSessionBody(sessionsList, sharedBoundary);

			HttpPut request = new HttpPut();
			request.setEntity(content);
			
			
			ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
			content.writeTo(outputStream);
			String multipartRawContent = outputStream.toString();
			
			String authHeader = WebServiceHelper.getHMACAuthHeader(AppBlade.appInfo, urlPath, multipartRawContent, HttpMethod.PUT);

			Log.v(AppBlade.LogTag, urlPath);
			Log.v(AppBlade.LogTag, url);
			Log.v(AppBlade.LogTag, authHeader);

			request.setURI(new URI(url));
			request.addHeader("Content-Type", HttpUtils.ContentTypeMultipartFormData + "; boundary=" + sharedBoundary);
			request.addHeader("Authorization", authHeader);
			WebServiceHelper.addCommonHeaders(request);
			
			
			HttpResponse response = null;
			response = client.execute(request);
			if(response != null && response.getStatusLine() != null)
			{
				int statusCode = response.getStatusLine().getStatusCode();
				Log.v(AppBlade.LogTag, "response: "+ statusCode);
				return statusCode;
			}
		}
		catch(Exception ex)
		{
			Log.v(AppBlade.LogTag, String.format("%s %s", ex.getClass().getSimpleName(), ex.getMessage()));
		}

		IOUtils.safeClose(client);
		
		return -10000; //an exception occurred during posting
	}
	
	/**
	 * Generates a MultipartEntity of the given list of sessions
	 * @param sessions list of SessionData objects
	 * @param boundary boundary String that will be used as a separator.
	 * @return MultipartEntity object generated for the sessions.
	 */
	public static MultipartEntity getPostSessionBody(List<SessionData> sessions, String boundary) {
		MultipartEntity entity = new MultipartEntity(HttpMultipartMode.BROWSER_COMPATIBLE, boundary, null);
		
		try
		{
			ContentBody deviceIdBody  = new StringBody(AppBlade.appInfo.AppId);
			entity.addPart("device_id", deviceIdBody);			
			ContentBody projectIdBody  = new StringBody(AppBlade.appInfo.AppId);
			entity.addPart("project_id", projectIdBody);			
			ContentBody sessionsBody = new StringBody(formattedSessionsBodyFromList(sessions));
			entity.addPart("sessions", sessionsBody);			
		} 
		catch (IOException e) {
			Log.v(AppBlade.LogTag, e.toString());
		}
		
		return entity;
	}
	
	/**
	 * Sends a post request for all currently stored sessions. (Note the existing session will not be sent since it hasn't ended yet.)
 	 * @param context Context to use for file maintenance.
 	 */
	public static void postExistingSessions(final Context context){
		Log.v(AppBlade.LogTag, "checking for existing sessions.");
		getSessionDataWithListener(context, new OnSessionDataAcquiredListener(){
			@SuppressWarnings("unchecked")
			public void OnSessionDataAcquired(List<SessionData> acquiredData) {
				PostSessionTask postSessionTask = new PostSessionTask(context);
				postSessionTask.execute(acquiredData);
			}
		} );
	}
	
	
	//*****************Data Listener
	/**
	 * REtrieves session data and reports the to the listener when the data is acquired. <br>
	 * Ideal for asynchronous tasks. 
	 * @param context Context to use for file maintenance.
	 * @param listener Listerer we will send the callbacks to.
	 */
	public static void getSessionDataWithListener(Context context,
			final OnSessionDataAcquiredListener listener) {
		File f = new File(sessionsIndexFileURI());
		if(f.exists()){
			Log.v(AppBlade.LogTag, sessionsIndexFileURI()+" exists.");
				Log.v(AppBlade.LogTag, "Finished sessions might exist, posting them.");
				List<SessionData> existingSessions = SessionHelper.readData(context);
				listener.OnSessionDataAcquired(existingSessions);
		}else{
			Log.v(AppBlade.LogTag, "Sessions file does not exist, creating it.");
			List<SessionData> blankSessions = new ArrayList<SessionData>();
			updateFile(context, sessionsIndexFileURI(), blankSessions);
			listener.OnSessionDataAcquired(blankSessions);
		}

	}
	

	//*****************Sessions batch formatting for sending to AppBlade
	/**
	 * Turns a sessionslist into a JSONFormatted String (non-destructive to the sessions list)
	 * @param sessions List of sessions we want to format.
	 * @return String in the format of a JSONArray with all the SessionData Objects as JSON Objects inside it.
	 */
	public static String formattedSessionsBodyFromList(List<SessionData> sessions){
		JSONArray jsonSessions = new JSONArray();
		//build a list of JSONObjects 
		for(SessionData s : sessions){
			jsonSessions.put(s.formattedSessionAsJSON());
		}
		return jsonSessions.toString();
	}
	
	//*****************Sessions storage helpers
	/**
	 * Generator of the sessions folder location.
	 * @return A String of the sessions folder location.
	 */
	public static String sessionsIndexFileURI() {
		return AppBlade.sessionsDir + "/"+sessionsIndexFileName;
	}


	//*****************Sessions storage/queue logic
	/**
	 * Generator for a SessionData object that we absolutely HAVE to have stored statically before we get it. 
	 * @param context Context to use for file maintenance.
	 * @return A SessionData object
	 */
	public static SessionData createPersistentSession(Context context) {
		Log.v(AppBlade.LogTag, "Creating New Session ");
		SessionData data = new SessionData(new Date(), new Date(), new JSONObject());
		//check if file exists
		File f = new File(sessionsIndexFileURI());
		if(f.exists()){
			try {
				f.createNewFile();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		insertSessionData(context, data);
		return data;
	}
	

	/**
	 * Synchronized addition of a single session.<br>
	 * @param context Context to use for file maintenance.
	 * @param data SessionData you want added. 
	 */
	public synchronized static void insertSessionData(final Context context, final SessionData data) {
		Log.v(AppBlade.LogTag, "Adding Session to file");
		getSessionDataWithListener(context, new OnSessionDataAcquiredListener(){
			public void OnSessionDataAcquired(List<SessionData> acquiredData) {
				acquiredData.add(data); //add data
		        // Update file
		        updateFile(context, sessionsIndexFileURI(), acquiredData);
			}
		} );

	}	


	/**
	 * Synchronized removal of a single stored session.<br>
	 * @param context Context to use for file maintenance.
	 * @param data SessionData you want removed. 
	 */
	public synchronized static void removeSession(final Context context, final SessionData data) {
		Log.v(AppBlade.LogTag, "Removing Session to file");
		getSessionDataWithListener(context, new OnSessionDataAcquiredListener(){
			public void OnSessionDataAcquired(List<SessionData> acquiredData) {
				// remove object from ArrayList
				acquiredData.remove(data);
				// Update file with new list of sessions
				updateFile(context, sessionsIndexFileURI(), acquiredData);
			}
		} );
	}

	/**
	 * Batch removal of sessions after success (or expiration).<br>
	 * Sessions ended on or before dateEnded will be removed. Sessions that started before dateEnded but ended after dateEnded will not be removed. 
	 * @param context Context to use for file maintenance.
	 * @param dateEnded The date you want sessions removed before. 
	 */
	public synchronized static void removeSessionsEndedBefore(final Context context, final Date dateEnded){
		getSessionDataWithListener(context, new OnSessionDataAcquiredListener(){
			@SuppressWarnings("deprecation")
			public void OnSessionDataAcquired(List<SessionData> acquiredData) {
		        // remove all objects from ArrayList that ended before dateEnded
		        for (int i = 0; i < acquiredData.size(); )
		        {
		        	SessionData s = acquiredData.get(i);
		        	if(s.ended.getSeconds() <= dateEnded.getSeconds())
		        	{
		        		acquiredData.remove(i);
		        	}
		        	else
		        	{
		        		i++;
		        	}
		        }
		        //list filtered, rewrite
		        updateFile(context, sessionsIndexFileURI(), acquiredData);
			}
		} );

	}
	

	
	//***************** BASE FILE MANAGEMENT
	
	/**
	 * Retrieves list of current sessions.<br>
	 * @param context Context to use for file maintenance.
	 * @return list of current stored session data. 
	 */
	public synchronized  static List<SessionData> readData(Context context)
    {
    	Log.v(AppBlade.LogTag, "reading in Sessions file. ");

            List<SessionData> listofusers = new ArrayList<SessionData>();
            FileInputStream fstream = null;
            try
            {
                fstream = new FileInputStream(sessionsIndexFileURI());
				BufferedReader br = new BufferedReader(new InputStreamReader(fstream));
                String strLine = "";
                //Read file line by line
                while ((strLine = br.readLine()) != null)   {
                  listofusers.add(new SessionData(strLine));
                }
                br.close();
            }
            catch (IOException e) {
              e.printStackTrace();
            }
            finally {
                try { fstream.close(); } catch ( Exception ignore ) {}
            }
            
        	Log.v(AppBlade.LogTag, "Read Sessions file. " +listofusers.size() +" sessions");

            return listofusers;
    }

	/**
	 * Function that makes or overwrites a file with the given sessions.
	 * @param context Context to use for file maintenance.
	 * @param filename String name of the file that we will store our session data.
	 * @param sessionDataList List of SessionData that we will store in the file.
	 */
    public synchronized  static void updateFile(Context context, String filename, List<SessionData> sessionDataList) {
    	//check for existence of file, if no file, create file
    	Log.v(AppBlade.LogTag, "Updating Sessions file. " +sessionDataList.size() +" sessions");
	    try{
	    	final File parent = new File(AppBlade.sessionsDir);
	    	if(!parent.exists())
	    	{
	    		System.err.println("Parent directories do not exist");
		    	if (!parent.mkdirs())
		    	{
		    	   System.err.println("Could not create parent directories");
		    	}
	    	}
	    	final File someFile = new File(AppBlade.sessionsDir, sessionsIndexFileName);
	    	if(!someFile.exists()){
	        	Log.v(AppBlade.LogTag, "Sessions file does not exist yet. creating Sessions file.");
	    		someFile.createNewFile();
	    	}
	    }catch (IOException ex) {
	    	Log.w(AppBlade.LogTag, "Error making Sessions file", ex);
	    }
       BufferedWriter bufferedWriter = null;
        try {
            bufferedWriter = new BufferedWriter(new FileWriter(filename));
        	Log.v(AppBlade.LogTag, "built bufferedWriter");

        } catch (IOException ex) {
        	Log.w(AppBlade.LogTag, "Error writing Sessions file", ex);
        }
        SessionData ud;
        String row;
       for(int i=0; i<sessionDataList.size(); i++) {
           ud = sessionDataList.get(i);
           row = ud.sessionAsStoredString();
            try {
            	Log.v(AppBlade.LogTag, "writing "+row);
                bufferedWriter.write(row);
                bufferedWriter.newLine();
            } catch (FileNotFoundException ex) {
    	    	Log.w(AppBlade.LogTag, "Error writing individual session", ex);
            } catch (IOException ex) {
    	    	Log.w(AppBlade.LogTag, "IO Error writing individual session", ex);
            }
        }
        //Close the BufferedWriter
        try {
              if (bufferedWriter != null) {
              	Log.v(AppBlade.LogTag, "teardown bufferedWriter");

                  bufferedWriter.flush();
                  bufferedWriter.close();
              }
        } catch (IOException ex) {
	    	Log.w(AppBlade.LogTag, "IO Error writing session file", ex);
        }
    }	
}

