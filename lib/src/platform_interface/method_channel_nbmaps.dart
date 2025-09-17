part of "../../nb_maps_flutter.dart";

class MethodChannelNbMapsGl extends NbMapsGlPlatform {
  late MethodChannel _channel;
  static bool useHybridComposition = false;

  @visibleForTesting
  Future<dynamic> handleMethodCall(MethodCall call) async {
    final arguments = call.arguments as Map?;
    switch (call.method) {
      case 'infoWindow#onTap':
        final String? symbolId = arguments?['symbol'] as String?;
        if (symbolId != null) {
          onInfoWindowTappedPlatform(symbolId);
        }

      case 'feature#onTap':
        final id = arguments?['id'];
        final double x = arguments?['x'] as double;
        final double y = arguments?['y'] as double;
        final double lng = arguments?['lng'] as double;
        final double lat = arguments?['lat'] as double;
        onFeatureTappedPlatform({
          'id': id,
          'point': Point<double>(x, y),
          'latLng': LatLng(lat, lng)
        });
      case 'feature#onDrag':
        final id = arguments?['id'];
        final double x = arguments?['x'] as double;
        final double y = arguments?['y'] as double;
        final double originLat = arguments?['originLat'] as double;
        final double originLng = arguments?['originLng'] as double;

        final double currentLat = arguments?['currentLat'] as double;
        final double currentLng = arguments?['currentLng'] as double;

        final double deltaLat = arguments?['deltaLat'] as double;
        final double deltaLng = arguments?['deltaLng'] as double;
        final String eventType = arguments?['eventType'] as String;

        onFeatureDraggedPlatform({
          'id': id,
          'point': Point<double>(x, y),
          'origin': LatLng(originLat, originLng),
          'current': LatLng(currentLat, currentLng),
          'delta': LatLng(deltaLat, deltaLng),
          'eventType': eventType,
        });

      case 'camera#onMoveStarted':
        onCameraMoveStartedPlatform(null);
      case 'camera#onMove':
        final position = arguments?['position'] as Map<String, dynamic>?;
        final cameraPosition = CameraPosition.fromMap(position);
        if (cameraPosition != null) {
          onCameraMovePlatform.call(cameraPosition);
        } else {}
      case 'camera#onIdle':
        final position = arguments?['position'] as Map<String, dynamic>?;
        final cameraPosition = CameraPosition.fromMap(position);
        onCameraIdlePlatform(cameraPosition);
      case 'map#onStyleLoaded':
        onMapStyleLoadedPlatform(null);
      case 'map#onMapClick':
        final double x = arguments?['x'] as double;
        final double y = arguments?['y'] as double;
        final double lng = arguments?['lng'] as double;
        final double lat = arguments?['lat'] as double;
        onMapClickPlatform(
            {'point': Point<double>(x, y), 'latLng': LatLng(lat, lng)});
      case 'map#onMapLongClick':
        final double x = arguments?['x'] as double;
        final double y = arguments?['y'] as double;
        final double lng = arguments?['lng'] as double;
        final double lat = arguments?['lat'] as double;
        onMapLongClickPlatform(
            {'point': Point<double>(x, y), 'latLng': LatLng(lat, lng)});

      case 'map#onAttributionClick':
        onAttributionClickPlatform(null);
      case 'map#onCameraTrackingChanged':
        final int mode = arguments?['mode'] as int;
        onCameraTrackingChangedPlatform(MyLocationTrackingMode.values[mode]);
      case 'map#onCameraTrackingDismissed':
        onCameraTrackingDismissedPlatform(null);
      case 'map#onIdle':
        onMapIdlePlatform(null);
      case 'map#onUserLocationUpdated':
        final userLocation = arguments?['userLocation'] as Map<String, dynamic>;
        final heading = arguments?['heading'] as Map<String, dynamic>?;

        final List<dynamic> positionDynamic = userLocation['position'] as List<dynamic>;
        final List<double> position = positionDynamic.cast<double>();
        final LatLng latLng = LatLng(position[0], position[1]);

        onUserLocationUpdatedPlatform(UserLocation(
            position: latLng,
            altitude: userLocation['altitude'] as double,
            bearing: userLocation['bearing'] as double,
            speed: userLocation['speed'] as double,
            horizontalAccuracy: userLocation['horizontalAccuracy'] as double,
            verticalAccuracy: userLocation['verticalAccuracy'] as double,
            heading: heading == null
                ? null
                : UserHeading(
                    magneticHeading: heading['magneticHeading'] as double,
                    trueHeading: heading['trueHeading'] as double,
                    headingAccuracy: heading['headingAccuracy'] as double,
                    x: heading['x'] as double,
                    y: heading['y'] as double,
                    z: heading['x'] as double,
                    timestamp: DateTime.fromMillisecondsSinceEpoch(
                        heading['timestamp'] as int),
                  ),
            timestamp: DateTime.fromMillisecondsSinceEpoch(
                userLocation['timestamp'] as int)));
      default:
        throw MissingPluginException();
    }
  }

  @override
  Future<void> initPlatform(int id) async {
    _channel = MethodChannel('plugins.flutter.io/nbmaps_maps_$id');
    _channel.setMethodCallHandler(handleMethodCall);
    await _channel.invokeMethod('map#waitForMap');
  }

  @visibleForTesting
  void setTestingMethodChanenl(MethodChannel channel) {
    _channel = channel;
    _channel.setMethodCallHandler(handleMethodCall);
  }

  @override
  Widget buildView(
      Map<String, dynamic> creationParams,
      OnPlatformViewCreatedCallback onPlatformViewCreated,
      Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final useHybridCompositionParam =
          (creationParams['useHybridCompositionOverride'] ??
              useHybridComposition) as bool;
      if (useHybridCompositionParam) {
        return PlatformViewLink(
          viewType: 'plugins.flutter.io/nb_maps_flutter',
          surfaceFactory: (
            BuildContext context,
            PlatformViewController controller,
          ) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers: gestureRecognizers ??
                  const <Factory<OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
          onCreatePlatformView: (PlatformViewCreationParams params) {
            late AndroidViewController controller;
            controller = PlatformViewsService.initAndroidView(
              id: params.id,
              viewType: 'plugins.flutter.io/nb_maps_flutter',
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () => params.onFocusChanged(true),
            );
            controller.addOnPlatformViewCreatedListener(
              params.onPlatformViewCreated,
            );
            controller.addOnPlatformViewCreatedListener(
              onPlatformViewCreated,
            );

            controller.create();
            return controller;
          },
        );
      } else {
        return AndroidView(
          viewType: 'plugins.flutter.io/nb_maps_flutter',
          onPlatformViewCreated: onPlatformViewCreated,
          gestureRecognizers: gestureRecognizers,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'plugins.flutter.io/nb_maps_flutter',
        onPlatformViewCreated: onPlatformViewCreated,
        gestureRecognizers: gestureRecognizers,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return Text(
        '$defaultTargetPlatform is not yet supported by the maps plugin');
  }

  @override
  Future<CameraPosition?> updateMapOptions(
      Map<String, dynamic> optionsUpdate) async {
    final Map<String, dynamic>? json = await _channel.invokeMethod(
      'map#update',
      <String, dynamic>{
        'options': optionsUpdate,
      },
    );
    return CameraPosition.fromMap(json);
  }

  @override
  Future<bool?> animateCamera(CameraUpdate cameraUpdate, {Duration? duration}) async {
    return await _channel.invokeMethod('camera#animate', <String, dynamic>{
      'cameraUpdate': cameraUpdate.toJson(),
      'duration': duration?.inMilliseconds,
    });
  }

  @override
  Future<bool?> moveCamera(CameraUpdate cameraUpdate) async {
    return await _channel.invokeMethod('camera#move', <String, dynamic>{
      'cameraUpdate': cameraUpdate.toJson(),
    });
  }

  @override
  Future<void> updateMyLocationTrackingMode(
      MyLocationTrackingMode myLocationTrackingMode) async {
    await _channel
        .invokeMethod('map#updateMyLocationTrackingMode', <String, dynamic>{
      'mode': myLocationTrackingMode.index,
    });
  }

  @override
  Future<void> matchMapLanguageWithDeviceDefault() async {
    await _channel.invokeMethod('map#matchMapLanguageWithDeviceDefault');
  }

  @override
  Future<void> updateContentInsets(EdgeInsets insets, bool animated) async {
    await _channel.invokeMethod('map#updateContentInsets', <String, dynamic>{
      'bounds': <String, double>{
        'top': insets.top,
        'left': insets.left,
        'bottom': insets.bottom,
        'right': insets.right,
      },
      'animated': animated,
    });
  }

  @override
  Future<void> setMapLanguage(String language) async {
    await _channel.invokeMethod('map#setMapLanguage', <String, dynamic>{
      'language': language,
    });
  }

  @override
  Future<void> setTelemetryEnabled(bool enabled) async {
    await _channel.invokeMethod('map#setTelemetryEnabled', <String, dynamic>{
      'enabled': enabled,
    });
  }

  @override
  Future<bool> getTelemetryEnabled() async {
    try {
      final result = await _channel.invokeMethod('map#getTelemetryEnabled');
      return result as bool? ?? false;
    } catch (e) {
      if (kDebugMode) {
        print("Error getting telemetry enabled: $e");
      }
      return false;
    }
  }

  @override
  Future<List<dynamic>> queryRenderedFeatures(
      Point<double> point, List<String> layerIds, List<Object>? filter) async {
    try {
      final Map? reply = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'map#queryRenderedFeatures',
        <String, Object?>{
          'x': point.x,
          'y': point.y,
          'layerIds': layerIds,
          'filter': filter,
        },
      );
      final features = reply?['features'] as List<dynamic>?;
      final decodeFeatures =  features?.map((feature) => jsonDecode(feature as String)).toList();
      if(decodeFeatures == null) {
        return [];
      }
      return decodeFeatures;
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }


  @override
  Future<List> queryRenderedFeaturesInRect(
      Rect rect, List<String> layerIds, String? filter) async {
    try {
      final Map<dynamic, dynamic>? reply = await _channel.invokeMethod(
        'map#queryRenderedFeatures',
        <String, Object?>{
          'left': rect.left,
          'top': rect.top,
          'right': rect.right,
          'bottom': rect.bottom,
          'layerIds': layerIds,
          'filter': filter,
        },
      );
      final features = reply?['features'] as List<dynamic>?;
      final decodeFeatures =  features?.map((feature) => jsonDecode(feature as String)).toList();
      if(decodeFeatures == null) {
        return [];
      }
      return decodeFeatures;
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future invalidateAmbientCache() async {
    try {
      await _channel.invokeMethod('map#invalidateAmbientCache');
      return null;
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<LatLng?> requestMyLocationLatLng() async {
    try {
      final Map<dynamic, dynamic>? reply = await _channel.invokeMethod(
          'locationComponent#getLastLocation');
      double latitude = 0.0;
      double longitude = 0.0;
      if(reply == null) {
        return null;
      }
      if (reply.containsKey('latitude') && reply['latitude'] != null) {
        latitude = double.parse(reply['latitude'].toString());
      }
      if (reply.containsKey('longitude') && reply['longitude'] != null) {
        longitude = double.parse(reply['longitude'].toString());
      }
      return LatLng(latitude, longitude);
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<LatLngBounds?> getVisibleRegion() async {
    try {
      final Map<dynamic, dynamic>? reply =
      await _channel.invokeMethod('map#getVisibleRegion');
      if (reply == null) {
        return null;
      }
      final southwest = reply['sw'] as List<dynamic>;
      final northeast = reply['ne'] as List<dynamic>;
      return LatLngBounds(
        southwest: LatLng(
          (southwest[0] as num).toDouble(),
          (southwest[1] as num).toDouble(),
        ),
        northeast: LatLng(
          (northeast[0] as num).toDouble(),
          (northeast[1] as num).toDouble(),
        ),
      );
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> addImage(String name, Uint8List bytes,
      [bool sdf = false]) async {
    try {
      return await _channel.invokeMethod('style#addImage', <String, Object>{
        'name': name,
        'bytes': bytes,
        'length': bytes.length,
        'sdf': sdf
      });
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> addImageSource(
      String imageSourceId, Uint8List bytes, LatLngQuad coordinates) async {
    try {
      return await _channel
          .invokeMethod('style#addImageSource', <String, Object>{
        'imageSourceId': imageSourceId,
        'bytes': bytes,
        'length': bytes.length,
        'coordinates': coordinates.toList().map((point) {
          return (point as List<dynamic>).map((e) => e as double).toList();
        }).toList(),
      });
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> updateImageSource(
      String imageSourceId, Uint8List? bytes, LatLngQuad? coordinates) async {
    try {
      return await _channel
          .invokeMethod('style#updateImageSource', <String, Object?>{
        'imageSourceId': imageSourceId,
        'bytes': bytes,
        'length': bytes?.length,
        'coordinates': coordinates?.toList()
      });
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<Point?> toScreenLocation(LatLng latLng) async {
    try {
      final Map<dynamic, dynamic>? screenPosMap  =
          await _channel.invokeMethod('map#toScreenLocation', <String, dynamic>{
        'latitude': latLng.latitude,
        'longitude': latLng.longitude,
      });
      if(screenPosMap == null) {
        return null;
      }
      final x = screenPosMap['x'] as double;
      final y = screenPosMap['y'] as double;
      return Point(x, y);
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<List<Point>> toScreenLocationBatch(Iterable<LatLng> latLngs) async {
    try {
      final coordinates = Float64List.fromList(latLngs
          .map((e) => [e.latitude, e.longitude])
          .expand((e) => e)
          .toList());
      final Float64List? result = await _channel.invokeMethod(
          'map#toScreenLocationBatch', {"coordinates": coordinates});

      final points = <Point>[];
      if (result == null) {
        return points;
      }
      for (int i = 0; i < result.length; i += 2) {
        points.add(Point(result[i], result[i + 1]));
      }

      return points;
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> removeSource(String sourceId) async {
    try {
      return await _channel.invokeMethod(
        'style#removeSource',
        <String, Object>{'sourceId': sourceId},
      );
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> addLayer(String imageLayerId, String imageSourceId,
      double? minzoom, double? maxzoom) async {
    try {
      return await _channel.invokeMethod('style#addLayer', <String, dynamic>{
        'imageLayerId': imageLayerId,
        'imageSourceId': imageSourceId,
        'minzoom': minzoom,
        'maxzoom': maxzoom
      });
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> addLayerBelow(String imageLayerId, String imageSourceId,
      String belowLayerId, double? minzoom, double? maxzoom) async {
    try {
      return await _channel
          .invokeMethod('style#addLayerBelow', <String, dynamic>{
        'imageLayerId': imageLayerId,
        'imageSourceId': imageSourceId,
        'belowLayerId': belowLayerId,
        'minzoom': minzoom,
        'maxzoom': maxzoom
      });
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> removeLayer(String layerId) async {
    try {
      return await _channel.invokeMethod(
          'style#removeLayer', <String, Object>{'layerId': layerId});
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> setFilter(String layerId, dynamic filter) async {
    try {
      return await _channel.invokeMethod('style#setFilter',
          <String, Object>{'layerId': layerId, 'filter': jsonEncode(filter)});
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> setVisibility(String layerId, bool isVisible) async {
    try {
      return await _channel.invokeMethod('style#setVisibility',
          <String, Object>{'layerId': layerId, 'isVisible': isVisible});
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<LatLng?> toLatLng(Point screenLocation) async {
    try {
      final Map<dynamic, dynamic>? latLngMap =
          await _channel.invokeMethod('map#toLatLng', <String, dynamic>{
        'x': screenLocation.x,
        'y': screenLocation.y,
      });
      if(latLngMap == null ) {
        return null;
      }
      final latitude = (latLngMap['latitude'] as num).toDouble() ;
      final longitude = (latLngMap['longitude'] as num).toDouble();
      return LatLng(latitude, longitude);
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<double?> getMetersPerPixelAtLatitude(double latitude) async {
    try {
      final Map<String, dynamic>? latLngMap = await _channel
          .invokeMethod('map#getMetersPerPixelAtLatitude', <String, dynamic>{
        'latitude': latitude,
      });
      if(latLngMap == null) {
        return null;
      }
      return (latLngMap['metersperpixel'] as num).toDouble();
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> addGeoJsonSource(String sourceId, Map<String, dynamic> geojson,
      {String? promoteId}) async {
    await _channel.invokeMethod('source#addGeoJson', <String, dynamic>{
      'sourceId': sourceId,
      'geojson': jsonEncode(geojson),
    });
  }

  @override
  Future<void> setGeoJsonSource(
      String sourceId, Map<String, dynamic> geojson) async {
    await _channel.invokeMethod('source#setGeoJson', <String, dynamic>{
      'sourceId': sourceId,
      'geojson': jsonEncode(geojson),
    });
  }

  @override
  Future<void> addSymbolLayer(
      String sourceId, String layerId, Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom,
      dynamic filter,
      required bool enableInteraction}) async {
    await _channel.invokeMethod('symbolLayer#add', <String, dynamic>{
      'sourceId': sourceId,
      'layerId': layerId,
      'belowLayerId': belowLayerId,
      'sourceLayer': sourceLayer,
      'minzoom': minzoom,
      'maxzoom': maxzoom,
      'filter': jsonEncode(filter),
      'enableInteraction': enableInteraction,
      'properties': properties
          .map((key, value) => MapEntry<String, String>(key, jsonEncode(value)))
    });
  }

  @override
  Future<void> addLineLayer(
      String sourceId, String layerId, Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom,
      dynamic filter,
      required bool enableInteraction}) async {
    await _channel.invokeMethod('lineLayer#add', <String, dynamic>{
      'sourceId': sourceId,
      'layerId': layerId,
      'belowLayerId': belowLayerId,
      'sourceLayer': sourceLayer,
      'minzoom': minzoom,
      'maxzoom': maxzoom,
      'filter': jsonEncode(filter),
      'enableInteraction': enableInteraction,
      'properties': properties
          .map((key, value) => MapEntry<String, String>(key, jsonEncode(value)))
    });
  }

  @override
  Future<void> addCircleLayer(
      String sourceId, String layerId, Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom,
      dynamic filter,
      required bool enableInteraction}) async {
    await _channel.invokeMethod('circleLayer#add', <String, dynamic>{
      'sourceId': sourceId,
      'layerId': layerId,
      'belowLayerId': belowLayerId,
      'sourceLayer': sourceLayer,
      'minzoom': minzoom,
      'maxzoom': maxzoom,
      'filter': jsonEncode(filter),
      'enableInteraction': enableInteraction,
      'properties': properties
          .map((key, value) => MapEntry<String, String>(key, jsonEncode(value)))
    });
  }

  @override
  Future<void> addFillLayer(
      String sourceId, String layerId, Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom,
      dynamic filter,
      required bool enableInteraction}) async {
    await _channel.invokeMethod('fillLayer#add', <String, dynamic>{
      'sourceId': sourceId,
      'layerId': layerId,
      'belowLayerId': belowLayerId,
      'sourceLayer': sourceLayer,
      'minzoom': minzoom,
      'maxzoom': maxzoom,
      'filter': jsonEncode(filter),
      'enableInteraction': enableInteraction,
      'properties': properties
          .map((key, value) => MapEntry<String, String>(key, jsonEncode(value)))
    });
  }

  @override
  Future<void> addFillExtrusionLayer(
      String sourceId, String layerId, Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom,
      dynamic filter,
      required bool enableInteraction}) async {
    await _channel.invokeMethod('fillExtrusionLayer#add', <String, dynamic>{
      'sourceId': sourceId,
      'layerId': layerId,
      'belowLayerId': belowLayerId,
      'sourceLayer': sourceLayer,
      'minzoom': minzoom,
      'maxzoom': maxzoom,
      'filter': jsonEncode(filter),
      'enableInteraction': enableInteraction,
      'properties': properties
          .map((key, value) => MapEntry<String, String>(key, jsonEncode(value)))
    });
  }

  @override
  void dispose() {
    super.dispose();
    _channel.setMethodCallHandler(null);
  }

  @override
  Future<void> addSource(String sourceId, SourceProperties properties) async {
    await _channel.invokeMethod('style#addSource', <String, dynamic>{
      'sourceId': sourceId,
      'properties': properties.toJson(),
    });
  }

  //sourceLayer is unused
  @override
  Future<void> addRasterLayer(
      String sourceId, String layerId, Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom}) async {
    await _channel.invokeMethod('rasterLayer#add', <String, dynamic>{
      'sourceId': sourceId,
      'layerId': layerId,
      'belowLayerId': belowLayerId,
      'minzoom': minzoom,
      'maxzoom': maxzoom,
      'properties': properties
          .map((key, value) => MapEntry<String, String>(key, jsonEncode(value)))
    });
  }

  //sourceLayer is unused
  @override
  Future<void> addHillshadeLayer(
      String sourceId, String layerId, Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom}) async {
    await _channel.invokeMethod('hillshadeLayer#add', <String, dynamic>{
      'sourceId': sourceId,
      'layerId': layerId,
      'belowLayerId': belowLayerId,
      'minzoom': minzoom,
      'maxzoom': maxzoom,
      'properties': properties
          .map((key, value) => MapEntry<String, String>(key, jsonEncode(value)))
    });
  }

  //sourceLayer is unused
  @override
  Future<void> addHeatmapLayer(
      String sourceId, String layerId, Map<String, dynamic> properties,
      {String? belowLayerId,
      String? sourceLayer,
      double? minzoom,
      double? maxzoom}) async {
    await _channel.invokeMethod('heatmapLayer#add', <String, dynamic>{
      'sourceId': sourceId,
      'layerId': layerId,
      'belowLayerId': belowLayerId,
      'minzoom': minzoom,
      'maxzoom': maxzoom,
      'properties': properties
          .map((key, value) => MapEntry<String, String>(key, jsonEncode(value)))
    });
  }

  @override
  Future<void> setFeatureForGeoJsonSource(
      String sourceId, Map<String, dynamic> geojsonFeature) async {
    await _channel.invokeMethod('source#setFeature', <String, dynamic>{
      'sourceId': sourceId,
      'geojsonFeature': jsonEncode(geojsonFeature)
    });
  }

  @override
  void forceResizeWebMap() {}

  @override
  void resizeWebMap() {}

  @override
  Future<String?> takeSnapshot(SnapshotOptions snapshotOptions) async {
    try {
      debugPrint("${snapshotOptions.toJson()}");
      final String? uri = await _channel.invokeMethod(
          'snapshot#takeSnapshot', snapshotOptions.toJson());
      return uri;
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<String?> findBelowLayerId(List<String> belowAt) async {
    return await _channel
        .invokeMethod('style#findBelowLayer', {"belowAt": belowAt});
  }

  @override
  Future<void> setStyleString(String styleString) async {
    try {
      final uri = await _channel
          .invokeMethod('style#setStyleString', {"styleString": styleString});
      return uri;
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }
}
