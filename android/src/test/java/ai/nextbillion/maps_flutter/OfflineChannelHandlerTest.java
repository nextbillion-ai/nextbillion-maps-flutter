package ai.nextbillion.maps_flutter;

import static org.junit.Assert.*;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.Test;

public class OfflineChannelHandlerTest {
  private static final class Messenger implements BinaryMessenger {
    final Map<String, BinaryMessageHandler> handlers = new HashMap<>();
    @Override public void send(String channel, ByteBuffer message) {}
    @Override public void send(String channel, ByteBuffer message, BinaryReply reply) {}
    @Override public void setMessageHandler(String channel, BinaryMessageHandler handler) {
      if (handler == null) handlers.remove(channel);
      else handlers.put(channel, handler);
    }
  }
  private static final class Sink implements EventChannel.EventSink {
    final List<Object> values = new ArrayList<>();
    int errors;
    String errorCode;
    int endings;
    @Override public void success(Object value) { values.add(value); }
    @Override public void error(String code, String message, Object details) { errors++; errorCode = code; }
    @Override public void endOfStream() { endings++; }
  }

  @Test public void noObserverDoesNotRegisterOrBufferEvents() {
    Messenger messenger = new Messenger();
    OfflineChannelHandlerImpl handler = new OfflineChannelHandlerImpl(messenger, "test", false, null);
    handler.onStart();
    handler.onProgress(1);
    handler.onSuccess();
    Sink sink = new Sink();
    handler.onListen(null, sink);
    assertTrue(messenger.handlers.isEmpty());
    assertTrue(sink.values.isEmpty());
    handler.dispose();
  }

  @Test public void lateSubscriptionGetsStartLatestProgressAndOneTerminal() {
    Messenger messenger = new Messenger();
    OfflineChannelHandlerImpl handler = new OfflineChannelHandlerImpl(messenger, "test", true, null);
    handler.onStart();
    handler.onProgress(10);
    handler.onProgress(20);
    handler.onSuccess();
    handler.onError("late", null, null);
    handler.onProgress(30);
    Sink sink = new Sink();
    handler.onListen(null, sink);
    assertEquals(3, sink.values.size());
    assertTrue(sink.values.get(0).toString().contains("start"));
    assertTrue(sink.values.get(1).toString().contains("20.0"));
    assertTrue(sink.values.get(2).toString().contains("success"));
    assertEquals(0, sink.errors);
    assertEquals(1, sink.endings);
    handler.dispose();
    assertTrue(messenger.handlers.isEmpty());
  }

  @Test public void deletionBeforeSubscriptionDeliversOneCancelledTerminal() {
    Messenger messenger = new Messenger();
    OfflineChannelHandlerImpl handler = new OfflineChannelHandlerImpl(messenger, "test", true, null);
    handler.onStart();
    handler.onError("CANCELLED", "Offline region was deleted", null);
    handler.onSuccess();
    Sink sink = new Sink();
    handler.onListen(null, sink);
    assertEquals(1, sink.values.size());
    assertEquals(1, sink.errors);
    assertEquals("CANCELLED", sink.errorCode);
    assertEquals(1, sink.endings);
    handler.onCancel(null);
    assertTrue(messenger.handlers.isEmpty());
  }

  @Test public void cancelAndEngineDetachReleaseHandlerOnlyOnce() {
    Messenger messenger = new Messenger();
    int[] disposed = {0};
    OfflineChannelHandlerImpl handler = new OfflineChannelHandlerImpl(messenger, "test", true, () -> disposed[0]++);
    Sink sink = new Sink();
    handler.onListen(null, sink);
    assertEquals(1, messenger.handlers.size());
    handler.onCancel(null);
    handler.dispose();
    handler.onStart();
    assertEquals(1, disposed[0]);
    assertTrue(sink.values.isEmpty());
    assertTrue(messenger.handlers.isEmpty());
  }
}
