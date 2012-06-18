package mypackage;

import net.rim.device.api.ui.UiApplication;
import AppBlade.AppBladeSDK;

/**
 * This class extends the UiApplication class, providing a
 * graphical user interface.
 */
public class MyApp extends UiApplication
{
    /**
     * Entry point for application
     * @param args Command line arguments (not used)
     */ 
    public static void main(String[] args)
    {
//    	_permissions();
    	
        // Create a new instance of the application and make the currently
        // running thread the application's event dispatch thread.
        MyApp theApp = new MyApp();       
        theApp.enterEventDispatcher();
    }
    

    /**
     * Creates a new MyApp object
     */
    public MyApp()
    {        
        AppBladeSDK sdk = new AppBladeSDK("062f0f43-dc15-4751-b6c7-0375483d133f");
        sdk.authorize();
        // Push a screen onto the UI stack for rendering.
        pushScreen(new MyScreen());
    }    
    
    
}
