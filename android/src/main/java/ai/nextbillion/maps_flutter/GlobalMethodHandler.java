package ai.nextbillion.maps_flutter;

import android.content.Context;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.util.Map;
import java.util.Set;
import java.util.HashMap;
import java.util.HashSet;
import java.util.ArrayList;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;
import ai.nextbillion.maps.offline.OfflineManager;
import ai.nextbillion.maps.offline.OfflineRegion;

import ai.nextbillion.maps.net.ConnectivityReceiver;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/** @noinspection ALL */
class GlobalMethodHandler implements MethodChannel.MethodCallHandler {
  private static final int BUFFER_SIZE = 8192;
  @NonNull private final Context context;
  @NonNull private final BinaryMessenger messenger;
  @Nullable private final FlutterPlugin.FlutterAssets flutterAssets;

  private final AtomicBoolean closed = new AtomicBoolean(false);
  private final Set<PendingResult> pendingResults = new HashSet<>();
  private final ExecutorService importExecutor = Executors.newSingleThreadExecutor();
  private final Handler main = new Handler(Looper.getMainLooper());
  private final Set<OfflineManagerUtils.DownloadSession> downloads = new HashSet<>();
  private final Map<String, OfflineChannelHandlerImpl> downloadChannels = new HashMap<>();

  void dispose() {
    closed.set(true);
    importExecutor.shutdownNow();
    for (PendingResult result : new ArrayList<>(pendingResults))
      result.error("ENGINE_DETACHED", "The Flutter engine was detached", null);
    for (OfflineManagerUtils.DownloadSession download : new ArrayList<>(downloads)) download.dispose();
    downloads.clear();
    for (OfflineChannelHandlerImpl channel : new ArrayList<>(downloadChannels.values())) channel.dispose();
    downloadChannels.clear();
  }

  GlobalMethodHandler(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
    this.context = binding.getApplicationContext();
    this.flutterAssets = binding.getFlutterAssets();
    this.messenger = binding.getBinaryMessenger();
  }

  @Override
  public void onMethodCall(MethodCall methodCall, @NonNull MethodChannel.Result reply) {
    final MethodChannel.Result result = new PendingResult(reply, pendingResults);
    if (closed.get()) {
      result.error("ENGINE_DETACHED", "The Flutter engine was detached", null);
      return;
    }
    try {
    String accessToken = methodCall.argument("accessToken");
    NbMapUtils.getNextbillion(context, accessToken);
    switch (methodCall.method) {
      case "installOfflineMapTiles":
        String tilesDb = methodCall.argument("tilesdb");
        if (tilesDb == null || tilesDb.isEmpty()) throw new IllegalArgumentException("tilesdb is required");
        installOfflineMapTiles(tilesDb, result);
        break;
      case "setOffline":
        boolean offline = Boolean.TRUE.equals(methodCall.argument("offline"));
        ConnectivityReceiver.instance(context).setConnected(offline ? false : null);
        result.success(null);
        break;
      case "mergeOfflineRegions":
        OfflineManagerUtils.mergeRegions(result, context, methodCall.argument("path"));
        break;
      case "setOfflineTileCountLimit":
        OfflineManagerUtils.setOfflineTileCountLimit(
            result, context, methodCall.<Number>argument("limit").longValue());
        break;
      case "setHttpHeaders":
        Map<String, String> headers = (Map<String, String>) methodCall.argument("headers");
        NbMapHttpRequestUtil.setHttpHeaders(headers, result);
        break;
      case "downloadOfflineRegion":
        // Get args from caller
        Map<String, Object> definitionMap = (Map<String, Object>) methodCall.argument("definition");
        Map<String, Object> metadataMap = (Map<String, Object>) methodCall.argument("metadata");
        String channelName = methodCall.argument("channelName");

        if (channelName == null) throw new IllegalArgumentException("channelName is required");
        OfflineChannelHandlerImpl channelHandler = new OfflineChannelHandlerImpl(messenger, channelName,
            !Boolean.FALSE.equals(methodCall.argument("observe")), () -> downloadChannels.remove(channelName));
        downloadChannels.put(channelName, channelHandler);
        final OfflineManagerUtils.DownloadSession[] holder = new OfflineManagerUtils.DownloadSession[1];
        holder[0] = new OfflineManagerUtils.DownloadSession(result, channelHandler, () -> {
          downloads.remove(holder[0]);
          if (Boolean.FALSE.equals(methodCall.argument("observe"))) channelHandler.dispose();
        });
        downloads.add(holder[0]);
        holder[0].start(context, definitionMap, metadataMap);
        break;
      case "getListOfRegions":
        OfflineManagerUtils.regionsList(result, context);
        break;
      case "updateOfflineRegionMetadata":
        // Get download region arguments from caller
        Map<String, Object> metadata = (Map<String, Object>) methodCall.argument("metadata");
        OfflineManagerUtils.updateRegionMetadata(
            result, context, methodCall.<Number>argument("id").longValue(), metadata);
        break;
      case "deleteOfflineRegion":
        OfflineManagerUtils.deleteRegion(
            result, context, methodCall.<Number>argument("id").longValue());
        break;
      default:
        result.notImplemented();
        break;
    }
    } catch (IllegalArgumentException | NullPointerException | ClassCastException error) {
      result.error("INVALID_ARGUMENT", error.getMessage(), null);
    } catch (RuntimeException error) {
      result.error("OFFLINE_ERROR", error.getMessage(), null);
    }
  }

  private void installOfflineMapTiles(String tilesDb, MethodChannel.Result result) {
    importExecutor.execute(() -> {
      File directory = null;
      try {
        directory = new File(context.getCacheDir(), "nbmap_import_" + UUID.randomUUID());
        if (!directory.mkdir()) throw new IOException("Could not create import directory");
        File database = new File(directory, "cache.db");
        try (InputStream input = openTilesDbFile(tilesDb);
             FileOutputStream output = new FileOutputStream(database)) {
          byte[] buffer = new byte[BUFFER_SIZE];
          int count;
          while ((count = input.read(buffer)) != -1) {
            if (Thread.currentThread().isInterrupted()) throw new IOException("Import cancelled");
            output.write(buffer, 0, count);
          }
        }
        final File imported = directory;
        main.post(() -> {
          if (closed.get()) { deleteImport(imported); return; }
          try {
            OfflineManager.getInstance(context).mergeOfflineRegions(database.getAbsolutePath(),
                new ImportCallback(result, imported));
          } catch (RuntimeException error) {
            deleteImport(imported);
            result.error("INSTALL_OFFLINE_TILES", error.getMessage(), null);
          }
        });
      } catch (IOException | RuntimeException error) {
        deleteImport(directory);
        main.post(() -> result.error("INSTALL_OFFLINE_TILES", error.getMessage(), null));
      }
    });
  }

  private static void deleteImport(File directory) {
    if (directory == null) return;
    File[] files = directory.listFiles();
    if (files != null) for (File file : files) file.delete();
    directory.delete();
  }

  private static final class ImportCallback implements OfflineManager.MergeOfflineRegionsCallback {
    private final MethodChannel.Result result;
    private final File directory;
    ImportCallback(MethodChannel.Result result, File directory) {
      this.result = result;
      this.directory = directory;
    }
    @Override public void onMerge(OfflineRegion[] regions) {
      deleteImport(directory);
      result.success(null);
    }
    @Override public void onError(String error) {
      deleteImport(directory);
      result.error("INSTALL_OFFLINE_TILES", error, null);
    }
  }

  private InputStream openTilesDbFile(String tilesDb) throws IOException {
    if (tilesDb.startsWith("/")) { // Absolute path.
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        return Files.newInputStream(new File(tilesDb).toPath());
      } else {
        return new FileInputStream(new File(tilesDb));
      }
    } else {
      String assetKey = flutterAssets.getAssetFilePathByName(tilesDb);
      return context.getAssets().open(assetKey);
    }
  }

}
