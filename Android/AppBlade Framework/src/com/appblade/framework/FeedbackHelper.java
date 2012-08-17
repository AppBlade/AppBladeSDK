package com.appblade.framework;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;

import org.json.JSONObject;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
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
				fData.CustomParams = AppBlade.customFields;
				listener.OnFeedbackDataAcquired(fData);
			}
		});
		
		dialog.setNegativeButton("Cancel", null);
		
		dialog.show();
	}

	public static byte[] getPostFeedbackBody(FeedbackData data, String boundary) {
		
		
		byte[] contentByte = String.format("--%s\r\n", boundary).getBytes();
		
		byte[] notesHeaderByte = String.format("Content-Disposition: form-data; name=\"feedback[notes]\"\r\n\r\n").getBytes();
		contentByte = WebServiceHelper.concatenateByteArrays(contentByte, notesHeaderByte);
		
		byte[] noteByte = data.Notes.getBytes();
		contentByte = WebServiceHelper.concatenateByteArrays(contentByte, noteByte);
		
		byte[] boundaryByte = String.format("\r\n--%s\r\n", boundary).getBytes();
		contentByte = WebServiceHelper.concatenateByteArrays(contentByte, boundaryByte);
		
		byte[] consoleHeaderByte = String.format("Content-Disposition: form-data; name=\"feedback[console]\"\r\n\r\n").getBytes();
		contentByte = WebServiceHelper.concatenateByteArrays(contentByte, consoleHeaderByte);
		byte[] consoleByte = data.Console.getBytes();
		contentByte = WebServiceHelper.concatenateByteArrays(contentByte, consoleByte);
		
		byte[] paramsHeaderByte = String.format("Content-Disposition: form-data; name=\"custom_params\"\r\nContent-Type: application/json\r\n\r\n").getBytes();
		contentByte = WebServiceHelper.concatenateByteArrays(contentByte, paramsHeaderByte);
		JSONObject customParams = new JSONObject(data.CustomParams);
		
		byte[] paramsByte = customParams.toString().getBytes();
		contentByte = WebServiceHelper.concatenateByteArrays(contentByte, paramsByte);
		
		
		if (data.Screenshot != null) {
			
			contentByte = WebServiceHelper.concatenateByteArrays(contentByte, boundaryByte);
			
			if (StringUtils.isNullOrEmpty(data.ScreenshotName))
				data.ScreenshotName = "FeedbackScreenshot";
			
			byte[] screenshotHeaderByte = String.format("Content-Disposition: form-data; name=\"feedback[screenshot]\"; filename=\"base64:%s\"\r\nContent-Type: application/octet-stream\r\n\r\n", data.ScreenshotName).getBytes();
			contentByte = WebServiceHelper.concatenateByteArrays(contentByte, screenshotHeaderByte);
			
			byte[] screenshotRawBytes = getBytesFromBitmap(data.Screenshot);
			String encodedImage = Base64.encodeToString(screenshotRawBytes, Base64.NO_WRAP);
			byte[] screenshotByte = encodedImage.getBytes();
			contentByte = WebServiceHelper.concatenateByteArrays(contentByte, screenshotByte);
		}
		
		byte[] boundaryEndByte = String.format("\r\n--%s--", boundary).getBytes();
		contentByte = WebServiceHelper.concatenateByteArrays(contentByte, boundaryEndByte);
		
		return contentByte;
	}

	public static byte[] getBytesFromBitmap(Bitmap bitmap) {
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		bitmap.compress(CompressFormat.PNG, 100, out);
		return out.toByteArray();
	}
	
	public static String GetFileExt(String FileName)
    {       
         String ext = FileName.substring((FileName.lastIndexOf(".") + 1), FileName.length());
         return ext;
    }
}
