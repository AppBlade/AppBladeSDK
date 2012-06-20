package appblade;

import java.io.*;

import javax.microedition.io.Connector;
import javax.microedition.io.HttpConnection;

import net.rim.device.api.applicationcontrol.ApplicationPermissions;
import net.rim.device.api.applicationcontrol.ApplicationPermissionsManager;
import net.rim.device.api.servicebook.ServiceBook;
import net.rim.device.api.servicebook.ServiceRecord;
import net.rim.device.api.system.ApplicationDescriptor;
import net.rim.device.api.system.CoverageInfo;
import net.rim.device.api.system.DeviceInfo;
import net.rim.device.api.system.WLANInfo;
import net.rim.device.api.ui.UiApplication;
import net.rim.device.api.ui.component.*;
import net.rim.device.api.system.*;

public final class AppBladeSDK implements DialogClosedListener
{

	private static final boolean USE_MDS_IN_SIMULATOR = false;
	private static final boolean DEBUG_MESSAGES = true;
	
	private static final String BASE_URL = "https://appblade.com/api/1/projects/";
	private static final String APPROVAL_URL = "/devices/";
	private static AppBladeSDK _sdk = null;
	
	private String _projectuuid = null;
	
	public AppBladeSDK(final String projectId)
	{
		this._projectuuid = projectId;
		_permissions();
		AppBladeSDK._sdk = this;
		
	}
	
	public void authorize()
	{
		String URL = AppBladeSDK.BASE_URL + this._projectuuid + AppBladeSDK.APPROVAL_URL + DeviceInfo.getDeviceId() + ".json?" + this.getConnectionString();
		int response = -1;
		try
		{
			HttpConnection connection = (HttpConnection)Connector.open(URL);
			connection.setRequestMethod(HttpConnection.GET);
			this.addHeadersToConnection(connection);
			response = connection.getResponseCode();
			
            connection.close();
		}
		catch (Exception e)
		{
			AppBladeSDK.logMessage("Exception trying to connect to server: " + e.toString());
		}
		
		AppBladeSDK.logMessage("Response code was " + response);
		
		if (response > 0) {
			final int status = response;
			UiApplication.getUiApplication().invokeLater(new Runnable() {
	            public void run() {
	                AppBladeSDK._sdk.processAuthorizeResponse(status);
	            }
	        });
		}
		else {
			AppBladeSDK.logMessage("We did not connect to the server.");
		}
	}
	
	public void processAuthorizeResponse(int statusCode)
	{
		if (statusCode != HttpConnection.HTTP_OK) {
			Dialog myDialog = new Dialog(Dialog.OK, "You are not authorized to use this application.", 0, Bitmap.getPredefinedBitmap(Bitmap.EXCLAMATION), Dialog.GLOBAL_STATUS);
			myDialog.setDialogClosedListener(this);
			myDialog.show();
		}
	}
	
    private static void logMessage(String str) {
    	if (AppBladeSDK.DEBUG_MESSAGES)
    	{
    		System.out.println(str);
    	}
    }
    
    public void dialogClosed(Dialog dialog, int choice) {
    	logMessage("-----------Exiting--------------");
    	System.exit(0);
    }
    
    private void addHeadersToConnection(HttpConnection connection)
    {
    	try 
    	{
	        connection.setRequestProperty("device_type", DeviceInfo.getDeviceName());
	        connection.setRequestProperty("os_version", DeviceInfo.getPlatformVersion());
	        connection.setRequestProperty("device_id", "" + DeviceInfo.getDeviceId());
	        connection.setRequestProperty("bundle_identifier", ApplicationDescriptor.currentApplicationDescriptor().getName());
	        connection.setRequestProperty("bundle_version", ApplicationDescriptor.currentApplicationDescriptor().getVersion());
	        connection.setRequestProperty("DEVICE_MFG", "RIM");
	        connection.setRequestProperty("DEVICE_BRAND", DeviceInfo.getManufacturerName());
	        connection.setRequestProperty("SOFTWARE_VERSION", DeviceInfo.getSoftwareVersion());
	        connection.setRequestProperty("Accept", "application/json");
    	}
    	catch (IOException e)
    	{
    		logMessage(e.toString());
    	}
    	
    }
	
    /**
     * Determines what connection type to use and returns the necessary string to use it.
     * @return A string with the connection info
     * 
     * Proper network connections, taken from Localytics blog
     * http://www.localytics.com/blog/2009/how-to-reliably-establish-a-network-connection-on-any-blackberry-device/
     * 
     */
    private String getConnectionString()
    {
        // This code is based on the connection code developed by Mike Nelson of AccelGolf.
        // http://blog.accelgolf.com/2009/05/22/blackberry-cross-carrier-and-cross-network-http-connection        
        String connectionString = null;                
                        
        // Simulator behavior is controlled by the USE_MDS_IN_SIMULATOR variable.
        if(DeviceInfo.isSimulator())
        {
            if(AppBladeSDK.USE_MDS_IN_SIMULATOR)
            {
                    logMessage("Device is a simulator and USE_MDS_IN_SIMULATOR is true");
                    connectionString = ";deviceside=false";                 
            }
            else
            {
                    logMessage("Device is a simulator and USE_MDS_IN_SIMULATOR is false");
                    connectionString = ";deviceside=true";
            }
        }                                        
                
        // Wifi is the preferred transmission method
        else if(WLANInfo.getWLANState() == WLANInfo.WLAN_STATE_CONNECTED)
        {
            logMessage("Device is connected via Wifi.");
            connectionString = ";interface=wifi";
        }
                        
        // Is the carrier network the only way to connect?
        else if((CoverageInfo.getCoverageStatus() & CoverageInfo.COVERAGE_DIRECT) == CoverageInfo.COVERAGE_DIRECT)
        {
            logMessage("Carrier coverage.");
                        
            String carrierUid = getCarrierBIBSUid();
            if(carrierUid == null) 
            {
                // Has carrier coverage, but not BIBS.  So use the carrier's TCP network
                logMessage("No Uid");
                connectionString = ";deviceside=true";
            }
            else 
            {
                // otherwise, use the Uid to construct a valid carrier BIBS request
                logMessage("uid is: " + carrierUid);
                connectionString = ";deviceside=false;connectionUID="+carrierUid + ";ConnectionType=mds-public";
            }
        }                
        
        // Check for an MDS connection instead (BlackBerry Enterprise Server)
        else if((CoverageInfo.getCoverageStatus() & CoverageInfo.COVERAGE_MDS) == CoverageInfo.COVERAGE_MDS)
        {
            logMessage("MDS coverage found");
            connectionString = ";deviceside=false";
        }
        
        // If there is no connection available abort to avoid bugging the user unnecssarily.
        else if(CoverageInfo.getCoverageStatus() == CoverageInfo.COVERAGE_NONE)
        {
            logMessage("There is no available connection.");
        }
        
        // In theory, all bases are covered so this shouldn't be reachable.
        else
        {
            logMessage("no other options found, assuming device.");
            connectionString = ";deviceside=true";
        }        
        
        return connectionString;
    }
    
    /**
     * Looks through the phone's service book for a carrier provided BIBS network
     * @return The uid used to connect to that network.
     */
    private static String getCarrierBIBSUid()
    {
        ServiceRecord[] records = ServiceBook.getSB().getRecords();
        int currentRecord;
        
        for(currentRecord = 0; currentRecord < records.length; currentRecord++)
        {
            if(records[currentRecord].getCid().toLowerCase().equals("ippp"))
            {
                if(records[currentRecord].getName().toLowerCase().indexOf("bibs") >= 0)
                {
                    return records[currentRecord].getUid();
                }
            }
        }
        
        return null;
    }
    
    private static void _permissions() {
    	ApplicationPermissionsManager apm = ApplicationPermissionsManager.getInstance();
    	
    	int internet = apm.getPermission(ApplicationPermissions.PERMISSION_INTERNET);
    	int wifi = apm.getPermission(ApplicationPermissions.PERMISSION_WIFI);
    	int server = apm.getPermission(ApplicationPermissions.PERMISSION_SERVER_NETWORK);
    	
    	if (internet != ApplicationPermissions.VALUE_ALLOW || wifi != ApplicationPermissions.VALUE_ALLOW || server != ApplicationPermissions.VALUE_ALLOW)
    	{
	    	ApplicationPermissions permRequest = new ApplicationPermissions();
	    	permRequest.addPermission(ApplicationPermissions.PERMISSION_INTERNET);
	    	permRequest.addPermission(ApplicationPermissions.PERMISSION_WIFI);
	    	permRequest.addPermission(ApplicationPermissions.PERMISSION_SERVER_NETWORK);
	    	apm.invokePermissionsRequest(permRequest);
    	}
    }
}
