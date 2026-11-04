package ai.nextbillion.maps_flutter;

import androidx.annotation.Nullable;
import com.google.gson.Gson;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import java.util.HashMap;
import java.util.Map;

public class OfflineChannelHandlerImpl implements EventChannel.StreamHandler {
  private EventChannel.EventSink sink;
  private final Gson gson = new Gson();
  private final Map<String, PendingEvent> pending = new java.util.LinkedHashMap<>();
  private final EventChannel eventChannel;
  private boolean finished;
  private final boolean enabled;
  private Runnable onDisposed;

  OfflineChannelHandlerImpl(BinaryMessenger messenger, String channelName, boolean enabled,
      Runnable onDisposed) {
    this.enabled = enabled;
    this.onDisposed = onDisposed;
    eventChannel = new EventChannel(messenger, channelName);
    if (enabled) eventChannel.setStreamHandler(this);
  }

  @Override
  public void onListen(Object arguments, EventChannel.EventSink events) {
    sink = events;
    for (PendingEvent event : pending.values()) event.send(events);
    pending.clear();
  }

  @Override
  public void onCancel(Object arguments) { dispose(); }

  void dispose() {
    finished = true;
    if (sink != null) sink.endOfStream();
    sink = null;
    pending.clear();
    eventChannel.setStreamHandler(null);
    Runnable callback = onDisposed;
    onDisposed = null;
    if (callback != null) callback.run();
  }

  void onError(String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {
    emit("error", target -> { target.error(errorCode, errorMessage, errorDetails); target.endOfStream(); });
  }

  void onSuccess() {
    Map<String, Object> body = new HashMap<>();
    body.put("status", "success");
    emit("success", target -> { target.success(gson.toJson(body)); target.endOfStream(); });
  }

  void onStart() {
    Map<String, Object> body = new HashMap<>();
    body.put("status", "start");
    emit((String) body.get("status"), target -> target.success(gson.toJson(body)));
  }

  void onProgress(double progress) {
    Map<String, Object> body = new HashMap<>();
    body.put("status", "progress");
    body.put("progress", progress);
    emit((String) body.get("status"), target -> target.success(gson.toJson(body)));
  }
  private interface PendingEvent { void send(EventChannel.EventSink target); }

  private void emit(String kind, PendingEvent event) {
    if (!enabled || finished) return;
    if ("success".equals(kind) || "error".equals(kind)) finished = true;
    if (sink != null) event.send(sink);
    else pending.put(kind, event);
  }

}
