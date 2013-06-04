package com.notappblade.updatetest;


import com.appblade.framework.AppBlade;
import android.os.Bundle;
import android.app.Activity;
import android.content.pm.PackageInfo;
import android.view.Menu;
import android.widget.TextView;

public class MainActivity extends Activity {

	

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		
		String versionString = "Currently Running Version: \n" + getAppVersion();
		TextView versionTextView = (TextView)findViewById(R.id.versionText);
		versionTextView.setText(versionString);
	}

	
	@Override
	protected void onResume()
	{
		super.onResume();
		AppBlade.checkForUpdatesIgnoreTimeout(MainActivity.this, false);
	}
	
	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.activity_main, menu);
		return true;
	}

	
	/**
	 * Helper for displaying the app version. If one exists.
	 * @return PackageInfo.versionName, if available.
	 */
	private String getAppVersion() {
		String toRet = "Not Found";
		PackageInfo info = AppBlade.getPackageInfo();
		if(info != null)
		{
			toRet = info.versionName;
		}
		return toRet;
	}

}
