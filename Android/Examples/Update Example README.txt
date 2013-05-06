The Update Example Android project demonstrates how AppBlade updates your app outside of the play store. The versionName value is read to display the change made to the manifest, but any change, be it in code or packaged resources, will trigger an update call. 

To demo this example for yourself:
1. Register a project on AppBlade.
2. Embed your AppBlade credentials  
3. Build and upload your .apk to AppBlade
4. Make a change to the Update Example project (editing android:versionName in the manifest will work best as that value is being read and displayed already).
5. Build and upload your second .apk to AppBlade.

If you had a device that downloaded the build uploaded to AppBlade after step 3, then after step 5 resuming the build will prompt an update to be downloaded to that devices downloads folder.   

(Simulators are not guaranteed to work with this demo)