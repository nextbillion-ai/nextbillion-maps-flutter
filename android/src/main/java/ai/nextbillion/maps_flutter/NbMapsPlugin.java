
package ai.nextbillion.maps_flutter;

import android.app.Application;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.Lifecycle;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference;
import io.flutter.plugin.common.MethodChannel;

/**
 * Plugin for controlling a set of NBMap views to be shown as overlays on top of the Flutter
 * view. The overlay should be hidden during transformations or while Flutter is rendering on top of
 * the map. A Texture drawn using NBMap bitmap snapshots can then be shown instead of the
 * overlay.
 * @noinspection ALL
 */
public class NbMapsPlugin implements FlutterPlugin, ActivityAware {

  private FlutterAssets flutterAssets;
  private MethodChannel methodChannel;
  private MethodChannel nextBillionChannel;
  private GlobalMethodHandler globalHandler;
  protected @Nullable Lifecycle lifecycle;
  private RegionalOfflineHandler regionalOfflineHandler;

  public NbMapsPlugin() {
    // no-op
  }

  // New Plugin APIs

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    flutterAssets = binding.getFlutterAssets();
    regionalOfflineHandler = new RegionalOfflineHandler(binding.getBinaryMessenger(),
        (Application) binding.getApplicationContext());

    methodChannel =
        new MethodChannel(binding.getBinaryMessenger(), "plugins.flutter.io/nb_maps_flutter");
    globalHandler = new GlobalMethodHandler(binding);
    methodChannel.setMethodCallHandler(globalHandler);

    nextBillionChannel =
            new MethodChannel(binding.getBinaryMessenger(), "plugins.flutter.io/nextbillion_init");
    nextBillionChannel.setMethodCallHandler(new NextBillionMethodHandler(binding));

    binding
        .getPlatformViewRegistry()
        .registerViewFactory(
            "plugins.flutter.io/nb_maps_flutter",
            new NbMapFactory(
                binding.getBinaryMessenger(),
                new LifecycleProvider() {
                  @Nullable
                  @Override
                  public Lifecycle getLifecycle() {
                    return lifecycle;
                  }
                  @Override
                  public FlutterAssets getFlutterAssets() { return flutterAssets; }
                }));

  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (regionalOfflineHandler != null) regionalOfflineHandler.dispose();
    regionalOfflineHandler = null;
    if (globalHandler != null) globalHandler.dispose();
    globalHandler = null;
    if (methodChannel != null) methodChannel.setMethodCallHandler(null);
    if (nextBillionChannel != null) nextBillionChannel.setMethodCallHandler(null);
    methodChannel = null;
    nextBillionChannel = null;
    flutterAssets = null;
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding);
    if (regionalOfflineHandler != null) regionalOfflineHandler.onHostLifecycleChanged(lifecycle);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivity() {
    if (regionalOfflineHandler != null) regionalOfflineHandler.onHostLifecycleChanged(null);
    lifecycle = null;
  }

//  private static final class ProxyLifecycleProvider
//      implements ActivityLifecycleCallbacks, LifecycleOwner, LifecycleProvider {
//
//    private final LifecycleRegistry lifecycle = new LifecycleRegistry(this);
//    private final int registrarActivityHashCode;
//
//    private ProxyLifecycleProvider(Activity activity) {
//      this.registrarActivityHashCode = activity.hashCode();
//      activity.getApplication().registerActivityLifecycleCallbacks(this);
//    }
//
//    @Override
//    public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
//      if (activity.hashCode() != registrarActivityHashCode) {
//        return;
//      }
//      lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_CREATE);
//    }
//
//    @Override
//    public void onActivityStarted(Activity activity) {
//      if (activity.hashCode() != registrarActivityHashCode) {
//        return;
//      }
//      lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_START);
//    }
//
//    @Override
//    public void onActivityResumed(Activity activity) {
//      if (activity.hashCode() != registrarActivityHashCode) {
//        return;
//      }
//      lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_RESUME);
//    }
//
//    @Override
//    public void onActivityPaused(Activity activity) {
//      if (activity.hashCode() != registrarActivityHashCode) {
//        return;
//      }
//      lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_PAUSE);
//    }
//
//    @Override
//    public void onActivityStopped(Activity activity) {
//      if (activity.hashCode() != registrarActivityHashCode) {
//        return;
//      }
//      lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_STOP);
//    }
//
//    @Override
//    public void onActivitySaveInstanceState(Activity activity, Bundle outState) {}
//
//    @Override
//    public void onActivityDestroyed(Activity activity) {
//      if (activity.hashCode() != registrarActivityHashCode) {
//        return;
//      }
//      activity.getApplication().unregisterActivityLifecycleCallbacks(this);
//      lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_DESTROY);
//    }
//
//    @NonNull
//    @Override
//    public Lifecycle getLifecycle() {
//      return lifecycle;
//    }
//  }

  interface LifecycleProvider {
    @Nullable
    Lifecycle getLifecycle();
    FlutterAssets getFlutterAssets();
  }

  /** Provides a static method for extracting lifecycle objects from Flutter plugin bindings. */
  public static class FlutterLifecycleAdapter {

    /**
     * Returns the lifecycle object for the activity a plugin is bound to.
     *
     * <p>Returns null if the Flutter engine version does not include the lifecycle extraction code.
     * (this probably means the Flutter engine version is too old).
     */
    @NonNull
    public static Lifecycle getActivityLifecycle(
        @NonNull ActivityPluginBinding activityPluginBinding) {
      HiddenLifecycleReference reference =
          (HiddenLifecycleReference) activityPluginBinding.getLifecycle();
      return reference.getLifecycle();
    }
  }
}
