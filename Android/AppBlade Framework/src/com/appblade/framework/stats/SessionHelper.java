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

import com.appblade.framework.AppBlade;
import com.appblade.framework.WebServiceHelper;
import com.appblade.framework.WebServiceHelper.HttpMethod;
import com.appblade.framework.utils.HttpClientProvider;
import com.appblade.framework.utils.IOUtils;

import android.util.Log;

public class SessionHelper {
	public static String sessionsFolder = "/appBlade/sessions";
	public static String sessionsIndexFileName = "index.txt";

	
	//API related functions
	public static Boolean postSession(SessionData data) {
		boolean success = false;
		HttpClient client = HttpClientProvider.newInstance("Android");

		try
		{
			String urlPath = String.format(WebServiceHelper.ServicePathSessionFormat, AppBlade.appInfo.AppId, AppBlade.appInfo.Ext);
			String url = WebServiceHelper.getUrl(urlPath);

			final MultipartEntity content = SessionHelper.getPostSessionBody(data, AppBlade.BOUNDARY);

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
			request.addHeader("Content-Type", "multipart/form-data; boundary=" + AppBlade.BOUNDARY);
			request.addHeader("Authorization", authHeader);
			WebServiceHelper.addCommonHeaders(request);
			
			
			HttpResponse response = null;
			response = client.execute(request);
			if(response != null && response.getStatusLine() != null)
			{
				int statusCode = response.getStatusLine().getStatusCode();
				int statusCategory = statusCode / 100;

				if(statusCategory == 2)
					success = true;
			}
		}
		catch(Exception ex)
		{
			Log.d(AppBlade.LogTag, String.format("%s %s", ex.getClass().getSimpleName(), ex.getMessage()));
		}

		IOUtils.safeClose(client);
		
		return success;
	}
	
	public static MultipartEntity getPostSessionBody(SessionData data, String boundary) {
		MultipartEntity entity = new MultipartEntity(HttpMultipartMode.BROWSER_COMPATIBLE, boundary, null);
		
		try
		{
			ContentBody deviceIdBody  = new StringBody(AppBlade.appInfo.AppId);
			entity.addPart("session[device_id]", deviceIdBody);			
			ContentBody projectIdBody  = new StringBody(AppBlade.appInfo.AppId);
			entity.addPart("session[project_id]", projectIdBody);			
			ContentBody sessionsBody = new StringBody(data.formattedSessionBody());
			entity.addPart("session[sessions]", sessionsBody);			
		} 
		catch (IOException e) {
			Log.d(AppBlade.LogTag, e.toString());
		}
		
		return entity;
	}

	public static MultipartEntity getPostSessionBody(List<SessionData> sessions, String boundary) {
		MultipartEntity entity = new MultipartEntity(HttpMultipartMode.BROWSER_COMPATIBLE, boundary, null);
		
		try
		{
			ContentBody deviceIdBody  = new StringBody(AppBlade.appInfo.AppId);
			entity.addPart("session[device_id]", deviceIdBody);			
			ContentBody projectIdBody  = new StringBody(AppBlade.appInfo.AppId);
			entity.addPart("session[project_id]", projectIdBody);			
			ContentBody sessionsBody = new StringBody(formattedSessionsBodyFromList(sessions));
			entity.addPart("session[sessions]", sessionsBody);			
		} 
		catch (IOException e) {
			Log.d(AppBlade.LogTag, e.toString());
		}
		
		return entity;
	}
	
	private static void postExistingSessions(){
		File f = new File(sessionsIndexFileLocation());
		if(f.exists()){
			ArrayList<SessionData> sessionsList = new ArrayList<SessionData>();
			if(sessionsList.size() != 0){
				Log.d(AppBlade.LogTag, "Finished sessions exist, posting them.");
				SessionData s = sessionsList.get(0);
				if(postSession(s)){
					Log.d(AppBlade.LogTag, "session posting success. remove successful session.");
					removeSession(s);
				}else{
					Log.d(AppBlade.LogTag, "error posting session. Stored for later.");
					
				}
			}
		}
	}
	
	public static void startSession(){
		//check for existing sessions, post them.
		postExistingSessions();
		Log.d(AppBlade.LogTag, "Starting Session");
		AppBlade.currentSession = new SessionData();
	}
	 

	public static void endSession(){
		Log.d(AppBlade.LogTag, "Ending Session");
		if(AppBlade.currentSession != null){
			AppBlade.currentSession.ended = new Date();
			SessionData sessionToStore = new SessionData(AppBlade.currentSession.began, AppBlade.currentSession.ended);
			insertSessionData(sessionToStore);
			AppBlade.currentSession = null;
		}
	}

	//sessions formatting
	public static String formattedSessionsBodyFromList(List<SessionData> sessions){
		String toRet = "\"sessions\" : ["; 
		for(int i = 0; i < sessions.size(); i++){
			SessionData s = sessions.get(i);
			toRet = toRet + " " + s.formattedSessionBody();
			if(sessions.size() > 1 && i < sessions.size() - 1){
				toRet = toRet +",";	
			}
		}
		toRet = toRet  + "]";
		return toRet;
	}
	
	//Sessions storage/queue logic
	public static String sessionsIndexFileLocation() {
		return sessionsFolder + "/"+sessionsIndexFileName;
	}

	
	public static SessionData createPersistentSession() {
		Log.d(AppBlade.LogTag, "Creating New Session ");
		SessionData data = new SessionData(new Date(), new Date());
		insertPendingSession(data);
		return data;
	}
	
	public static void insertPendingSession(SessionData sessionToInsert){
		//check if file exists
		File f = new File(sessionsIndexFileLocation());
		if(f.exists()){
			try {
				f.createNewFile();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		
		insertSessionData(sessionToInsert);
	}


	public static void removeSession(SessionData data) {
		Log.d(AppBlade.LogTag, "Removing Session to file");
        List<SessionData> userDataList = readData();
        // remove object from ArrayList
        userDataList.remove(data);
        // Update file
        updateFile(sessionsIndexFileLocation(), userDataList);

	}
	

	public static void insertSessionData(SessionData data) {
		Log.d(AppBlade.LogTag, "Adding Session to file");

        List<SessionData> userDataList = readData();
        userDataList.add(data);
        // Update file
        updateFile(sessionsIndexFileLocation(), userDataList);
	}	
	

	public static List<SessionData> readData()
    {
            List<SessionData> listofusers = new ArrayList<SessionData>();
            FileInputStream fstream = null;
            try
            {

                fstream = new FileInputStream(sessionsIndexFileLocation());
                BufferedReader br = new BufferedReader(new InputStreamReader(fstream));
                String strLine = "";
                String[] tokens = strLine.split(", ");
                //Read file line by line
                while ((strLine = br.readLine()) != null)   {
                  // Copy the content into the array
                  tokens = strLine.split(", ");
                  listofusers.add(new SessionData(new Date(tokens[0]), new Date(tokens[1])));
                }
            }
            catch (IOException e) {
              e.printStackTrace();
            }
            finally {
                try { fstream.close(); } catch ( Exception ignore ) {}
            }
            return listofusers;
    }


    public static void updateFile(String filename, List<SessionData> userDataList) {
       BufferedWriter bufferedWriter = null;
        try {
            bufferedWriter = new BufferedWriter(new FileWriter(filename));
        } catch (IOException ex) {
        	Log.d(AppBlade.LogTag, "Error writing Sessions file");
        	ex.printStackTrace();
        }
        SessionData ud;
        String row;
       for(int i=0; i<userDataList.size(); i++) {
           ud = userDataList.get(i);
           row = ud.began.toString() + ", " + ud.ended.toString();
            try {
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
                  bufferedWriter.flush();
                  bufferedWriter.close();
              }
        } catch (IOException ex) {
              ex.printStackTrace();
        }
    }	
	
}
