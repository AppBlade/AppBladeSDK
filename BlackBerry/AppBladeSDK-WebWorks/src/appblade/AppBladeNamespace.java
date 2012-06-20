package appblade;

import net.rim.device.api.script.Scriptable;

public final class AppBladeNamespace extends Scriptable {
	public static final String FIELD_AUTHORIZE = "authorize";
	private AppBladeFunction authorize;
	
	public AppBladeNamespace() {
		this.authorize = new AppBladeFunction();
	}
	
	public Object getField(String name) throws Exception {
		if (name.equals(FIELD_AUTHORIZE)) {
	         return this.authorize;
	      }
		return super.getField(name);
	}
}
