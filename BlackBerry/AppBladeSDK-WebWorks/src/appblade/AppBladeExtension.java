package appblade;

import org.w3c.dom.Document;

import net.rim.device.api.browser.field2.BrowserField;
import net.rim.device.api.script.ScriptEngine;
import net.rim.device.api.web.WidgetConfig;
import net.rim.device.api.web.WidgetExtension;

public final class AppBladeExtension implements WidgetExtension {

	public String[] getFeatureList() {
		String[] result = new String[1];
	      result[0] = "appblade.authorize";
	      return result;
	}

	public void loadFeature(String feature, String version, Document doc,
			ScriptEngine scriptEngine) throws Exception {
		if (feature == "appblade.authorize") {
	         scriptEngine.addExtension("appblade.authorize", new AppBladeNamespace());
	      }

	}

	public void register(WidgetConfig arg0, BrowserField arg1) {

	}

	public void unloadFeatures(Document arg0) {
	}

}
