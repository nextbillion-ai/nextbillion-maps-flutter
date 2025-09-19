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
        try {
          final id = arguments?['id'];
          final double x = (arguments?['x'] as num?)?.toDouble() ?? 0.0;
          final double y = (arguments?['y'] as num?)?.toDouble() ?? 0.0;
          final double lng = (arguments?['lng'] as num?)?.toDouble() ?? 0.0;
          final double lat = (arguments?['lat'] as num?)?.toDouble() ?? 0.0;
          onFeatureTappedPlatform({
            'id': id,
            'point': Point<double>(x, y),
            'latLng': LatLng(lat, lng)
          });
        } catch (e) {
          if (kDebugMode) {
            print('Error processing feature tap: $e');
          }
        }
      case 'feature#onDrag':
        try {
          final id = arguments?['id'];
          final double x = (arguments?['x'] as num?)?.toDouble() ?? 0.0;
          final double y = (arguments?['y'] as num?)?.toDouble() ?? 0.0;
          final double originLat = (arguments?['originLat'] as num?)?.toDouble() ?? 0.0;
          final double originLng = (arguments?['originLng'] as num?)?.toDouble() ?? 0.0;

          final double currentLat = (arguments?['currentLat'] as num?)?.toDouble() ?? 0.0;
          final double currentLng = (arguments?['currentLng'] as num?)?.toDouble() ?? 0.0;

          final double deltaLat = (arguments?['deltaLat'] as num?)?.toDouble() ?? 0.0;
          final double deltaLng = (arguments?['deltaLng'] as num?)?.toDouble() ?? 0.0;
          final String eventType = (arguments?['eventType'] as String?) ?? '';

          onFeatureDraggedPlatform({
            'id': id,
            'point': Point<double>(x, y),
            'origin': LatLng(originLat, originLng),
            'current': LatLng(currentLat, currentLng),
            'delta': LatLng(deltaLat, deltaLng),
            'eventType': eventType,
          });
        } catch (e) {
          if (kDebugMode) {
            print('Error processing feature drag: $e');
          }
        }

      case 'camera#onMoveStarted':
        onCameraMoveStartedPlatform(null);
      case 'camera#onMove':
        try {
          final dynamic positionDynamic = arguments?['position'];
          final Map<String, dynamic>? position = positionDynamic is Map
              ? Map<String, dynamic>.from(positionDynamic)
              : null;
          final cameraPosition = CameraPosition.fromMap(position);
          if (cameraPosition != null) {
            onCameraMovePlatform.call(cameraPosition);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing camera move: $e');
          }
        }
      case 'camera#onIdle':
        try {
          final dynamic positionDynamic = arguments?['position'];
          final Map<String, dynamic>? position = positionDynamic is Map
              ? Map<String, dynamic>.from(positionDynamic)
              : null;
          final cameraPosition = CameraPosition.fromMap(position);
          onCameraIdlePlatform(cameraPosition);
        } catch (e) {
          if (kDebugMode) {
            print('Error processing camera idle: $e');
          }
        }
      case 'map#onStyleLoaded':
        onMapStyleLoadedPlatform(null);
      case 'map#onMapClick':
        try {
          final double x = (arguments?['x'] as num?)?.toDouble() ?? 0.0;
          final double y = (arguments?['y'] as num?)?.toDouble() ?? 0.0;
          final double lng = (arguments?['lng'] as num?)?.toDouble() ?? 0.0;
          final double lat = (arguments?['lat'] as num?)?.toDouble() ?? 0.0;
          onMapClickPlatform(
              {'point': Point<double>(x, y), 'latLng': LatLng(lat, lng)});
        } catch (e) {
          if (kDebugMode) {
            print('Error processing map click: $e');
          }
        }
      case 'map#onMapLongClick':
        try {
          final double x = (arguments?['x'] as num?)?.toDouble() ?? 0.0;
          final double y = (arguments?['y'] as num?)?.toDouble() ?? 0.0;
          final double lng = (arguments?['lng'] as num?)?.toDouble() ?? 0.0;
          final double lat = (arguments?['lat'] as num?)?.toDouble() ?? 0.0;
          onMapLongClickPlatform(
              {'point': Point<double>(x, y), 'latLng': LatLng(lat, lng)});
        } catch (e) {
          if (kDebugMode) {
            print('Error processing map long click: $e');
          }
        }

      case 'map#onAttributionClick':
        onAttributionClickPlatform(null);
      case 'map#onCameraTrackingChanged':
        try {
          final int mode = (arguments?['mode'] as int?) ?? 0;
          if (mode >= 0 && mode < MyLocationTrackingMode.values.length) {
            onCameraTrackingChangedPlatform(MyLocationTrackingMode.values[mode]);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing camera tracking changed: $e');
          }
        }
      case 'map#onCameraTrackingDismissed':
        onCameraTrackingDismissedPlatform(null);
      case 'map#onIdle':
        onMapIdlePlatform(null);
      case 'map#onUserLocationUpdated':
        try {
          final dynamic userLocationDynamic = arguments?['userLocation'];
          final dynamic headingDynamic = arguments?['heading'];
          
          // Safely convert to Map<String, dynamic>
          final Map<String, dynamic>? userLocation = userLocationDynamic is Map 
              ? Map<String, dynamic>.from(userLocationDynamic) 
              : null;
          final Map<String, dynamic>? heading = headingDynamic is Map 
              ? Map<String, dynamic>.from(headingDynamic) 
              : null;
          
          if (userLocation == null) {
            return;
          }

          final List<dynamic>? positionDynamic = userLocation['position'] as List<dynamic>?;
          if (positionDynamic == null || positionDynamic.length < 2) {
            return;
          }
          
          final List<double> position = positionDynamic.cast<double>();
          final LatLng latLng = LatLng(position[0], position[1]);

          onUserLocationUpdatedPlatform(UserLocation(
              position: latLng,
              altitude: (userLocation['altitude'] as num?)?.toDouble() ?? 0.0,
              bearing: (userLocation['bearing'] as num?)?.toDouble() ?? 0.0,
              speed: (userLocation['speed'] as num?)?.toDouble() ?? 0.0,
              horizontalAccuracy: (userLocation['horizontalAccuracy'] as num?)?.toDouble() ?? 0.0,
              verticalAccuracy: (userLocation['verticalAccuracy'] as num?)?.toDouble() ?? 0.0,
              heading: heading == null
                  ? null
                  : UserHeading(
                      magneticHeading: (heading['magneticHeading'] as num?)?.toDouble() ?? 0.0,
                      trueHeading: (heading['trueHeading'] as num?)?.toDouble() ?? 0.0,
                      headingAccuracy: (heading['headingAccuracy'] as num?)?.toDouble() ?? 0.0,
                      x: (heading['x'] as num?)?.toDouble() ?? 0.0,
                      y: (heading['y'] as num?)?.toDouble() ?? 0.0,
                      z: (heading['z'] as num?)?.toDouble() ?? 0.0,
                      timestamp: DateTime.fromMillisecondsSinceEpoch(
                          (heading['timestamp'] as int?) ?? 0),
                    ),
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                  (userLocation['timestamp'] as int?) ?? 0)));
        } catch (e) {
          if (kDebugMode) {
            print('Error processing user location update: $e');
          }
          // Don't rethrow to avoid breaking the method channel
        }
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
    try {
      final dynamic result = await _channel.invokeMapMethod(
        'map#update',
        <String, dynamic>{
          'options': optionsUpdate,
        },
      );
      
      // Safely convert the result to Map<String, dynamic>
      final Map<String, dynamic>? json = result is Map
          ? Map<String, dynamic>.from(result)
          : null;
          
      return CameraPosition.fromMap(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating map options: $e');
      }
      return null;
    }
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
      final dynamic reply = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'map#queryRenderedFeatures',
        <String, Object?>{
          'x': point.x,
          'y': point.y,
          'layerIds': layerIds,
          'filter': filter,
        },
      );
      
      // Safely extract features from reply
      final dynamic featuresData = reply is Map ? reply['features'] : null;
      final List<dynamic>? features = featuresData is List ? featuresData : null;
      
      if (features == null) {
        return [];
      }
      
      final decodeFeatures = features.map((feature) {
        try {
          return jsonDecode(feature as String);
        } catch (e) {
          if (kDebugMode) {
            print('Error decoding feature: $e');
          }
          return null;
        }
      }).where((feature) => feature != null).toList();
      
      return decodeFeatures;
    } on PlatformException catch (e) {
      return Future.error(e);
    } catch (e) {
      if (kDebugMode) {
        print('Error querying rendered features: $e');
      }
      return [];
    }
  }


  @override
  Future<List> queryRenderedFeaturesInRect(
      Rect rect, List<String> layerIds, String? filter) async {
    try {
      final dynamic reply = await _channel.invokeMethod(
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
      
      // Safely extract features from reply
      final dynamic featuresData = reply is Map ? reply['features'] : null;
      final List<dynamic>? features = featuresData is List ? featuresData : null;
      
      if (features == null) {
        return [];
      }
      
      final decodeFeatures = features.map((feature) {
        try {
          return jsonDecode(feature as String);
        } catch (e) {
          if (kDebugMode) {
            print('Error decoding feature in rect: $e');
          }
          return null;
        }
      }).where((feature) => feature != null).toList();
      
      return decodeFeatures;
    } on PlatformException catch (e) {
      return Future.error(e);
    } catch (e) {
      if (kDebugMode) {
        print('Error querying rendered features in rect: $e');
      }
      return [];
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
      final dynamic replyDynamic = await _channel.invokeMethod(
          'locationComponent#getLastLocation');
      
      // Safely convert reply to Map
      final Map? reply = replyDynamic is Map ? replyDynamic : null;
      
      if (reply == null) {
        return null;
      }
      
      double latitude = 0.0;
      double longitude = 0.0;
      
      if (reply.containsKey('latitude') && reply['latitude'] != null) {
        try {
          latitude = (reply['latitude'] as num?)?.toDouble() ?? 
                     double.parse(reply['latitude'].toString());
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing latitude: $e');
          }
        }
      }
      
      if (reply.containsKey('longitude') && reply['longitude'] != null) {
        try {
          longitude = (reply['longitude'] as num?)?.toDouble() ?? 
                      double.parse(reply['longitude'].toString());
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing longitude: $e');
          }
        }
      }
      
      return LatLng(latitude, longitude);
    } on PlatformException catch (e) {
      return Future.error(e);
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting location: $e');
      }
      return null;
    }
  }

  @override
  Future<LatLngBounds?> getVisibleRegion() async {
    try {
      final dynamic replyDynamic = await _channel.invokeMethod('map#getVisibleRegion');
      
      // Safely convert reply to Map
      final Map? reply = replyDynamic is Map ? replyDynamic : null;
      
      if (reply == null) {
        return null;
      }
      
      final dynamic southwestData = reply['sw'];
      final dynamic northeastData = reply['ne'];
      
      final List<dynamic>? southwest = southwestData is List ? southwestData : null;
      final List<dynamic>? northeast = northeastData is List ? northeastData : null;
      
      if (southwest == null || northeast == null || 
          southwest.length < 2 || northeast.length < 2) {
        return null;
      }
      
      return LatLngBounds(
        southwest: LatLng(
          (southwest[0] as num?)?.toDouble() ?? 0.0,
          (southwest[1] as num?)?.toDouble() ?? 0.0,
        ),
        northeast: LatLng(
          (northeast[0] as num?)?.toDouble() ?? 0.0,
          (northeast[1] as num?)?.toDouble() ?? 0.0,
        ),
      );
    } on PlatformException catch (e) {
      return Future.error(e);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting visible region: $e');
      }
      return null;
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
      final dynamic screenPosMapDynamic = await _channel.invokeMethod('map#toScreenLocation', <String, dynamic>{
        'latitude': latLng.latitude,
        'longitude': latLng.longitude,
      });
      
      // Safely convert reply to Map
      final Map? screenPosMap = screenPosMapDynamic is Map ? screenPosMapDynamic : null;
      
      if (screenPosMap == null) {
        return null;
      }
      
      final double x = (screenPosMap['x'] as num?)?.toDouble() ?? 0.0;
      final double y = (screenPosMap['y'] as num?)?.toDouble() ?? 0.0;
      return Point(x, y);
    } on PlatformException catch (e) {
      return Future.error(e);
    } catch (e) {
      if (kDebugMode) {
        print('Error converting to screen location: $e');
      }
      return null;
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
      final dynamic latLngMapDynamic = await _channel.invokeMethod('map#toLatLng', <String, dynamic>{
        'x': screenLocation.x,
        'y': screenLocation.y,
      });
      
      // Safely convert reply to Map
      final Map? latLngMap = latLngMapDynamic is Map ? latLngMapDynamic : null;
      
      if (latLngMap == null) {
        return null;
      }
      
      final double latitude = (latLngMap['latitude'] as num?)?.toDouble() ?? 0.0;
      final double longitude = (latLngMap['longitude'] as num?)?.toDouble() ?? 0.0;
      return LatLng(latitude, longitude);
    } on PlatformException catch (e) {
      return Future.error(e);
    } catch (e) {
      if (kDebugMode) {
        print('Error converting to LatLng: $e');
      }
      return null;
    }
  }

  @override
  Future<double?> getMetersPerPixelAtLatitude(double latitude) async {
    try {
      final dynamic latLngMapDynamic = await _channel
          .invokeMethod('map#getMetersPerPixelAtLatitude', <String, dynamic>{
        'latitude': latitude,
      });
      
      // Safely convert reply to Map
      final Map? latLngMap = latLngMapDynamic is Map ? latLngMapDynamic : null;
      
      if (latLngMap == null) {
        return null;
      }
      
      return (latLngMap['metersperpixel'] as num?)?.toDouble() ?? 0.0;
    } on PlatformException catch (e) {
      return Future.error(e);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting meters per pixel: $e');
      }
      return null;
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

  @override
  Future<void> setStyleType(NBMapStyleType styleType) async {
    try {
      final uri = await _channel
          .invokeMethod('style#setStyleType', {"styleType": styleType.value});
      return uri;
    } on PlatformException catch (e) {
      return Future.error(e);
    }
  }
}
