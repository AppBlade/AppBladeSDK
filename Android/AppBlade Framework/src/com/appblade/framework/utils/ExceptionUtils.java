package com.appblade.framework.utils;


public class ExceptionUtils {
	
	public static String getStackTrace(Throwable e)
	{
		StringBuilder builder = new StringBuilder();
		
		Throwable current = e;
		StringUtils.append(builder, "%s: %s%n", e.getClass().getCanonicalName(), e.getMessage());
		
		while(current != null)
		{
			StackTraceElement[] stack = current.getStackTrace();
			for(StackTraceElement element : stack)
			{
				if(element.isNativeMethod())
					StringUtils.append(builder, "    %s(Native Method)%n", element.getClassName());
				else
					StringUtils.append(builder, "    %s(%s:%d)%n", element.getClassName(), element.getFileName(), element.getLineNumber());
			}
			
			current = current.getCause();
			if(current != null)
			{
				StringUtils.append(builder, " ### CAUSED BY ### : %s%n", current.toString());
			}
		}
		return builder.toString();
	}

}
