package com.appblade.framework;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.ByteBuffer;

import org.apache.http.client.HttpClient;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.text.Layout;
import android.view.Gravity;
import android.view.View.OnClickListener;
import android.widget.EditText;
import android.widget.TextView;

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

	public static void getFeedbackData(Context context,
			final OnFeedbackDataAcquiredListener listener) {

		AlertDialog.Builder dialog = new AlertDialog.Builder(context);

		dialog.setTitle("Feedback");
//		dialog.setMessage("Feedback");

		final EditText editText = new EditText(context);
		editText.setLines(5);
		editText.setGravity(Gravity.TOP);
		editText.setHint("Enter any feedback...");

		dialog.setView(editText);
		
		dialog.setPositiveButton("Submit", new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int which) {
				FeedbackData data = new FeedbackData();
				data.Notes = editText.getText().toString();
				listener.OnFeedbackDataAcquired(data);
			}
		});
		
		dialog.setNegativeButton("Cancel", null);
		
		dialog.show();
	}

	public static String getPostFeedbackBody(FeedbackData data, String boundary) {
		StringBuffer body = new StringBuffer();

		body.append("--" + boundary + "\r\n");
		body.append("Content-Disposition: form-data; name=\"feedback[notes]\"\r\n\r\n");
		body.append(data.Notes);
		body.append("\r\n");

		body.append("--" + boundary + "\r\n");
		body.append("Content-Disposition: form-data; name=\"feedback[console]\"\r\n\r\n");
		body.append(data.Console);
		body.append("\r\n");

		if (data.Screenshot != null) {
			if (StringUtils.isNullOrEmpty(data.ScreenshotName))
				data.ScreenshotName = "FeedbackScreenshot";
			body.append("--" + boundary + "\n");
			body.append(String.format(
					"Content-Disposition: form-data; name=\"feedback[screenshot]\"; filename=\"%@\"\r\n",
					data.ScreenshotName));
			body.append("Content-Type: application/octet-stream\n");
			body.append(new String(getBytesFromBitmap(data.Screenshot)));
			body.append("\r\n");
		}
		body.append("--" + boundary + "--\r\n");


		return body.toString();
	}

	public static byte[] getBytesFromBitmap(Bitmap bitmap) {
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		bitmap.compress(CompressFormat.PNG, 100, out);
		return out.toByteArray();
	}
}
