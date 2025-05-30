part of "../nb_maps_flutter.dart";

typedef EventChannelCreator = EventChannel Function(String name);

MethodChannel globalChannel =
    MethodChannel('plugins.flutter.io/nb_maps_flutter');

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
  String regionsJson = await globalChannel.invokeMethod(
    'mergeOfflineRegions',
    <String, dynamic>{
      'path': path,
      'accessToken': accessToken,
    },
  );
  Iterable regions = json.decode(regionsJson);
  return regions.map((region) => OfflineRegion.fromMap(region)).toList();
}

Future<List<OfflineRegion>> getListOfRegions({String? accessToken}) async {
  String regionsJson = await globalChannel.invokeMethod(
    'getListOfRegions',
    <String, dynamic>{
      'accessToken': accessToken,
    },
  );
  Iterable regions = json.decode(regionsJson);
  return regions.map((region) => OfflineRegion.fromMap(region)).toList();
}

Future<OfflineRegion> updateOfflineRegionMetadata(
  int id,
  Map<String, dynamic> metadata, {
  String? accessToken,
}) async {
  final regionJson = await globalChannel.invokeMethod(
    'updateOfflineRegionMetadata',
    <String, dynamic>{
      'id': id,
      'accessToken': accessToken,
      'metadata': metadata,
    },
  );

  return OfflineRegion.fromMap(json.decode(regionJson));
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
  String channelName =
      'downloadOfflineRegion_${DateTime.now().microsecondsSinceEpoch}';

  final result = await globalChannel
      .invokeMethod('downloadOfflineRegion', <String, dynamic>{
    'accessToken': accessToken,
    'channelName': channelName,
    'definition': definition.toMap(),
    'metadata': metadata,
  });

  if (onEvent != null) {
    EventChannel eventChannel =
        eventChannelCreator?.call(channelName) ?? EventChannel('channelName');

    eventChannel.receiveBroadcastStream().handleError((error) {
      if (error is PlatformException) {
        onEvent(Error(error));
        return Error(error);
      }
      var unknownError = Error(
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
      final Map<String, dynamic> jsonData = json.decode(data);
      DownloadRegionStatus? status;
      switch (jsonData['status']) {
        case 'start':
          status = InProgress(0.0);
          break;
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
          break;
        case 'success':
          status = Success();
          break;
      }
      onEvent(status ?? (throw 'Invalid event status ${jsonData['status']}'));
    });
  }

  return OfflineRegion.fromMap(json.decode(result));
}
