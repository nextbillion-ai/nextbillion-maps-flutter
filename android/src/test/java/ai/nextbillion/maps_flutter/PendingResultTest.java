package ai.nextbillion.maps_flutter;

import static org.junit.Assert.*;
import io.flutter.plugin.common.MethodChannel;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;
import org.junit.Test;

public class PendingResultTest {
  private static final class Reply implements MethodChannel.Result {
    int replies;
    String code;
    @Override public void success(Object value) { replies++; }
    @Override public void error(String code, String message, Object details) { replies++; this.code = code; }
    @Override public void notImplemented() { replies++; }
  }
  @Test public void completionReleasesReplyAndSuppressesDuplicates() {
    Set<PendingResult> owner = new HashSet<>();
    Reply reply = new Reply();
    PendingResult pending = new PendingResult(reply, owner);
    pending.success("imported");
    pending.error("late", null, null);
    pending.notImplemented();
    assertEquals(1, reply.replies);
    assertTrue(owner.isEmpty());
  }
  @Test public void engineDetachCancelsAllAndDiscardsLateImportCallbacks() {
    Set<PendingResult> owner = new HashSet<>();
    Reply first = new Reply();
    Reply second = new Reply();
    PendingResult a = new PendingResult(first, owner);
    PendingResult b = new PendingResult(second, owner);
    for (PendingResult pending : new ArrayList<>(owner)) pending.error("ENGINE_DETACHED", null, null);
    a.success(null);
    b.error("late", null, null);
    assertEquals(1, first.replies);
    assertEquals(1, second.replies);
    assertEquals("ENGINE_DETACHED", first.code);
    assertTrue(owner.isEmpty());
  }
  @Test public void finishingOneCallDoesNotCancelAnother() {
    Set<PendingResult> owner = new HashSet<>();
    Reply first = new Reply();
    Reply second = new Reply();
    PendingResult a = new PendingResult(first, owner);
    PendingResult b = new PendingResult(second, owner);
    a.success(null);
    assertEquals(1, owner.size());
    assertEquals(0, second.replies);
    b.success(null);
    assertTrue(owner.isEmpty());
  }
}
