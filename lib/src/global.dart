part of "../nb_maps_flutter.dart";

typedef EventChannelCreator = EventChannel Function(String name);

MethodChannel globalChannel =
    const MethodChannel('plugins.flutter.io/nb_maps_flutter');

@visibleForTesting
void setTestingGlobalChannel(MethodChannel channel) {
  globalChannel = channel;
}

/// Imports a valid SDK offline database from an asset or absolute path.
///
/// The SDK merges offline packs and their resources into the active storage
/// without replacing the live database. This does not restore an ambient-only
/// cache. Completes after import; the supplied file is left intact. Supply a
/// closed, consistent database exported from a compatible SDK.
/// iOS 2.3.3 / Android 3.3.1 require matching schema v6 for merge; the import
/// does not migrate older input databases.
/// [tilesDb] is the import source; the destination uses the SDK default storage.
/// Import completion is independent of normal map creation and style loading.
Future<void> installOfflineMapTiles(String tilesDb) async {
  await globalChannel.invokeMethod(
    'installOfflineMapTiles',
    <String, dynamic>{
      'tilesdb': tilesDb,
    },
  );
}

enum DragEventType { start, drag, end }

Future<dynamic> setOffline(
  bool offline, {
  String? accessToken,
}) =>
    globalChannel.invokeMethod(
      'setOffline',
      <String, dynamic>{
        'offline': offline,
        'accessToken': accessToken,
      },
    );

Future<void> setHttpHeaders(Map<String, String> headers) {
  return globalChannel.invokeMethod(
    'setHttpHeaders',
    <String, dynamic>{
      'headers': headers,
    },
  );
}

Future<List<OfflineRegion>> mergeOfflineRegions(
  String path, {
  String? accessToken,
}) async {
  final String regionsJson = await globalChannel.invokeMethod(
        'mergeOfflineRegions',
        <String, dynamic>{
          'path': path,
          'accessToken': accessToken,
        },
      ) ??
      '[]';

  final List<dynamic> regions = json.decode(regionsJson) as List<dynamic>;

  return regions
      .map((region) => OfflineRegion.fromMap(region as Map<String, dynamic>))
      .toList();
}

Future<List<OfflineRegion>> getListOfRegions({String? accessToken}) async {
  final regionsJson = await globalChannel.invokeMethod<String>(
        'getListOfRegions',
        {'accessToken': accessToken},
      ) ??
      '[]'; // fallback if null

  final List<dynamic> regions = json.decode(regionsJson) as List<dynamic>;

  return regions
      .map((region) => OfflineRegion.fromMap(region as Map<String, dynamic>))
      .toList();
}

Future<OfflineRegion> updateOfflineRegionMetadata(
  int id,
  Map<String, dynamic> metadata, {
  String? accessToken,
}) async {
  final regionJson = await globalChannel.invokeMethod<String>(
        'updateOfflineRegionMetadata',
        {
          'id': id,
          'accessToken': accessToken,
          'metadata': metadata,
        },
      ) ??
      '{}';

  return OfflineRegion.fromMap(json.decode(regionJson) as Map<String, dynamic>);
}

Future<dynamic> setOfflineTileCountLimit(int limit, {String? accessToken}) =>
    globalChannel.invokeMethod(
      'setOfflineTileCountLimit',
      <String, dynamic>{
        'limit': limit,
        'accessToken': accessToken,
      },
    );

Future<dynamic> deleteOfflineRegion(int id, {String? accessToken}) =>
    globalChannel.invokeMethod(
      'deleteOfflineRegion',
      <String, dynamic>{
        'id': id,
        'accessToken': accessToken,
      },
    );

/// Starts a legacy offline-pack download defined by bounds, zoom, and style.
///
/// [definition] specifies the requested map coverage. [metadata] is an optional
/// JSON-serializable application payload stored with the pack. [accessToken] is
/// an optional legacy native token argument; initialize [NextBillion] normally.
/// [onEvent], when supplied, receives progress, success, or error notifications.
/// [eventChannelCreator] overrides event-channel creation for tests and should
/// be omitted by applications.
///
/// The returned [OfflineRegion] identifies the accepted pack; it does not mean
/// downloading has finished. Observe [onEvent] for completion. iOS requires
/// TomTom for legacy downloads. These pack IDs are separate from the CDN region
/// IDs used by [RegionalOffline]; use [RegionalOffline.downloadRegion] for
/// catalog-based region downloads.
Future<OfflineRegion> downloadOfflineRegion(
  OfflineRegionDefinition definition, {
  Map<String, dynamic> metadata = const {},
  String? accessToken,
  Function(DownloadRegionStatus event)? onEvent,
  EventChannelCreator? eventChannelCreator,
}) async {
  final String channelName =
      'downloadOfflineRegion_${DateTime.now().microsecondsSinceEpoch}';

  final result = await globalChannel
      .invokeMethod('downloadOfflineRegion', <String, dynamic>{
    'accessToken': accessToken,
    'channelName': channelName,
    'definition': definition.toMap(),
    'metadata': metadata,
    'observe': onEvent != null,
  });

  if (onEvent != null) {
    final EventChannel eventChannel =
        eventChannelCreator?.call(channelName) ?? EventChannel(channelName);

    StreamSubscription<dynamic>? subscription;
    var finished = false;
    void fail(Object error) {
      if (finished) return;
      finished = true;
      subscription?.cancel();
      onEvent(Error(error is PlatformException
          ? error
          : PlatformException(
              code: 'INVALID_EVENT',
              message: 'Invalid offline download event',
              details: error.toString(),
            )));
    }

    subscription = eventChannel.receiveBroadcastStream().listen((data) {
      if (finished) return;
      DownloadRegionStatus status;
      try {
        final jsonData = json.decode(data as String) as Map<String, dynamic>;
        status = switch (jsonData['status']) {
          'start' => InProgress(0),
          'progress' => InProgress((jsonData['progress'] as num).toDouble()),
          'success' => Success(),
          _ => throw const FormatException('Unknown download status'),
        };
      } catch (error) {
        fail(error);
        return;
      }
      if (status is Success) {
        finished = true;
        subscription?.cancel();
      }
      onEvent(status);
    }, onError: fail);
  }
  final decodeResult = json.decode(result as String) as Map<String, dynamic>;
  return OfflineRegion.fromMap(decodeResult);
}
