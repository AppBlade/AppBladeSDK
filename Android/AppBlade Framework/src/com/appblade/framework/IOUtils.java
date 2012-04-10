package com.appblade.framework;

import java.io.Closeable;
import java.io.IOException;

import org.apache.http.client.HttpClient;

public class IOUtils {
	
	public synchronized static void safeClose(Closeable closeable)
	{
		if(closeable != null)
		{
			try
			{
				closeable.close();
			}
			catch (IOException e) { }
		}
	}
	
	public synchronized static void safeClose(HttpClient client)
	{
		if(client != null && client.getConnectionManager() != null)
		{
			client.getConnectionManager().shutdown();
		}
	}
}
