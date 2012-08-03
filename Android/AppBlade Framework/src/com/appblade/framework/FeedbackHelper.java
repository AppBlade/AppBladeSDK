package com.appblade.framework;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;

import org.apache.http.entity.ByteArrayEntity;

import org.apache.http.entity.mime.HttpMultipartMode;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.entity.mime.content.ByteArrayBody;
import org.apache.http.entity.mime.content.ContentBody;
import org.apache.http.entity.mime.content.StringBody;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.util.Log;
import android.view.Gravity;
import android.widget.EditText;

public class FeedbackHelper {

	public static String getLogData(){
		try {
			Process process = Runtime.getRuntime().exec("logcat -d");
			BufferedReader bufferedReader = new BufferedReader(
					new InputStreamReader(process.getInputStream()));

			StringBuilder log = new StringBuilder();
			String line;
			while ((line = bufferedReader.readLine()) != null) {
				log.append(line);
				log.append("\n");
			}

			return log.toString();
		} catch (IOException e) {
		}

		return "";
	}

	public static void getFeedbackData(Context context, FeedbackData data,
			final OnFeedbackDataAcquiredListener listener) {

		AlertDialog.Builder dialog = new AlertDialog.Builder(context);

		dialog.setTitle("Feedback");
//		dialog.setMessage("Feedback");

		final EditText editText = new EditText(context);
		editText.setLines(5);
		editText.setGravity(Gravity.TOP);
		editText.setHint("Enter any feedback...");

		dialog.setView(editText);
		
		if (data == null)
			data = new FeedbackData();
		
		final FeedbackData fData = data;
		
		dialog.setPositiveButton("Submit", new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int which) {
				fData.Notes = editText.getText().toString();
				listener.OnFeedbackDataAcquired(fData);
			}
		});
		
		dialog.setNegativeButton("Cancel", null);
		
		dialog.show();
	}

	public static byte[] getPostFeedbackBody(FeedbackData data, String boundary) {
		
		
		byte[] contentByte = String.format("--%s\r\n", boundary).getBytes();
		
		byte[] notesHeaderByte = String.format("Content-Disposition: form-data; name=\"feedback[notes]\"\r\n\r\n").getBytes();
		contentByte = FeedbackHelper.concatenateByteArrays(contentByte, notesHeaderByte);
		
		byte[] noteByte = data.Notes.getBytes();
		contentByte = FeedbackHelper.concatenateByteArrays(contentByte, noteByte);
		
		byte[] boundaryByte = String.format("\r\n--%s\r\n", boundary).getBytes();
		contentByte = FeedbackHelper.concatenateByteArrays(contentByte, boundaryByte);
		
		byte[] consoleHeaderByte = String.format("Content-Disposition: form-data; name=\"feedback[console]\"\r\n\r\n").getBytes();
		contentByte = FeedbackHelper.concatenateByteArrays(contentByte, consoleHeaderByte);
		byte[] consoleByte = data.Console.getBytes();
		contentByte = FeedbackHelper.concatenateByteArrays(contentByte, consoleByte);
		
		
		if (data.Screenshot != null) {
			
			contentByte = FeedbackHelper.concatenateByteArrays(contentByte, boundaryByte);
			
			if (StringUtils.isNullOrEmpty(data.ScreenshotName))
				data.ScreenshotName = "FeedbackScreenshot";
			
			byte[] screenshotHeaderByte = String.format("Content-Disposition: form-data; name=\"feedback[screenshot]\"; filename=\"base64:%s\"\r\nContent-Type: application/octet-stream\r\n\r\n", data.ScreenshotName).getBytes();
			contentByte = FeedbackHelper.concatenateByteArrays(contentByte, screenshotHeaderByte);
			byte[] screenshotRawBytes = getBytesFromBitmap(data.Screenshot);
			String encodedImage = Base64.encodeToString(screenshotRawBytes, Base64.DEFAULT);
			
			byte[] screenshotByte = encodedImage.getBytes();
			contentByte = FeedbackHelper.concatenateByteArrays(contentByte, screenshotByte);
		}
		
		byte[] boundaryEndByte = String.format("\r\n--%s--", boundary).getBytes();
		contentByte = FeedbackHelper.concatenateByteArrays(contentByte, boundaryEndByte);
		
		return contentByte;
	}
	
	public static byte[] concatenateByteArrays(byte[] a, byte[] b) {
	    byte[] result = new byte[a.length + b.length]; 
	    System.arraycopy(a, 0, result, 0, a.length); 
	    System.arraycopy(b, 0, result, a.length, b.length); 
	    return result;
	} 

	public static byte[] getBytesFromBitmap(Bitmap bitmap) {
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		bitmap.compress(CompressFormat.PNG, 100, out);
		return out.toByteArray();
	}
}
