package com.appblade.framework;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.Random;

import javax.crypto.BadPaddingException;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;

import org.json.JSONException;
import org.json.JSONObject;

import android.app.ProgressDialog;
import android.content.Context;
import android.graphics.Bitmap;
import android.os.AsyncTask;
import android.util.Log;
import android.widget.Toast;

public class PostFeedbackTask extends AsyncTask<FeedbackData, Void, Void>{

	Context context;
	ProgressDialog progress;
	
	Boolean success;
	FeedbackData data;
	
	private static final String SUCCESS_MESSAGE 	= "Feedback Uploaded Successfully!";
	private static final String FAIL_MESSAGE 		= "Feedback Upload Failed";
	
	public PostFeedbackTask(Context context) {
		this.context = context;
	}
	
	@Override
	protected Void doInBackground(FeedbackData... params) {
		data = params[0];
		success = AppBlade.postFeedback(data);
		
		return null;
	}
	
	@Override
	protected void onPostExecute(Void result) {
		String toastMessage = FAIL_MESSAGE;
		if (success) {
			toastMessage = SUCCESS_MESSAGE;
			
			if (!StringUtils.isNullOrEmpty(data.SavedName))
			{
				// Remove files if this was saved to disk
				
				String filePath = String.format("%s/%s", AppBlade.feedbackDir, data.SavedName);
				File file = new File(filePath);
				file.delete();
				
				String screenshotPath = String.format("%s/%s", AppBlade.feedbackDir, data.ScreenshotName);
				File screenshot = new File(screenshotPath);
				screenshot.delete();
				
			}
		}
		else {
			try {
				int r = new Random().nextInt(9999);
				String baseName = String.format("%d-%d", System.currentTimeMillis(), r);
				
				String screenshotName = String.format("img-%s.png", baseName);
				data.ScreenshotName = screenshotName;
				String screenshotPath = String.format("%s/%s", AppBlade.feedbackDir, screenshotName);
				
				
				File screenshot = new File(screenshotPath);
				if(screenshot.createNewFile())
				{
					OutputStream outStream = new FileOutputStream(screenshot);
					data.Screenshot.compress(Bitmap.CompressFormat.PNG, 100, outStream);
					outStream.flush();
					outStream.close();

				}
				
				String fileName = String.format("fb-%s.json", baseName);
				String filePath = String.format("%s/%s", AppBlade.feedbackDir, fileName);
				Log.d(AppBlade.LogTag, String.format("Saving file at path %s", filePath));
				
				JSONObject saveData = new JSONObject();
				saveData.put(FeedbackData.NOTES_KEY, data.Notes);
				saveData.put(FeedbackData.CONSOLE_KEY, data.Console);
				saveData.put(FeedbackData.SCREENSHOT_NAME_KEY, data.ScreenshotName);
				saveData.put(FeedbackData.PARAMS_KEY, new JSONObject(data.CustomParams));
				
				String jsonString = saveData.toString();
				
				byte[] cipherData = AES256Cipher.encrypt(AppBlade.ivBytes, AppBlade.AESkey.getBytes("UTF-8"), jsonString.getBytes("UTF-8"));
				String base64Text = Base64.encodeToString(cipherData, Base64.DEFAULT);
				
				File file = new File(filePath);
				if(file.createNewFile())
				{
					BufferedWriter writer = new BufferedWriter(new FileWriter(filePath));
					writer.write(base64Text);
					writer.close();
				}
			
				// Let's make sure to log all of our exceptions...
			} catch (UnsupportedEncodingException e) {
				Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
			} catch (InvalidKeyException e) {
				Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
			} catch (NoSuchAlgorithmException e) {
				Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
			} catch (NoSuchPaddingException e) {
				Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
			} catch (InvalidAlgorithmParameterException e) {
				Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
			} catch (IllegalBlockSizeException e) {
				Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
			} catch (BadPaddingException e) {
				Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
			} catch (JSONException e) {
				Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
			} catch (IOException e) {
				Log.d(AppBlade.LogTag, String.format("Ex: %s, %s", e.getClass().getCanonicalName(), e.getMessage()));
			}

		}
		
		Toast.makeText(context, toastMessage, Toast.LENGTH_SHORT).show();
	}

}
