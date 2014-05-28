package com.appblade.framework.utils;

import java.io.Closeable;
import java.io.IOException;

import org.apache.http.client.HttpClient;

/**
 * Utility class for synchronized opening and closing of Closeables/HttpClients. 
 * @author rich.stern@raizlabs
 * @author andrew.tremblay@raizlabs
 */
public class IOUtils {
	
	/**
	 * Try to close an object asynchronously.<br>
	 * Catches any IOExceptions
	 * @param closeable Closeable object to, well, close.
	 */
	public synchronized static void safeClose(Closeable closeable)
	{
		if(closeable != null)
		{
			try
			{
				closeable.close();
			}
			catch (IOException e) { e.printStackTrace(); }
		}
	}
	
	/**
	 * Try to close an object asynchronously.<br>
	 * @param client HttpClient object to, well, close.
	 */
	public synchronized static void safeClose(HttpClient client)
	{
		if(client != null && client.getConnectionManager() != null)
		{
			client.getConnectionManager().shutdown();
		}
	}
}
