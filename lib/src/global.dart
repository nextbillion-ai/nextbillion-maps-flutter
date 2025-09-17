part of "../nb_maps_flutter.dart";

typedef EventChannelCreator = EventChannel Function(String name);

MethodChannel globalChannel =
    const MethodChannel('plugins.flutter.io/nb_maps_flutter');

@visibleForTesting
void setTestingGlobalChannel(MethodChannel channel) {
  globalChannel = channel;
}

/// Copy tiles db file passed in to the tiles cache directory (sideloaded) to
/// make tiles available offline.
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
  ) ?? '[]';


  final List<dynamic> regions = json.decode(regionsJson) as List<dynamic>;

  return regions
      .map((region) => OfflineRegion.fromMap(region as Map<String, dynamic>))
      .toList();
}


Future<List<OfflineRegion>> getListOfRegions({String? accessToken}) async {
  final regionsJson = await globalChannel.invokeMethod<String>(
    'getListOfRegions',
    {'accessToken': accessToken},
  ) ?? '[]'; // fallback if null

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
  ) ?? '{}';

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
  });

  if (onEvent != null) {
    final EventChannel eventChannel =
        eventChannelCreator?.call(channelName) ?? const EventChannel('channelName');

    eventChannel.receiveBroadcastStream().handleError((error) {
      if (error is PlatformException) {
        onEvent(Error(error));
        return Error(error);
      }
      final unknownError = Error(
        PlatformException(
          code: 'UnknowException',
          message:
              'This error is unhandled by plugin. Please contact us if needed.',
          details: error,
        ),
      );
      onEvent(unknownError);
      return unknownError;
    }).listen((data) {
      final Map<String, dynamic> jsonData = json.decode(data as String) as Map<String, dynamic> ;
      DownloadRegionStatus? status;
      switch (jsonData['status']) {
        case 'start':
          status = InProgress(0.0);
        case 'progress':
          final dynamic value = jsonData['progress'];
          double progress = 0.0;

          if (value is int) {
            progress = value.toDouble();
          }

          if (value is double) {
            progress = value;
          }

          status = InProgress(progress);
        case 'success':
          status = Success();
      }
      onEvent(status ?? (throw 'Invalid event status ${jsonData['status']}'));
    });
  }
  final decodeResult  = json.decode(result as String) as Map<String, dynamic> ;
  return OfflineRegion.fromMap(decodeResult);
}
