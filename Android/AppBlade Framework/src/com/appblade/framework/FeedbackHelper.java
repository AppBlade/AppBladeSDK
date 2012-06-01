package com.appblade.framework;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;

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

	public static MultipartEntity getPostFeedbackBody(FeedbackData data, String boundary) {
		MultipartEntity entity = new MultipartEntity(HttpMultipartMode.BROWSER_COMPATIBLE, boundary, null);
		
		try
		{
		ContentBody notesBody = new StringBody(data.Notes);
		entity.addPart("feedback[notes]", notesBody);

		ContentBody consoleBody = new StringBody(data.Console);
		entity.addPart("feedback[console]", consoleBody);
		
		if (data.Screenshot != null) {
			if (StringUtils.isNullOrEmpty(data.ScreenshotName))
				data.ScreenshotName = "FeedbackScreenshot";
			
			byte[] screenshotBytes = getBytesFromBitmap(data.Screenshot);
			ContentBody screenshotBody = new ByteArrayBody(screenshotBytes, "application/octet-stream");
			entity.addPart("feedback[screenshot]", screenshotBody);
		}
		} catch (IOException e) {
			Log.d(AppBlade.LogTag, e.toString());
		}
		
		return entity;
	}

	public static byte[] getBytesFromBitmap(Bitmap bitmap) {
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		bitmap.compress(CompressFormat.PNG, 100, out);
		return out.toByteArray();
	}
}
