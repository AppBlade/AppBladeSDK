package appblade;

import net.rim.device.api.script.ScriptableFunction;

public final class AppBladeFunction extends ScriptableFunction {
	public Object invoke(Object obj, Object[] args) throws Exception
	{

	   if (args.length == 1) 
	   {
	      AppBladeSDK sdk = new AppBladeSDK((String)args[0]);
	      sdk.authorize();
	   }
	   return UNDEFINED;
	}

}
