package com.appblade.framework.utils;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.math.BigInteger;
import java.security.DigestInputStream;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import android.util.Log;

import com.appblade.framework.AppBlade;


public class StringUtils {
	 public static final int BUFFER_SIZE = 2048;
	 
	/**
	 * Utility method for pulling plain text from an InputStream object
	 * @param in InputStream object retrieved from an HttpResponse
	 * @return String contents of stream
	 */
	public static String readStream(InputStream in)
	{
		BufferedReader reader = new BufferedReader(new InputStreamReader(in));
		StringBuilder sb = new StringBuilder();
		String line = null;
		try
		{
			while((line = reader.readLine()) != null)
			{
				sb.append(line + "\n");
			}
		}
		catch(Exception ex) { }
		finally
		{
			IOUtils.safeClose(in);
			IOUtils.safeClose(reader);
		}
		return sb.toString();
	}
	
	public static boolean isNullOrEmpty(String input)
	{
		return input == null || input.trim().length() == 0;
	}
	
	public static void append(StringBuilder builder, String format, Object... params)
	{
		builder.append(String.format(format, params));
	}
	
	public static String hmacSha256(String key, String message)
	{
		String result = "";
		try
		{
			Mac mac = Mac.getInstance("HmacSHA256");
			SecretKeySpec signingKey = new SecretKeySpec(key.getBytes(), "HmacSHA256");
			mac.init(signingKey);
			byte[] rawHmac = mac.doFinal(message.getBytes());
			result = Base64.encodeToString(rawHmac, 0, rawHmac.length, 0);
		}
		catch(InvalidKeyException ex) { }
		catch(NoSuchAlgorithmException ex) { }
		
		return result;
	}
	
	public static byte[] sha256(String input)
	{
		try
		{
			MessageDigest digest = MessageDigest.getInstance("SHA-256");
			digest.update(input.getBytes());
			byte[] messageDigest = digest.digest();
			return messageDigest;
		}
		catch(NoSuchAlgorithmException ex) { }
		
		return null;
	}

	public static int safeParse(String input, int defaultValue) {
		int value = defaultValue;
		try
		{
			value = Integer.parseInt(input);
		}
		catch (Exception ex) { }
		return value;
	}
	
	public static String md5(String input) {
		String hash = input;
		MessageDigest m = null;

	    try
	    {
            m = MessageDigest.getInstance("MD5");
    	    m.update(input.getBytes(), 0, input.length());
    	    hash = new BigInteger(1, m.digest()).toString(16);
	    }
	    catch (NoSuchAlgorithmException e) { }
	    return hash;
	}
	
	
	public static String md5FromInputStream(InputStream is)  {
		MessageDigest md = null;
		byte[] byteArray = null;
		try {
			md = MessageDigest.getInstance("MD5");
		} catch (NoSuchAlgorithmException e1) {
			e1.printStackTrace();
		}
		
		if(md != null){
			try {
				is = new DigestInputStream(is, md);
				// read stream to EOF as normal...
			}
			finally {
				try {
					is.close();
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
			byteArray = md.digest();
		}
		
        StringBuffer hexString = new StringBuffer();
        for (int i = 0; i < byteArray.length; i++) {
            String hex = Integer.toHexString(0xff & byteArray[i]);
            if(hex.length() == 1) hexString.append('0');
            hexString.append(hex);
        }
        
        return hexString.toString();
	}

	public static String sha256FromInputStream(InputStream is)  {
		MessageDigest md = null;
        StringBuffer hexString = new StringBuffer();
		try {
			md = MessageDigest.getInstance("SHA-256");
		} catch (NoSuchAlgorithmException e1) {
			e1.printStackTrace();
		}
		
		if(md != null){
	        DigestInputStream dis = new DigestInputStream(is, md);
	        byte[] buffer = new byte[BUFFER_SIZE];
	       try {
	    	   try {
					while (dis.read(buffer) != -1) {
					 //
					}
			        dis.close();
	    	   }
	    	   finally {
		    	   is.close();
		       }
	       }
	       catch (IOException e) {
				e.printStackTrace();
	       }
	        
			byte[] byteArray = md.digest();
	        for (int i = 0; i < byteArray.length; i++) {
	            String hex = Integer.toHexString(byteArray[i] & 0xff);
	            if(hex.length() == 1) hexString.append('0');
	            hexString.append(hex);
	        }
		}

        return hexString.toString();
	}
}
