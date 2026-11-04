package ai.nextbillion.maps_flutter;

import io.flutter.plugin.common.MethodChannel;
import java.util.Set;

/** Drops late/duplicate replies and releases the engine reply after completion. */
final class PendingResult implements MethodChannel.Result {
    private MethodChannel.Result reply;
    private final Set<PendingResult> owner;

    PendingResult(MethodChannel.Result reply, Set<PendingResult> owner) {
        this.reply = reply;
        this.owner = owner;
        owner.add(this);
    }

    private MethodChannel.Result take() {
        MethodChannel.Result value = reply;
        reply = null;
        owner.remove(this);
        return value;
    }

    @Override public void success(Object value) {
        MethodChannel.Result target = take();
        if (target != null) target.success(value);
    }

    @Override public void error(String code, String message, Object details) {
        MethodChannel.Result target = take();
        if (target != null) target.error(code, message, details);
    }

    @Override public void notImplemented() {
        MethodChannel.Result target = take();
        if (target != null) target.notImplemented();
    }
}
