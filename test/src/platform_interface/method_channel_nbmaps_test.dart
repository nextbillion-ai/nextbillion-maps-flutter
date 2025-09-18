import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

import 'nextbillion_test.mocks.dart';

// @GenerateMocks([MethodChannel])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MethodChannelNbMapsGl nbMapsGlChannel;
  late MockMethodChannel channel;

  setUp(() {
    // Create a mock channel
    channel = MockMethodChannel();
    // Set the mock channel to the platform channel
    nbMapsGlChannel = MethodChannelNbMapsGl();
    nbMapsGlChannel.setTestingMethodChanenl(channel);
  });

  test('verify updateMapOptions', () async {
    final options = NextBillionMapOptions(
      compassEnabled: true,
      cameraTargetBounds: CameraTargetBounds(
        LatLngBounds(
          southwest: const LatLng(37.7749, -122.4194),
          northeast: const LatLng(37.8095, -122.3927),
        ),
      ),
      styleString: 'https://example.com/mapstyle',
      minMaxZoomPreference: const MinMaxZoomPreference(10.0, 15.0),
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
      doubleClickZoomEnabled: true,
      trackCameraPosition: true,
      myLocationEnabled: true,
      myLocationTrackingMode: MyLocationTrackingMode.none,
      myLocationRenderMode: MyLocationRenderMode.normal,
      logoViewMargins: const Point(10, 10),
      compassViewPosition: CompassViewPosition.bottomLeft,
      compassViewMargins: const Point(5, 5),
      attributionButtonPosition: AttributionButtonPosition.bottomRight,
      attributionButtonMargins: const Point(5, 5),
    );

    const expectedCameraPosition = CameraPosition(
      target: LatLng(37.7749, -122.4194),
      zoom: 15.0,
      bearing: 2.0,
      tilt: 3.0,
    );

    when(channel.invokeMapMethod<String, dynamic>('map#update', any))
        .thenAnswer((_) async => expectedCameraPosition.toMap());

    final result = await nbMapsGlChannel.updateMapOptions(options.toMap());
    expect(result, equals(expectedCameraPosition));
  });

  test('animateCamera', () async {
    final cameraUpdate = CameraUpdate.newCameraPosition(
      const CameraPosition(
        target: LatLng(37.7749, -122.4194),
        zoom: 15.0,
        bearing: 2.0,
        tilt: 3.0,
      ),
    );

    when(channel.invokeMethod<bool?>('camera#animate', any))
        .thenAnswer((_) async => true);

    await nbMapsGlChannel.animateCamera(cameraUpdate);

    final args = <String, dynamic>{
      'cameraUpdate': cameraUpdate.toJson(),
      'duration': null,
    };

    verify(channel.invokeMethod('camera#animate', args)).called(1);
  });

  test('test moveCamera', () async {
    final cameraUpdate = CameraUpdate.newCameraPosition(
      const CameraPosition(
        target: LatLng(37.7749, -122.4194),
        zoom: 15.0,
        bearing: 2.0,
        tilt: 3.0,
      ),
    );

    when(channel.invokeMethod<bool?>('camera#move', any))
        .thenAnswer((_) async => true);

    await nbMapsGlChannel.moveCamera(cameraUpdate);

    final args = <String, dynamic>{
      'cameraUpdate': cameraUpdate.toJson(),
    };

    verify(channel.invokeMethod('camera#move', args)).called(1);
  });

  test('updateMyLocationTrackingMode', () async {
    const myLocationTrackingMode = MyLocationTrackingMode.none;

    when(channel.invokeMethod<void>('map#updateMyLocationTrackingMode', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.updateMyLocationTrackingMode(myLocationTrackingMode);

    final args = <String, dynamic>{
      'mode': myLocationTrackingMode.index,
    };

    verify(channel.invokeMethod('map#updateMyLocationTrackingMode', args))
        .called(1);
  });

  test('matchMapLanguageWithDeviceDefault', () async {
    when(channel.invokeMethod<void>('map#matchMapLanguageWithDeviceDefault'))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.matchMapLanguageWithDeviceDefault();

    verify(channel.invokeMethod('map#matchMapLanguageWithDeviceDefault'))
        .called(1);
  });

  test('updateContentInsets', () async {
    const insets = EdgeInsets.only(
      left: 10.0,
      top: 10.0,
      right: 10.0,
      bottom: 10.0,
    );

    when(channel.invokeMethod<void>('map#updateContentInsets', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.updateContentInsets(insets, false);

    const args = <String, dynamic>{
      'bounds': <String, double>{
        'left': 10.0,
        'top': 10.0,
        'right': 10.0,
        'bottom': 10.0,
      },
      'animated': false,
    };

    verify(channel.invokeMethod('map#updateContentInsets', args)).called(1);
  });

  test('setMapLanguage', () async {
    const language = 'en';

    when(channel.invokeMethod<void>('map#setMapLanguage', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.setMapLanguage(language);

    const args = <String, dynamic>{
      'language': language,
    };

    verify(channel.invokeMethod('map#setMapLanguage', args)).called(1);
  });

  test('setTelemetryEnabled', () async {
    const enabled = true;

    when(channel.invokeMethod<void>('map#setTelemetryEnabled', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.setTelemetryEnabled(enabled);

    const args = <String, dynamic>{
      'enabled': enabled,
    };

    verify(channel.invokeMethod('map#setTelemetryEnabled', args)).called(1);
  });

  test('getTelemetryEnabled', () async {
    const enabled = true;

    when(channel.invokeMethod<bool>('map#getTelemetryEnabled'))
        .thenAnswer((_) async => enabled);

    final result = await nbMapsGlChannel.getTelemetryEnabled();

    expect(result, equals(enabled));
  });

  test('queryRenderedFeatures', () async {
    const point = Point<double>(10.0, 10.0);
    const layerIds = <String>['layerId'];

    when(channel.invokeMethod<Map<dynamic, dynamic>>(
            'map#queryRenderedFeatures', any))
        .thenAnswer((_) async => {
              'features': [],
            });

    await nbMapsGlChannel.queryRenderedFeatures(point, layerIds, null);

    final args = <String, Object?>{
      'x': point.x,
      'y': point.y,
      'layerIds': layerIds,
      'filter': null,
    };

    verify(channel.invokeMethod('map#queryRenderedFeatures', args)).called(1);
  });

  test('queryRenderedFeaturesInRect', () async {
    const rect = Rect.fromLTWH(10.0, 10.0, 10.0, 10.0);
    const layerIds = <String>['layerId'];

    when(channel.invokeMethod<Map<dynamic, dynamic>>(
            'map#queryRenderedFeatures', any))
        .thenAnswer((_) async => {
              'features': [],
            });

    await nbMapsGlChannel.queryRenderedFeaturesInRect(rect, layerIds, null);

    final args = <String, Object?>{
      'left': rect.left,
      'top': rect.top,
      'right': rect.right,
      'bottom': rect.bottom,
      'layerIds': layerIds,
      'filter': null,
    };

    verify(channel.invokeMethod('map#queryRenderedFeatures', args)).called(1);
  });

  test('invalidateAmbientCache', () async {
    when(channel.invokeMethod<void>('map#invalidateAmbientCache'))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.invalidateAmbientCache();

    verify(channel.invokeMethod('map#invalidateAmbientCache')).called(1);
  });

  test('requestMyLocationLatLng', () async {
    const latLng = LatLng(37.7749, -122.4194);

    when(channel.invokeMethod<Map<dynamic, dynamic>>(
            'locationComponent#getLastLocation'))
        .thenAnswer((_) async => {
              'latitude': latLng.latitude,
              'longitude': latLng.longitude,
            });

    final result = await nbMapsGlChannel.requestMyLocationLatLng();

    expect(result, equals(latLng));
  });

  test('getVisibleRegion', () async {
    final bounds = LatLngBounds(
      southwest: const LatLng(37.7749, -122.4194),
      northeast: const LatLng(37.8095, -122.3927),
    );

    when(channel.invokeMethod<Map<dynamic, dynamic>>('map#getVisibleRegion'))
        .thenAnswer((_) async => {
              'sw': bounds.southwest.toJson(),
              'ne': bounds.northeast.toJson(),
            });

    final result = await nbMapsGlChannel.getVisibleRegion();

    expect(result, equals(bounds));
  });

  test('addImage', () async {
    final byteData = ByteData(1);
    const name = 'name';
    const sdf = false;
    final data = byteData.buffer.asUint8List();

    when(channel.invokeMethod<void>('style#addImage', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.addImage(name, data);

    final args = <String, Object?>{
      'name': name,
      'bytes': data,
      'length': data.length,
      'sdf': sdf,
    };

    verify(channel.invokeMethod('style#addImage', args)).called(1);
  });

  test('test addImageSource', () async {
    const sourceId = 'sourceId';
    final bytes = Uint8List(1);
    const coordinates = LatLngQuad(
      topLeft: LatLng(37.7749, -122.4194),
      topRight: LatLng(37.7749, -122.3927),
      bottomRight: LatLng(37.8095, -122.3927),
      bottomLeft: LatLng(37.8095, -122.4194),
    );

    when(channel.invokeMethod<void>('style#addImageSource', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.addImageSource(sourceId, bytes, coordinates);

    final args = <String, dynamic>{
      'imageSourceId': sourceId,
      'bytes': bytes,
      'length': bytes.length,
      'coordinates': coordinates.toList()
    };

    verify(channel.invokeMethod('style#addImageSource', args)).called(1);
  });

  test('test updateImageSource', () async {
    const sourceId = 'sourceId';
    final bytes = Uint8List(1);
    const coordinates = LatLngQuad(
      topLeft: LatLng(37.7749, -122.4194),
      topRight: LatLng(37.7749, -122.3927),
      bottomRight: LatLng(37.8095, -122.3927),
      bottomLeft: LatLng(37.8095, -122.4194),
    );

    when(channel.invokeMethod<void>('style#updateImageSource', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.updateImageSource(sourceId, bytes, coordinates);

    final args = <String, dynamic>{
      'imageSourceId': sourceId,
      'bytes': bytes,
      'length': bytes.length,
      'coordinates': coordinates.toList()
    };

    verify(channel.invokeMethod('style#updateImageSource', args)).called(1);
  });

  test('test toScreenLocation', () async {
    const latLng = LatLng(37.7749, -122.4194);
    const point = Point<double>(10.0, 10.0);

    when(channel.invokeMethod<Map<dynamic, dynamic>>(
            'map#toScreenLocation', any))
        .thenAnswer((_) async => {
              'x': point.x,
              'y': point.y,
            });

    final result = await nbMapsGlChannel.toScreenLocation(latLng);

    expect(result, equals(point));
  });

  test('test toScreenLocationBatch', () async {
    const latLngs = <LatLng>[
      LatLng(37.7749, -122.4194),
      LatLng(37.7749, -122.3927),
    ];
    const points = <Point<double>>[
      Point<double>(10.0, 10.0),
      Point<double>(20.0, 20.0),
    ];

    when(channel.invokeMethod<List<dynamic>>('map#toScreenLocationBatch', any))
        .thenAnswer((_) async => Float64List.fromList([
              points[0].x,
              points[0].y,
              points[1].x,
              points[1].y,
            ]));

    final result = await nbMapsGlChannel.toScreenLocationBatch(latLngs);

    expect(result, equals(points));
  });

  test('removeSource', () async {
    const sourceId = 'sourceId';

    when(channel.invokeMethod<void>('style#removeSource', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.removeSource(sourceId);

    const args = <String, Object>{
      'sourceId': sourceId,
    };

    verify(channel.invokeMethod('style#removeSource', args)).called(1);
  });

  test('test addLayer', () async {
    const imageLayerId = 'imageLayerId';
    const imageSourceId = 'imageSourceId';
    const minzoom = 1.0;
    const maxzoom = 2.0;

    when(channel.invokeMethod<void>('style#addLayer', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.addLayer(
        imageLayerId, imageSourceId, minzoom, maxzoom);

    const args = <String, Object>{
      'imageLayerId': imageLayerId,
      'imageSourceId': imageSourceId,
      'minzoom': minzoom,
      'maxzoom': maxzoom
    };

    verify(channel.invokeMethod('style#addLayer', args)).called(1);
  });

  test('test removeLayer', () async {
    const layerId = 'layerId';

    when(channel.invokeMethod<void>('style#removeLayer', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.removeLayer(layerId);

    const args = <String, Object>{
      'layerId': layerId,
    };

    verify(channel.invokeMethod('style#removeLayer', args)).called(1);
  });

  test('addLayerBelow', () async {
    const imageLayerId = 'imageLayerId';
    const imageSourceId = 'imageSourceId';
    const belowLayerId = 'belowLayerId';
    const minzoom = 1.0;
    const maxzoom = 2.0;

    when(channel.invokeMethod<void>('style#addLayerBelow', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.addLayerBelow(
        imageLayerId, imageSourceId, belowLayerId, minzoom, maxzoom);

    const args = <String, Object>{
      'imageLayerId': imageLayerId,
      'imageSourceId': imageSourceId,
      'belowLayerId': belowLayerId,
      'minzoom': minzoom,
      'maxzoom': maxzoom
    };

    verify(channel.invokeMethod('style#addLayerBelow', args)).called(1);
  });

  test('setFilter', () async {
    const layerId = 'layerId';
    const filter = ['==', 'name', 'Doe'];

    when(channel.invokeMethod<void>('style#setFilter', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.setFilter(layerId, filter);

    final args = <String, Object>{
      'layerId': layerId,
      'filter': jsonEncode(filter),
    };

    verify(channel.invokeMethod('style#setFilter', args)).called(1);
  });

  test('test setVisibility', () async {
    const layerId = 'layerId';
    const isVisible = true;

    when(channel.invokeMethod<void>('style#setVisibility', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.setVisibility(layerId, isVisible);

    const args = <String, Object>{
      'layerId': layerId,
      'isVisible': isVisible,
    };

    verify(channel.invokeMethod('style#setVisibility', args)).called(1);
  });

  test('toLatLng', () async {
    const screenLocation = Point<double>(10.0, 10.0);
    const latLng = LatLng(37.7749, -122.4194);
    final args = <dynamic, dynamic>{
      'x': screenLocation.x,
      'y': screenLocation.y,
    };

    when(channel.invokeMethod<Map<dynamic, dynamic>>('map#toLatLng', any))
        .thenAnswer((_) async => {
              'latitude': latLng.latitude,
              'longitude': latLng.longitude,
            });

    final result = await nbMapsGlChannel.toLatLng(screenLocation);

    expect(result, equals(latLng));
    verify(channel.invokeMethod('map#toLatLng', args)).called(1);
  });

  test('test getMetersPerPixelAtLatitude', () async {
    const latitude = 37.7749;
    const expectedMetersPerPixel = 152.8740565703525;

    when(channel.invokeMethod<Map<String, dynamic>>(
            'map#getMetersPerPixelAtLatitude', any))
        .thenAnswer((_) async => {'metersperpixel': expectedMetersPerPixel});

    final result = await nbMapsGlChannel.getMetersPerPixelAtLatitude(
      latitude,
    );

    expect(result, equals(expectedMetersPerPixel));
  });

  test('test addGeoJsonSource', () async {
    const sourceId = 'sourceId';
    const geoJson = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [-122.4194, 37.7749],
          },
          'properties': {
            'name': 'Doe',
          },
        },
      ],
    };

    when(channel.invokeMethod<void>('source#addGeoJson', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.addGeoJsonSource(sourceId, geoJson);

    final args = <String, dynamic>{
      'sourceId': sourceId,
      'geojson': jsonEncode(geoJson),
    };

    verify(channel.invokeMethod('source#addGeoJson', args)).called(1);
  });

  test('test setGeoJsonSource', () async {
    const sourceId = 'sourceId';
    const geoJson = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [-122.4194, 37.7749],
          },
          'properties': {
            'name': 'Doe',
          },
        },
      ],
    };

    when(channel.invokeMethod<void>('source#setGeoJson', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.setGeoJsonSource(sourceId, geoJson);

    final args = <String, dynamic>{
      'sourceId': sourceId,
      'geojson': jsonEncode(geoJson),
    };

    verify(channel.invokeMethod('source#setGeoJson', args)).called(1);
  });

  test('test addSymbolLayer', () async {
    const sourceId = 'sourceId';
    const layerId = 'layerId';
    const properties = <String, dynamic>{};
    const belowLayerId = 'belowLayerId';
    const sourceLayer = 'sourceLayer';
    const minzoom = 1.0;
    const maxzoom = 2.0;
    const filter = ['==', 'name', 'Doe'];
    const enableInteraction = true;

    final args = <String, dynamic>{
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
    };

    when(channel.invokeMethod<void>('symbolLayer#add', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.addSymbolLayer(sourceId, layerId, properties,
        belowLayerId: belowLayerId,
        sourceLayer: sourceLayer,
        minzoom: minzoom,
        maxzoom: maxzoom,
        filter: filter,
        enableInteraction: enableInteraction);

    verify(channel.invokeMethod('symbolLayer#add', args)).called(1);
  });

  test('test addLineLayer', () async {
    const sourceId = 'sourceId';
    const layerId = 'layerId';
    const properties = <String, dynamic>{};
    const belowLayerId = 'belowLayerId';
    const sourceLayer = 'sourceLayer';
    const minzoom = 1.0;
    const maxzoom = 2.0;
    const filter = ['==', 'name', 'Doe'];
    const enableInteraction = true;

    final args = <String, dynamic>{
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
    };

    when(channel.invokeMethod<void>('lineLayer#add', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.addLineLayer(sourceId, layerId, properties,
        belowLayerId: belowLayerId,
        sourceLayer: sourceLayer,
        minzoom: minzoom,
        maxzoom: maxzoom,
        filter: filter,
        enableInteraction: enableInteraction);

    verify(channel.invokeMethod('lineLayer#add', args)).called(1);
  });

  test('test addCircleLayer', () async {
    const sourceId = 'sourceId';
    const layerId = 'layerId';
    const properties = <String, dynamic>{};
    const belowLayerId = 'belowLayerId';
    const sourceLayer = 'sourceLayer';
    const minzoom = 1.0;
    const maxzoom = 2.0;
    const filter = ['==', 'name', 'Doe'];
    const enableInteraction = true;

    final args = <String, dynamic>{
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
    };

    when(channel.invokeMethod<void>('circleLayer#add', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.addCircleLayer(sourceId, layerId, properties,
        belowLayerId: belowLayerId,
        sourceLayer: sourceLayer,
        minzoom: minzoom,
        maxzoom: maxzoom,
        filter: filter,
        enableInteraction: enableInteraction);

    verify(channel.invokeMethod('circleLayer#add', args)).called(1);
  });

  test('test addFillLayer', () async {
    const sourceId = 'sourceId';
    const layerId = 'layerId';
    const properties = <String, dynamic>{};
    const belowLayerId = 'belowLayerId';
    const sourceLayer = 'sourceLayer';
    const minzoom = 1.0;
    const maxzoom = 2.0;
    const filter = ['==', 'name', 'Doe'];
    const enableInteraction = true;

    final args = <String, dynamic>{
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
    };

    when(channel.invokeMethod<void>('fillLayer#add', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.addFillLayer(sourceId, layerId, properties,
        belowLayerId: belowLayerId,
        sourceLayer: sourceLayer,
        minzoom: minzoom,
        maxzoom: maxzoom,
        filter: filter,
        enableInteraction: enableInteraction);

    verify(channel.invokeMethod('fillLayer#add', args)).called(1);
  });

  test('test addFillExtrusionLayer', () async {
    const sourceId = 'sourceId';
    const layerId = 'layerId';
    const properties = <String, dynamic>{};
    const belowLayerId = 'belowLayerId';
    const sourceLayer = 'sourceLayer';
    const minzoom = 1.0;
    const maxzoom = 2.0;
    const filter = ['==', 'name', 'Doe'];
    const enableInteraction = true;

    final args = <String, dynamic>{
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
    };

    when(channel.invokeMethod<void>('fillExtrusionLayer#add', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.addFillExtrusionLayer(sourceId, layerId, properties,
        belowLayerId: belowLayerId,
        sourceLayer: sourceLayer,
        minzoom: minzoom,
        maxzoom: maxzoom,
        filter: filter,
        enableInteraction: enableInteraction);

    verify(channel.invokeMethod('fillExtrusionLayer#add', args)).called(1);
  });

  test('test addSource', () async {
    const sourceId = 'sourceId';
    const properties = VectorSourceProperties();

    final args = <String, dynamic>{
      'sourceId': sourceId,
      'properties': properties.toJson(),
    };

    when(channel.invokeMethod<void>('style#addSource', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.addSource(sourceId, properties);

    verify(channel.invokeMethod('style#addSource', args)).called(1);
  });

  test('test addRasterLayer', () async {
    const sourceId = 'sourceId';
    const layerId = 'layerId';
    const properties = <String, dynamic>{};
    const belowLayerId = 'belowLayerId';
    const sourceLayer = 'sourceLayer';
    const minzoom = 1.0;
    const maxzoom = 2.0;

    final args = <String, dynamic>{
      'sourceId': sourceId,
      'layerId': layerId,
      'belowLayerId': belowLayerId,
      'minzoom': minzoom,
      'maxzoom': maxzoom,
      'properties': properties
          .map((key, value) => MapEntry<String, String>(key, jsonEncode(value)))
    };

    when(channel.invokeMethod<void>('rasterLayer#add', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.addRasterLayer(sourceId, layerId, properties,
        belowLayerId: belowLayerId,
        sourceLayer: sourceLayer,
        minzoom: minzoom,
        maxzoom: maxzoom);

    verify(channel.invokeMethod('rasterLayer#add', args)).called(1);
  });

  test('test addHillshadeLayer', () async {
    const sourceId = 'sourceId';
    const layerId = 'layerId';
    const properties = <String, dynamic>{};
    const belowLayerId = 'belowLayerId';
    const sourceLayer = 'sourceLayer';
    const minzoom = 1.0;
    const maxzoom = 2.0;

    final args = <String, dynamic>{
      'sourceId': sourceId,
      'layerId': layerId,
      'belowLayerId': belowLayerId,
      'minzoom': minzoom,
      'maxzoom': maxzoom,
      'properties': properties
          .map((key, value) => MapEntry<String, String>(key, jsonEncode(value)))
    };

    when(channel.invokeMethod<void>('hillshadeLayer#add', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.addHillshadeLayer(sourceId, layerId, properties,
        belowLayerId: belowLayerId,
        sourceLayer: sourceLayer,
        minzoom: minzoom,
        maxzoom: maxzoom);

    verify(channel.invokeMethod('hillshadeLayer#add', args)).called(1);
  });

  test('test addHeatmapLayer', () async {
    const sourceId = 'sourceId';
    const layerId = 'layerId';
    const properties = <String, dynamic>{};
    const belowLayerId = 'belowLayerId';
    const sourceLayer = 'sourceLayer';
    const minzoom = 1.0;
    const maxzoom = 2.0;

    final args = <String, dynamic>{
      'sourceId': sourceId,
      'layerId': layerId,
      'belowLayerId': belowLayerId,
      'minzoom': minzoom,
      'maxzoom': maxzoom,
      'properties': properties
          .map((key, value) => MapEntry<String, String>(key, jsonEncode(value)))
    };

    when(channel.invokeMethod<void>('heatmapLayer#add', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.addHeatmapLayer(sourceId, layerId, properties,
        belowLayerId: belowLayerId,
        sourceLayer: sourceLayer,
        minzoom: minzoom,
        maxzoom: maxzoom);

    verify(channel.invokeMethod('heatmapLayer#add', args)).called(1);
  });

  test('test setFeatureForGeoJsonSource', () async {
    const sourceId = 'sourceId';
    const feature = <String, dynamic>{
      'type': 'Feature',
      'geometry': <String, dynamic>{
        'type': 'Point',
        'coordinates': [-122.4194, 37.7749],
      },
      'properties': <String, dynamic>{
        'name': 'Doe',
      },
    };

    when(channel.invokeMethod<void>('source#setFeature', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.setFeatureForGeoJsonSource(sourceId, feature);

    final args = <String, dynamic>{
      'sourceId': sourceId,
      'geojsonFeature': jsonEncode(feature),
    };

    verify(channel.invokeMethod('source#setFeature', args)).called(1);
  });

  test('test findBelowLayerId', () async {
    const belowAttrs = ['layerId'];
    const belowLayerId = 'belowLayerId';

    when(channel.invokeMethod<String>('style#findBelowLayer', any))
        .thenAnswer((_) async => belowLayerId);

    final result = await nbMapsGlChannel.findBelowLayerId(belowAttrs);

    expect(result, equals(belowLayerId));
  });

  test('test setStyleString', () async {
    const styleString = 'styleString';

    when(channel.invokeMethod<void>('style#setStyleString', any))
        .thenAnswer((_) async {});

    await nbMapsGlChannel.setStyleString(styleString);

    const args = <String, dynamic>{
      'styleString': styleString,
    };

    verify(channel.invokeMethod('style#setStyleString', args)).called(1);
  });

  test('handleMethodCall infoWindow#onTap', () {
    const arguments = <String, dynamic>{
      'symbol': 'symbolId',
    };

    nbMapsGlChannel.onInfoWindowTappedPlatform.add((String symbol) {
      expect(symbol, 'symbolId');
    });

    nbMapsGlChannel.handleMethodCall(const MethodCall('infoWindow#onTap', arguments));
  });

  test('handleMethodCall feature#onTap', () {
    const id = 'id';
    const x = 10.0;
    const y = 10.0;
    const lng = -122.4194;
    const lat = 37.7749;

    const arguments = <String, dynamic>{
      'id': id,
      'x': x,
      'y': y,
      'lng': lng,
      'lat': lat,
    };

    nbMapsGlChannel.onFeatureTappedPlatform.add((Map<String, dynamic> arg) {
      expect(arg['id'], id);
      expect(arg['point'], const Point<double>(x, y));
      expect(arg['latLng'], const LatLng(lat, lng));
    });

    nbMapsGlChannel.handleMethodCall(const MethodCall('feature#onTap', arguments));
  });

  test('handleMethodCall feature#onDrag', () {
    const id = 'id';
    const x = 10.0;
    const y = 10.0;
    const originLat = -122.4194;
    const originLng = 37.7749;
    const currentLat = 38.7749;
    const currentLng = -125.4194;
    const deltaLat = 1.0;
    const deltaLng = 2.0;
    const eventType = 'end';

    const methodArgs = <String, dynamic>{
      'id': id,
      'x': x,
      'y': y,
      'originLat': originLat,
      'originLng': originLng,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'deltaLat': deltaLat,
      'deltaLng': deltaLng,
      'eventType': eventType,
    };

    const callabckArguments = <String, dynamic>{
      'id': id,
      'point': Point<double>(x, y),
      'origin': LatLng(originLat, originLng),
      'current': LatLng(currentLat, currentLng),
      'delta': LatLng(deltaLat, deltaLng),
      'eventType': eventType,
    };

    nbMapsGlChannel.onFeatureDraggedPlatform.add((Map<String, dynamic> arg) {
      expect(arg, callabckArguments);
    });

    nbMapsGlChannel.handleMethodCall(const MethodCall('feature#onDrag', methodArgs));
  });

  test('handleMethodCall throws MissingPluginException for unknown method',
      () {
    const call = MethodCall('unknownMethod');

    expect(() async => await nbMapsGlChannel.handleMethodCall(call),
        throwsA(isA<MissingPluginException>()));
  });

  test('handleMethodCall camera#onMoveStarted', () {
    var isCallbackInvoked = false;
    nbMapsGlChannel.onCameraMoveStartedPlatform.add((_) {
      isCallbackInvoked = true;
    });

    nbMapsGlChannel.handleMethodCall(const MethodCall('camera#onMoveStarted'));

    expect(isCallbackInvoked, true);
  });

  test('handleMethodCall camera#onMove', () {
    const args = <String, dynamic>{
      'position': {
        'target': [37.7749, -122.4194],
        'zoom': 15.0,
        'bearing': 2.0,
        'tilt': 3.0,
      },
    };

    nbMapsGlChannel.onCameraMovePlatform.add((CameraPosition position) {
      expect(position.target, const LatLng(37.7749, -122.4194));
      expect(position.zoom, 15.0);
      expect(position.bearing, 2.0);
      expect(position.tilt, 3.0);
    });
    nbMapsGlChannel.handleMethodCall(const MethodCall('camera#onMove', args));
  });

  test('handleMethodCall camera#onIdle', () {
    const args = <String, dynamic>{
      'position': {
        'target': [37.7749, -122.4194],
        'zoom': 15.0,
        'bearing': 2.0,
        'tilt': 3.0,
      },
    };

    nbMapsGlChannel.onCameraIdlePlatform.add((CameraPosition? position) {
      expect(position?.target, const LatLng(37.7749, -122.4194));
      expect(position?.zoom, 15.0);
      expect(position?.bearing, 2.0);
      expect(position?.tilt, 3.0);
    });

    nbMapsGlChannel.handleMethodCall(const MethodCall('camera#onIdle', args));
  });

  test('handleMethodCall map#onStyleLoaded', () {
    var isCallbackInvoked = false;
    nbMapsGlChannel.onMapStyleLoadedPlatform.add((_) {
      isCallbackInvoked = true;
    });

    nbMapsGlChannel.handleMethodCall(const MethodCall('map#onStyleLoaded'));

    expect(isCallbackInvoked, true);
  });

  test('handleMethodCall map#onMapClick', () {
    const point = Point<double>(10.0, 10.0);
    const latLng = LatLng(37.7749, -122.4194);

    final arguments = <String, dynamic>{
      'x': point.x,
      'y': point.y,
      'lat': latLng.latitude,
      'lng': latLng.longitude,
    };

    nbMapsGlChannel.onMapClickPlatform.add((Map<String, dynamic> args) {
      expect(args['point'], point);
      expect(args['latLng'], latLng);
    });

    nbMapsGlChannel.handleMethodCall(MethodCall('map#onMapClick', arguments));
  });

  test('handleMethodCall map#onMapLongClick', () {
    const point = Point<double>(10.0, 10.0);
    const latLng = LatLng(37.7749, -122.4194);

    final arguments = <String, dynamic>{
      'x': point.x,
      'y': point.y,
      'lat': latLng.latitude,
      'lng': latLng.longitude,
    };

    nbMapsGlChannel.onMapLongClickPlatform.add((Map<String, dynamic> args) {
      expect(args['point'], point);
      expect(args['latLng'], latLng);
    });

    nbMapsGlChannel.handleMethodCall(MethodCall('map#onMapLongClick', arguments));
  });

  test('handleMethodCall map#onCameraTrackingChanged', () {
    const trackingMode = 1;

    const arguments = <String, dynamic>{
      'mode': trackingMode,
    };

    nbMapsGlChannel.onCameraTrackingChangedPlatform
        .add((MyLocationTrackingMode mode) {
      expect(mode, MyLocationTrackingMode.values[trackingMode]);
    });

    nbMapsGlChannel
        .handleMethodCall(const MethodCall('map#onCameraTrackingChanged', arguments));
  });

  test('handleMethodCall map#onAttributionClick', () {
    var isCallbackInvoked = false;
    nbMapsGlChannel.onAttributionClickPlatform.add((_) {
      isCallbackInvoked = true;
    });

    nbMapsGlChannel.handleMethodCall(const MethodCall('map#onAttributionClick'));

    expect(isCallbackInvoked, true);
  });

  test('handleMethodCall map#onUserLocationUpdated', () {
    const location = <String, dynamic>{
      'userLocation': {
        'position': [37.7749, -122.4194],
        'timestamp': 0,
        'altitude': 10.0,
        'bearing': 2.0,
        'horizontalAccuracy': 3.0,
        'verticalAccuracy': 4.0,
        'speed': 5.0
      }
    };

    nbMapsGlChannel.onUserLocationUpdatedPlatform.add((UserLocation location) {
      expect(location.position.latitude, 37.7749);
      expect(location.position.longitude, -122.4194);
      expect(location.altitude, 10.0);
      expect(location.bearing, 2.0);
      expect(location.horizontalAccuracy, 3.0);
      expect(location.verticalAccuracy, 4.0);
      expect(location.speed, 5.0);
    });

    nbMapsGlChannel
        .handleMethodCall(const MethodCall('map#onUserLocationUpdated', location));
  });
}
