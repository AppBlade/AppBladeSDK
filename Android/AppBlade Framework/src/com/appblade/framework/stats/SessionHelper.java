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

import com.appblade.framework.AppBlade;
import com.appblade.framework.WebServiceHelper;
import com.appblade.framework.WebServiceHelper.HttpMethod;
import com.appblade.framework.utils.HttpClientProvider;
import com.appblade.framework.utils.IOUtils;

import android.content.Context;
import android.util.Log;

public class SessionHelper {
	//I/O RELATED
	public static String sessionsIndexFileName = "index.txt";
	//API RELATED
	public static String sessionsIndexMIMEType = "text/json"; 

	//Session Logging 
	public static void startSession(Context context){
		Log.d(AppBlade.LogTag, "Starting Session");
		AppBlade.currentSession = new SessionData();
	}
	 
	public static void endSession(Context context){
		Log.d(AppBlade.LogTag, "Ending Session");
		if(AppBlade.currentSession != null){
			AppBlade.currentSession.ended = new Date();
			SessionData sessionToStore = new SessionData(AppBlade.currentSession.began, AppBlade.currentSession.ended);
			insertSessionData(context, sessionToStore);
			AppBlade.currentSession = null;
		}
	}

	
	//API RELATED FUNCTIONS
	public static int postSession(SessionData data) {
		ArrayList<SessionData> sessionsList = new ArrayList<SessionData>();
		sessionsList.add(data);
		return postSessions(sessionsList);
	}

	static int postSessions(List<SessionData> sessionsList) {
		HttpClient client = HttpClientProvider.newInstance("Android");
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

			Log.d(AppBlade.LogTag, urlPath);
			Log.d(AppBlade.LogTag, url);
			Log.d(AppBlade.LogTag, authHeader);

			request.setURI(new URI(url));
			request.addHeader("Content-Type", "multipart/form-data; boundary=" + sharedBoundary);
			request.addHeader("Authorization", authHeader);
			WebServiceHelper.addCommonHeaders(request);
			
			
			HttpResponse response = null;
			response = client.execute(request);
			if(response != null && response.getStatusLine() != null)
			{
				int statusCode = response.getStatusLine().getStatusCode();
				Log.d(AppBlade.LogTag, "response: "+ statusCode);
				return statusCode;
			}
		}
		catch(Exception ex)
		{
			Log.d(AppBlade.LogTag, String.format("%s %s", ex.getClass().getSimpleName(), ex.getMessage()));
		}

		IOUtils.safeClose(client);
		
		return -10000; //an exception occurred during posting
	}
	
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
			Log.d(AppBlade.LogTag, e.toString());
		}
		
		return entity;
	}
	
	public static void postExistingSessions(final Context context){
		Log.d(AppBlade.LogTag, "checking for existing sessions.");
		getSessionDataWithListener(context, new OnSessionDataAcquiredListener(){
			@SuppressWarnings("unchecked")
			public void OnSessionDataAcquired(List<SessionData> acquiredData) {
				PostSessionTask postSessionTask = new PostSessionTask(context);
				postSessionTask.execute(acquiredData);
			}
		} );
	}
	
	
	//Data Listener
	public static void getSessionDataWithListener(Context context,
			final OnSessionDataAcquiredListener listener) {
		File f = new File(sessionsIndexFileURI());
		if(f.exists()){
			Log.d(AppBlade.LogTag, sessionsIndexFileURI()+" exists.");
				Log.d(AppBlade.LogTag, "Finished sessions might exist, posting them.");
				List<SessionData> existingSessions = SessionHelper.readData(context);
				listener.OnSessionDataAcquired(existingSessions);
		}else{
			Log.d(AppBlade.LogTag, "Sessions file does not exist, creating it.");
			List<SessionData> blankSessions = new ArrayList<SessionData>();
			updateFile(context, sessionsIndexFileURI(), blankSessions);
			listener.OnSessionDataAcquired(blankSessions);
		}

	}
	

	//Sessions batch formatting for sending to AppBlade
	public static String formattedSessionsBodyFromList(List<SessionData> sessions){
		JSONArray jsonSessions = new JSONArray();
		//build a list of JSONObjects 
		for(SessionData s : sessions){
			jsonSessions.put(s.formattedSessionAsJSON());
		}
		return jsonSessions.toString();
	}
	
	//Sessions storage helpers
	public static String sessionsIndexFileURI() {
		return AppBlade.sessionsDir + "/"+sessionsIndexFileName;
	}


	//Sessions storage/queue logic
	public static SessionData createPersistentSession(Context context) {
		Log.d(AppBlade.LogTag, "Creating New Session ");
		SessionData data = new SessionData(new Date(), new Date());
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
	
	public synchronized static void insertSessionData(final Context context, final SessionData data) {
		Log.d(AppBlade.LogTag, "Adding Session to file");
		getSessionDataWithListener(context, new OnSessionDataAcquiredListener(){
			public void OnSessionDataAcquired(List<SessionData> acquiredData) {
				acquiredData.add(data); //add data
		        // Update file
		        updateFile(context, sessionsIndexFileURI(), acquiredData);
			}
		} );

	}	

	public synchronized static void removeSession(final Context context, final SessionData data) {
		Log.d(AppBlade.LogTag, "Removing Session to file");
		getSessionDataWithListener(context, new OnSessionDataAcquiredListener(){
			public void OnSessionDataAcquired(List<SessionData> acquiredData) {
				// remove object from ArrayList
				acquiredData.remove(data);
				// Update file
				updateFile(context, sessionsIndexFileURI(), acquiredData);
			}
		} );
	}

	//batch removal of sessions after success (or expiration). Sessions ended before dateEnded will be removed.
	public synchronized static void removeSessionsEndedBefore(final Context context, final Date dateEnded){
		getSessionDataWithListener(context, new OnSessionDataAcquiredListener(){
			public void OnSessionDataAcquired(List<SessionData> acquiredData) {
		        // remove all objects from ArrayList that ended before dateEnded
		        for (int i = 0; i < acquiredData.size(); )
		        {
		        	SessionData s = acquiredData.get(i);
		        	if(s.ended.getSeconds() < dateEnded.getSeconds())
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
	

	//Sessions base file interaction functions 
	public synchronized  static List<SessionData> readData(Context context)
    {
    	Log.d(AppBlade.LogTag, "reading in Sessions file. ");

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
            }
            catch (IOException e) {
              e.printStackTrace();
            }
            finally {
                try { fstream.close(); } catch ( Exception ignore ) {}
            }
            
        	Log.d(AppBlade.LogTag, "Read Sessions file. " +listofusers.size() +" sessions");

            return listofusers;
    }


    public synchronized  static void updateFile(Context context, String filename, List<SessionData> userDataList) {
    	//check for existence of file, if no file, create file
    	Log.d(AppBlade.LogTag, "Updating Sessions file. " +userDataList.size() +" sessions");
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
        	Log.d(AppBlade.LogTag, "Sessions file does not exist yet. creating Sessions file.");
    		someFile.createNewFile();
    	}
    }catch (IOException ex) {
    	Log.d(AppBlade.LogTag, "Error making Sessions file");
    	ex.printStackTrace();
    }
       BufferedWriter bufferedWriter = null;
        try {
            bufferedWriter = new BufferedWriter(new FileWriter(filename));
        	Log.d(AppBlade.LogTag, "built bufferedWriter");

        } catch (IOException ex) {
        	Log.d(AppBlade.LogTag, "Error writing Sessions file");
        	ex.printStackTrace();
        }
        SessionData ud;
        String row;
       for(int i=0; i<userDataList.size(); i++) {
           ud = userDataList.get(i);
           row = ud.sessionAsStoredString();
            try {
            	Log.d(AppBlade.LogTag, "writing "+row);
                bufferedWriter.write(row);
                bufferedWriter.newLine();
            } catch (FileNotFoundException ex) {
                ex.printStackTrace();
            } catch (IOException ex) {
                ex.printStackTrace();
            }
        }
        //Close the BufferedWriter
        try {
              if (bufferedWriter != null) {
              	Log.d(AppBlade.LogTag, "teardown bufferedWriter");

                  bufferedWriter.flush();
                  bufferedWriter.close();
              }
        } catch (IOException ex) {
              ex.printStackTrace();
        }
    }	
	
}
