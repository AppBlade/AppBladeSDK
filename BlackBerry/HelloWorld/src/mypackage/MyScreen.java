package mypackage;

import net.rim.device.api.ui.container.MainScreen;
//import org.json.simple.JSONObject;
/**
 * A class extending the MainScreen class, which provides default standard
 * behavior for BlackBerry GUI applications.
 */
public final class MyScreen extends MainScreen
{
    /**
     * Creates a new MyScreen object
     */
    public MyScreen()
    {        
        // Set the displayed title of the screen       
        setTitle("Hello World");
    }
    
}
