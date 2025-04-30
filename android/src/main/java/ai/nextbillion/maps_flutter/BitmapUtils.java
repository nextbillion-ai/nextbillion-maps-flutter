package ai.nextbillion.maps_flutter;

import android.content.Context;
import android.graphics.Bitmap;
import android.net.Uri;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.Objects;

/** Created by nickitaliano on 10/9/17. */
public class BitmapUtils {
  private static final String LOG_TAG = "BitmapUtils";

  @Nullable
  public static String createTempFile(@NonNull Context context, Bitmap bitmap) {
    File tempFile = null;
    FileOutputStream outputStream = null;

    try {
      tempFile = File.createTempFile(LOG_TAG, ".jpeg", context.getCacheDir());
      outputStream = new FileOutputStream(tempFile);
    } catch (IOException e) {
      Log.w(LOG_TAG, Objects.requireNonNull(e.getLocalizedMessage()));
    }

    if (tempFile == null || outputStream == null) {
      return null;
    }

    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
    closeSnapshotOutputStream(outputStream);
    return Uri.fromFile(tempFile).toString();
  }

  public static String createBase64(@NonNull  Bitmap bitmap) {
    ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
    byte[] bitmapBytes = outputStream.toByteArray();
    closeSnapshotOutputStream(outputStream);
    String base64Prefix = "data:image/jpeg;base64,";
    return base64Prefix + Base64.encodeToString(bitmapBytes, Base64.NO_WRAP);
  }

  private static void closeSnapshotOutputStream(@Nullable OutputStream outputStream) {
    if (outputStream == null) {
      return;
    }
    try {
      outputStream.close();
    } catch (IOException e) {
      Log.e(LOG_TAG, e.toString());
    }
  }
}
