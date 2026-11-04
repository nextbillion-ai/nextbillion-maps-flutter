package ai.nextbillion.maps_flutter;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import ai.nextbillion.maps.Nextbillion;
import ai.nextbillion.maps.regionaloffline.release.client.RegionalOffline;
import ai.nextbillion.maps.style.NGLDefaultMapStyle;
import ai.nextbillion.maps.style.NGLWellKnownTileServer;
import ai.nextbillion.maps.util.DefaultStyle;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * @author qiuyu
 * @Date 2023/7/13
 **/
public class NextBillionMethodHandler implements MethodChannel.MethodCallHandler {

    @NonNull
    private final Context context;

    NextBillionMethodHandler(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        this.context = binding.getApplicationContext();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        try {
        switch (call.method) {
            case "nextbillion/init_nextbillion":
                String accessToken = call.argument("accessKey");
                NbMapUtils.getNextbillion(context, accessToken);
                Nextbillion.getInstance(context, accessToken);
                NbMapUtils.setCrossPlatformInfo();
                result.success(null);
                break;
            case "nextbillion/init_nextbillion_tile_server":
                String token = call.argument("accessKey");
                String serverName = call.argument("server");
                if (serverName != null) {
                    NGLWellKnownTileServer wellKnownTileServer = NGLWellKnownTileServer.valueOf(serverName);
                    if (!canSelectServer(wellKnownTileServer, result)) break;
                    Nextbillion.getInstance(context, token, wellKnownTileServer);
                    Log.e("Styles","wellKnownTileServer : " + wellKnownTileServer);
                } else {
                    Nextbillion.getInstance(context, token);
                }
                NbMapUtils.setCrossPlatformInfo();
                result.success(null);
                break;
            case "nextbillion/get_access_key":
                String accessTokenResult = NbMapUtils.getAccessKey();
                result.success(accessTokenResult);
                break;
            case "nextbillion/set_access_key":
                String accessTokenToSet = call.argument("accessKey");
                NbMapUtils.setAccessKey(accessTokenToSet);
                result.success(null);
                break;
            case "nextbillion/get_base_uri":
                String baseUri = NbMapUtils.getBaseUri();
                result.success(baseUri);
                break;
            case "nextbillion/set_base_uri":
                String baseUriToSet = call.argument("baseUri");
                NbMapUtils.setBaseUri(baseUriToSet);
                result.success(null);
                break;
            case "nextbillion/set_key_header_name":
                String apiKeyHeaderName = call.argument("apiKeyHeaderName");
                NbMapUtils.setApiKeyHeaderName(apiKeyHeaderName);
                result.success(null);
                break;
            case "nextbillion/get_key_header_name":
                String keyHeaderName = NbMapUtils.getApiKeyHeaderName();
                result.success(keyHeaderName);
                break;
            case "nextbillion/get_nb_id":
                String nbId = NbMapUtils.getNbId();
                result.success(nbId);
                break;
            case "nextbillion/set_user_id":
                String id = call.argument("userId");
                NbMapUtils.setUserid(id);
                result.success(null);
                break;
            case "nextbillion/get_user_id":
                String userId = NbMapUtils.getUserid();
                result.success(userId);
                break;

            case "nextbillion/predefined_styles":
                try {

                    DefaultStyle[] styles = Nextbillion.getPredefinedStyles();
                    List<DefaultStyle> defaultMapStyles = styles != null ? java.util.Arrays.asList(styles) : new java.util.ArrayList<>();
                    List<Map<String, Object>> serializableStyles = new ArrayList<>();

                    if (styles != null) {
                        for (DefaultStyle style : defaultMapStyles) {
                            Map<String, Object> styleMap = new HashMap<>();
                            styleMap.put("name", style.getName());
                            styleMap.put("url", style.getUrl());
                            styleMap.put("version", style.getVersion());
                            serializableStyles.add(styleMap);
                        }
                    }

                    result.success(serializableStyles);
                } catch (Exception e) {
                    Log.e("NextBillionMethodHandler", "Error getting predefined styles", e);
                    result.error("ERROR", "Failed to get predefined styles", e.getMessage());
                }
                break;
            case "nextbillion/switch_tile_server":
                String name = call.argument("server");
                if (name != null) {
                    NGLWellKnownTileServer wellKnownTileServer = NGLWellKnownTileServer.valueOf(name);
                    if (!canSelectServer(wellKnownTileServer, result)) break;
                    Nextbillion.setWellKnownTileServer(wellKnownTileServer);
                    Log.e("Styles","wellKnownTileServer : " + wellKnownTileServer);
                    result.success(true);
                } else {
                    result.success(false);
                }
                break;
            default:
                result.notImplemented();
        }
        } catch (IllegalArgumentException error) {
            result.error("INVALID_ARGUMENT", error.getMessage(), null);
        } catch (RuntimeException error) {
            result.error("NEXTBILLION_ERROR", error.getMessage(), null);
        }
    }

    // Published Android 3.3.0 and 3.3.1 throw inside its asynchronous refresh when switching an
    // initialized Regional Offline runtime to Orbis. Fail before changing state.
    static boolean canSelectServer(NGLWellKnownTileServer server, MethodChannel.Result result) {
        if (server == NGLWellKnownTileServer.NGLTomTomOrbis &&
            (RegionalOffline.isInitialized() || RegionalOfflineHandler.isConfiguring())) {
            result.error("SDK_UPDATE_REQUIRED",
                "Android Maps 3.3.1 cannot switch to Orbis during or after Regional Offline initialization. " +
                "Use Orbis before configuring Regional Offline, or update the native SDK with the Orbis refresh fix.", null);
            return false;
        }
        return true;
    }
}
