package com.appblade.framework.utils;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.math.BigInteger;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import com.appblade.framework.Base64;

public class StringUtils {
	
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
}
