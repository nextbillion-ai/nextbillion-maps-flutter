package ai.nextbillion.maps_flutter;


import android.content.Context;
import android.util.Log;

import androidx.annotation.Nullable;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Collections;
import java.util.WeakHashMap;

import ai.nextbillion.maps.geometry.LatLng;
import ai.nextbillion.maps.geometry.LatLngBounds;
import ai.nextbillion.maps.offline.OfflineManager;
import ai.nextbillion.maps.offline.OfflineRegion;
import ai.nextbillion.maps.offline.OfflineRegionDefinition;
import ai.nextbillion.maps.offline.OfflineRegionError;
import ai.nextbillion.maps.offline.OfflineRegionStatus;
import ai.nextbillion.maps.offline.OfflineTilePyramidRegionDefinition;
import io.flutter.plugin.common.MethodChannel;

abstract class OfflineManagerUtils {
    private static final String TAG = "OfflineManagerUtils";
    // Regions live in one process-wide SDK database, including across engines.
    // Engine handlers remain the owners; this registry must not retain sessions.
    private static final Set<DownloadSession> activeSessions =
        Collections.newSetFromMap(new WeakHashMap<>());

    static void mergeRegions(MethodChannel.Result result, Context context, String path) {
        OfflineManager.getInstance(context)
                .mergeOfflineRegions(
                        path,
                        new OfflineManager.MergeOfflineRegionsCallback() {
                            public void onMerge(OfflineRegion[] offlineRegions) {
                                if (result == null) return;
                                List<Map<String, Object>> regionsArgs = new ArrayList<>();
                                for (OfflineRegion offlineRegion : offlineRegions) {
                                    regionsArgs.add(offlineRegionToMap(offlineRegion));
                                }
                                String json = new Gson().toJson(regionsArgs);
                                result.success(json);
                            }

                            public void onError(String error) {
                                if (result == null) return;
                                result.error("mergeOfflineRegions Error", error, null);
                            }
                        });
    }

    static void setOfflineTileCountLimit(MethodChannel.Result result, Context context, long limit) {
        OfflineManager.getInstance(context).setOfflineNbmapTileCountLimit(limit);
        result.success(null);
    }

    /** A download belongs to one engine; late creation callbacks cannot restart it. */
    static final class DownloadSession implements OfflineRegion.OfflineRegionObserver {
        private MethodChannel.Result result;
        private final OfflineChannelHandlerImpl channel;
        private Runnable onFinished;
        private OfflineRegion region;
        private boolean closed;

        DownloadSession(MethodChannel.Result result, OfflineChannelHandlerImpl channel, Runnable onFinished) {
            this.result = result;
            this.channel = channel;
            this.onFinished = onFinished;
            activeSessions.add(this);
        }

        void start(Context context, Map<String, Object> definitionMap, Map<String, Object> metadataMap) {
            try {
                OfflineRegionDefinition definition = mapToRegionDefinition(definitionMap,
                    context.getResources().getDisplayMetrics().density);
                if (definition == null) throw new IllegalArgumentException("Invalid offline region definition");
                String metadata = new Gson().toJson(metadataMap == null ? new HashMap<>() : metadataMap);
                OfflineManager.getInstance(context).createOfflineRegion(definition,
                    metadata.getBytes(StandardCharsets.UTF_8), new OfflineManager.CreateOfflineRegionCallback() {
                        @Override public void onCreate(OfflineRegion created) {
                            if (closed) {
                                created.setDownloadState(OfflineRegion.STATE_INACTIVE);
                                created.setObserver(null);
                                return;
                            }
                            region = created;
                            try {
                            String encoded = new Gson().toJson(offlineRegionToMap(created));
                            MethodChannel.Result reply = result;
                            result = null;
                            reply.success(encoded);
                            channel.onStart();
                            created.setObserver(DownloadSession.this);
                            created.setDownloadState(OfflineRegion.STATE_ACTIVE);
                            } catch (RuntimeException error) {
                                if (result != null) creationError(error.getMessage());
                                else {
                                    close();
                                    channel.onError("OFFLINE_ERROR", error.getMessage(), null);
                                }
                            }
                        }
                        @Override public void onError(String error) { creationError(error); }
                    });
            } catch (RuntimeException error) { creationError(error.getMessage()); }
        }

        private void creationError(String error) {
            if (closed) return;
            MethodChannel.Result reply = result;
            result = null;
            close();
            channel.dispose();
            if (reply != null) reply.error("nbMapInvalidRegionDefinition", error, null);
        }

        @Override public void onStatusChanged(OfflineRegionStatus status) {
            if (closed) return;
            if (status.isComplete()) {
                close();
                channel.onSuccess();
            } else {
                channel.onProgress(calculateDownloadingProgress(status.getRequiredResourceCount(),
                    status.getCompletedResourceCount()));
            }
        }
        @Override public void onError(OfflineRegionError error) {
            if (closed) return;
            close();
            channel.onError("Downloading error", error.getMessage(), error.getReason());
        }
        @Override public void nbmapTileCountLimitExceeded(long limit) {
            if (closed) return;
            close();
            channel.onError("nbMapTileCountLimitExceeded", "Tile count limit exceeded: " + limit, null);
        }
        private void close() {
            if (closed) return;
            closed = true;
            result = null;
            activeSessions.remove(this);
            OfflineRegion current = region;
            region = null;
            Runnable callback = onFinished;
            onFinished = null;
            try {
                if (current != null) {
                    // Detach before changing state to avoid reentrant terminal callbacks.
                    try { current.setObserver(null); }
                    finally { current.setDownloadState(OfflineRegion.STATE_INACTIVE); }
                }
            } catch (RuntimeException error) {
                Log.w(TAG, "Could not stop the offline region", error);
            } finally {
                if (callback != null) callback.run();
            }
        }
        void cancelForDeletion() {
            close();
            channel.onError("CANCELLED", "Offline region was deleted", null);
        }
        void dispose() { close(); channel.dispose(); }
    }

    static void regionsList(MethodChannel.Result result, Context context) {
        OfflineManager.getInstance(context)
                .listOfflineRegions(
                        new OfflineManager.ListOfflineRegionsCallback() {
                            @Override
                            public void onList(OfflineRegion[] offlineRegions) {
                                List<Map<String, Object>> regionsArgs = new ArrayList<>();
                                for (OfflineRegion offlineRegion : offlineRegions) {
                                    regionsArgs.add(offlineRegionToMap(offlineRegion));
                                }
                                result.success(new Gson().toJson(regionsArgs));
                            }

                            @Override
                            public void onError(String error) {
                                result.error("RegionListError", error, null);
                            }
                        });
    }

    static void updateRegionMetadata(
            MethodChannel.Result result, Context context, long id, Map<String, Object> metadataMap) {
        OfflineManager.getInstance(context)
                .listOfflineRegions(
                        new OfflineManager.ListOfflineRegionsCallback() {
                            @Override
                            public void onList(OfflineRegion[] offlineRegions) {
                                for (OfflineRegion offlineRegion : offlineRegions) {
                                    if (offlineRegion.getId() != id) continue;

                                    String metadata = "{}";
                                    if (metadataMap != null) {
                                        metadata = new Gson().toJson(metadataMap);
                                    }
                                    offlineRegion.updateMetadata(
                                            metadata.getBytes(),
                                            new OfflineRegion.OfflineRegionUpdateMetadataCallback() {
                                                @Override
                                                public void onUpdate(byte[] metadataBytes) {
                                                    Map<String, Object> regionData = offlineRegionToMap(offlineRegion);
                                                    regionData.put("metadata", metadataBytesToMap(metadataBytes));

                                                    if (result == null) return;
                                                    result.success(new Gson().toJson(regionData));
                                                }

                                                @Override
                                                public void onError(String error) {
                                                    if (result == null) return;
                                                    result.error("UpdateMetadataError", error, null);
                                                }
                                            });
                                    return;
                                }
                                if (result == null) return;
                                result.error(
                                        "UpdateMetadataError",
                                        "There is no " + "region with given id to " + "update.",
                                        null);
                            }

                            @Override
                            public void onError(String error) {
                                if (result == null) return;
                                result.error("RegionListError", error, null);
                            }
                        });
    }

    static void deleteRegion(MethodChannel.Result result, Context context, long id) {
        // listOfflineRegions returns different wrappers for the same database row.
        // Stop the original download wrapper before deleting through a list wrapper.
        for (DownloadSession session : new ArrayList<>(activeSessions)) {
            if (session.region != null && session.region.getId() == id) session.cancelForDeletion();
        }
        OfflineManager.getInstance(context)
                .listOfflineRegions(
                        new OfflineManager.ListOfflineRegionsCallback() {
                            @Override
                            public void onList(OfflineRegion[] offlineRegions) {
                                for (OfflineRegion offlineRegion : offlineRegions) {
                                    if (offlineRegion.getId() != id) continue;

                                    offlineRegion.delete(
                                            new OfflineRegion.OfflineRegionDeleteCallback() {
                                                @Override
                                                public void onDelete() {
                                                    if (result == null) return;
                                                    result.success(null);
                                                }

                                                @Override
                                                public void onError(String error) {
                                                    if (result == null) return;
                                                    result.error("DeleteRegionError", error, null);
                                                }
                                            });
                                    return;
                                }
                                if (result == null) return;
                                result.error(
                                        "DeleteRegionError",
                                        "There is no " + "region with given id to " + "delete.",
                                        null);
                            }

                            @Override
                            public void onError(String error) {
                                if (result == null) return;
                                result.error("RegionListError", error, null);
                            }
                        });
    }

    protected static double calculateDownloadingProgress(
            long requiredResourceCount, long completedResourceCount) {
        return requiredResourceCount > 0
                ? (100.0 * completedResourceCount / requiredResourceCount)
                : 0.0;
    }

    private static @Nullable OfflineRegionDefinition mapToRegionDefinition(
            Map<String, Object> map, float pixelDensity) {
        // Create a bounding box for the offline region
        if (map == null) return null;
        String mapStyleUrl = (String) map.get("mapStyleUrl");

        Object boundsObj = map.get("bounds");
        Object minZoomObj = map.get("minZoom");
        Object maxZoomObj = map.get("maxZoom");
        Object includeIdeographsObj = map.get("includeIdeographs");

        if (mapStyleUrl == null || boundsObj == null || minZoomObj == null || maxZoomObj == null || includeIdeographsObj == null) {
            return null;
        }
        double minZoom = ((Number) minZoomObj).doubleValue();
        double maxZoom = ((Number) maxZoomObj).doubleValue();
        boolean includeIdeographs = (Boolean) includeIdeographsObj;

        List<List<Double>> bounds = new ArrayList<>();
        if (boundsObj instanceof List) {
            for (Object item : (List<?>) boundsObj) {
                if (item instanceof List) {
                    List<?> point = (List<?>) item;
                    if (point.size() == 2 && point.get(0) instanceof Number && point.get(1) instanceof Number) {
                        bounds.add(Arrays.asList(
                                ((Number) point.get(0)).doubleValue(),
                                ((Number) point.get(1)).doubleValue()
                        ));
                    }
                }
            }
        }

        if (bounds.size() != 2 || Double.isNaN(minZoom) || Double.isInfinite(minZoom)
                || Double.isNaN(maxZoom) || Double.isInfinite(maxZoom)
                || minZoom < 0 || maxZoom < minZoom) return null;
        return new OfflineTilePyramidRegionDefinition(
                mapStyleUrl,
                listToBounds(bounds),
                minZoom,
                maxZoom,
                pixelDensity,
                includeIdeographs
        );
    }

    static LatLngBounds listToBounds(List<List<Double>> bounds) {
        return new LatLngBounds.Builder()
                .include(new LatLng(bounds.get(1).get(0), bounds.get(1).get(1))) // Northeast
                .include(new LatLng(bounds.get(0).get(0), bounds.get(0).get(1))) // Southwest
                .build();
    }

    static Map<String, Object> offlineRegionToMap(OfflineRegion region) {
        Map<String, Object> result = new HashMap<>();
        result.put("id", region.getId());
        result.put("definition", offlineRegionDefinitionToMap(region.getDefinition()));
        result.put("metadata", metadataBytesToMap(region.getMetadata()));
        return result;
    }

    static Map<String, Object> offlineRegionDefinitionToMap(
            OfflineRegionDefinition definition) {
        Map<String, Object> result = new HashMap<>();
        result.put("mapStyleUrl", definition.getStyleURL());
        result.put("bounds", boundsToList(definition.getBounds()));
        result.put("minZoom", definition.getMinZoom());
        result.put("maxZoom", definition.getMaxZoom());
        result.put("includeIdeographs", definition.getIncludeIdeographs());
        return result;
    }

    static List<List<Double>> boundsToList(LatLngBounds bounds) {
        List<List<Double>> boundsList = new ArrayList<>();
        List<Double> northeast = Arrays.asList(bounds.getLatNorth(), bounds.getLonEast());
        List<Double> southwest = Arrays.asList(bounds.getLatSouth(), bounds.getLonWest());
        boundsList.add(southwest);
        boundsList.add(northeast);
        return boundsList;
    }

    static HashMap<String, Object> metadataBytesToMap(byte[] metadataBytes) {
        if (metadataBytes != null) {
            String json = new String(metadataBytes, StandardCharsets.UTF_8);
            Type type = new TypeToken<HashMap<String, Object>>() {}.getType();
            try {
                HashMap<String, Object> metadata = new Gson().fromJson(json, type);
                return metadata == null ? new HashMap<>() : metadata;
            } catch (com.google.gson.JsonParseException error) {
                Log.w(TAG, "Ignoring invalid offline region metadata", error);
            }
        }
        return new HashMap<>();
    }
}
