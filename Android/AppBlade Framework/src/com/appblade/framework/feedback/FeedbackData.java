package com.appblade.framework.feedback;

import java.io.File;
import java.io.FileOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.IOException;

import com.appblade.framework.utils.StringUtils;

import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.graphics.BitmapFactory;

public class FeedbackData {
	public String FileName;
	public String Notes;
	public Bitmap Screenshot;
	public String ScreenshotName;
	public String ScreenshotFileLocation;

	/*
	 * Persistent storage functionality
	 */
	public void setPersistentScreenshot(Bitmap screenshot){
		this.Screenshot = screenshot;
		if(this.ScreenshotFileLocation == null){
			this.ScreenshotFileLocation = FeedbackHelper.formatNewScreenshotFileLocation();
		}

		//if we have a non null variable, write it to file
		if(this.Screenshot == null){
			//create a file to write bitmap data
			File f = new File(this.ScreenshotFileLocation);
			try {
				f.createNewFile();
			} catch (IOException e) {
				e.printStackTrace();
			}

			//Convert bitmap to byte array
			ByteArrayOutputStream bos = new ByteArrayOutputStream();
			this.Screenshot.compress(CompressFormat.PNG, 100, bos);
			byte[] bitmapdata = bos.toByteArray();
	
			//write the bytes in file
			FileOutputStream fos;
			try {
				fos = new FileOutputStream(f);
				fos.write(bitmapdata);
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		else
		{
			//setting screenshot to null means delete the file (potentially)
		}
	}
	
	public Bitmap getScreenshot(){
		if(this.Screenshot == null){
			if (StringUtils.isNullOrEmpty(this.ScreenshotFileLocation)){
				//no image stored, return null
			}
			else
			{
				// pull in out bitmap from our file location (TODO: check validity here, also. nullify if an invalid bitmap or file does not exist)
				File f = new File(this.ScreenshotFileLocation);
				if(f.exists() && f.isFile())
				{
					InputStream is = FeedbackData.class.getResourceAsStream(this.ScreenshotFileLocation);
					this.Screenshot = BitmapFactory.decodeStream(is);
					if(this.Screenshot == null){
						//bitmap couldn't be decoded, possible invalid file. remove if necessary.
					}
				}
			}
		}
		return this.Screenshot;
	}

}
