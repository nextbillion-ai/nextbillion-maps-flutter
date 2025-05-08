import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

@GenerateMocks([NbMapsGlPlatform])
import 'controller_test.mocks.dart';

void main() {
  late MockNbMapsGlPlatform mockPlatform;
  late NextbillionMapController controller;
  late CameraPosition initialCameraPosition;

  setUp(() {
    mockPlatform = MockNbMapsGlPlatform();
    initialCameraPosition = const CameraPosition(
      target: LatLng(0.0, 0.0),
      zoom: 10.0,
    );

    // Setup mock platform callbacks
    when(mockPlatform.onFeatureTappedPlatform).thenReturn(ArgumentCallbacks<Map<String, dynamic>>());
    when(mockPlatform.onFeatureDraggedPlatform).thenReturn(ArgumentCallbacks<Map<String, dynamic>>());
    when(mockPlatform.onCameraMoveStartedPlatform).thenReturn(ArgumentCallbacks<void>());
    when(mockPlatform.onCameraMovePlatform).thenReturn(ArgumentCallbacks<CameraPosition>());
    when(mockPlatform.onCameraIdlePlatform).thenReturn(ArgumentCallbacks<CameraPosition?>());
    when(mockPlatform.onMapStyleLoadedPlatform).thenReturn(ArgumentCallbacks<void>());
    when(mockPlatform.onMapClickPlatform).thenReturn(ArgumentCallbacks<Map<String, dynamic>>());
    when(mockPlatform.onMapLongClickPlatform).thenReturn(ArgumentCallbacks<Map<String, dynamic>>());
    when(mockPlatform.onAttributionClickPlatform).thenReturn(ArgumentCallbacks<void>());
    when(mockPlatform.onCameraTrackingChangedPlatform).thenReturn(ArgumentCallbacks<MyLocationTrackingMode>());
    when(mockPlatform.onCameraTrackingDismissedPlatform).thenReturn(ArgumentCallbacks<void>());
    when(mockPlatform.onMapIdlePlatform).thenReturn(ArgumentCallbacks<void>());
    when(mockPlatform.onUserLocationUpdatedPlatform).thenReturn(ArgumentCallbacks<UserLocation>());

    controller = NextbillionMapController(
      nbMapsGlPlatform: mockPlatform,
      initialCameraPosition: initialCameraPosition,
      annotationOrder: [AnnotationType.symbol],
      annotationConsumeTapEvents: [AnnotationType.symbol],
    );
  });

  tearDown(() {
    if (!controller.disposed) {
      controller.dispose();
    }
  });

  group('NextbillionMapController', () {
    test('initializes with correct camera position', () {
      expect(controller.cameraPosition, equals(initialCameraPosition));
    });

    test('isCameraMoving is initially false', () {
      expect(controller.isCameraMoving, isFalse);
    });

    test('dispose sets disposed flag to true', () {
      final disposed = controller.disposed;
      controller.dispose();
      expect(controller.disposed, !disposed);
    });

    test('onMapClick callback is called when map is clicked', () {
      bool callbackCalled = false;
      Point<double>? receivedPoint;
      LatLng? receivedLatLng;

      controller = NextbillionMapController(
        nbMapsGlPlatform: mockPlatform,
        initialCameraPosition: initialCameraPosition,
        annotationOrder: [AnnotationType.symbol],
        annotationConsumeTapEvents: [AnnotationType.symbol],
        onMapClick: (point, latLng) {
          callbackCalled = true;
          receivedPoint = point;
          receivedLatLng = latLng;
        },
      );

      const testPoint = Point<double>(100.0, 200.0);
      const testLatLng = LatLng(1.0, 2.0);

      mockPlatform.onMapClickPlatform.add((args) {
        final point = args['point'] as Point<double>;
        final latLng = args['latLng'] as LatLng;
        controller.onMapClick?.call(point, latLng);
      });

      mockPlatform.onMapClickPlatform.call({
        'point': testPoint,
        'latLng': testLatLng,
      });

      expect(callbackCalled, isTrue);
      expect(receivedPoint, equals(testPoint));
      expect(receivedLatLng, equals(testLatLng));
    });

    test('onCameraIdle callback is called when camera becomes idle', () {
      bool callbackCalled = false;

      controller = NextbillionMapController(
        nbMapsGlPlatform: mockPlatform,
        initialCameraPosition: initialCameraPosition,
        annotationOrder: [AnnotationType.symbol],
        annotationConsumeTapEvents: [AnnotationType.symbol],
        onCameraIdle: () {
          callbackCalled = true;
        },
      );

      mockPlatform.onCameraIdlePlatform.add((position) {
        controller.onCameraIdle?.call();
      });

      mockPlatform.onCameraIdlePlatform.call(null);

      expect(callbackCalled, isTrue);
      expect(controller.isCameraMoving, isFalse);
    });

    test('onUserLocationUpdated callback is called when location updates', () {
      bool callbackCalled = false;
      UserLocation? receivedLocation;

      controller = NextbillionMapController(
        nbMapsGlPlatform: mockPlatform,
        initialCameraPosition: initialCameraPosition,
        annotationOrder: [AnnotationType.symbol],
        annotationConsumeTapEvents: [AnnotationType.symbol],
        onUserLocationUpdated: (location) {
          callbackCalled = true;
          receivedLocation = location;
        },
      );

      final testLocation = UserLocation(
        position: const LatLng(1.0, 2.0),
        heading: UserHeading(
          magneticHeading: 90.0,
          trueHeading: 90.0,
          headingAccuracy: 1.0,
          x: 0.0,
          y: 0.0,
          z: 0.0,
          timestamp: DateTime.now(),
        ),
        altitude: 0.0,
        bearing: 90.0,
        speed: 10.0,
        horizontalAccuracy: 5.0,
        verticalAccuracy: 5.0,
        timestamp: DateTime.now(),
      );

      mockPlatform.onUserLocationUpdatedPlatform.add((location) {
        controller.onUserLocationUpdated?.call(location);
      });

      mockPlatform.onUserLocationUpdatedPlatform.call(testLocation);

      expect(callbackCalled, isTrue);
      expect(receivedLocation, equals(testLocation));
    });

    test('onMapLongClick callback is called when map is long clicked', () {
      bool callbackCalled = false;
      Point<double>? receivedPoint;
      LatLng? receivedLatLng;

      controller = NextbillionMapController(
        nbMapsGlPlatform: mockPlatform,
        initialCameraPosition: initialCameraPosition,
        annotationOrder: [AnnotationType.symbol],
        annotationConsumeTapEvents: [AnnotationType.symbol],
        onMapLongClick: (point, latLng) {
          callbackCalled = true;
          receivedPoint = point;
          receivedLatLng = latLng;
        },
      );

      const testPoint = Point<double>(150.0, 250.0);
      const testLatLng = LatLng(2.0, 3.0);

      mockPlatform.onMapLongClickPlatform.add((args) {
        final point = args['point'] as Point<double>;
        final latLng = args['latLng'] as LatLng;
        controller.onMapLongClick?.call(point, latLng);
      });

      mockPlatform.onMapLongClickPlatform.call({
        'point': testPoint,
        'latLng': testLatLng,
      });

      expect(callbackCalled, isTrue);
      expect(receivedPoint, equals(testPoint));
      expect(receivedLatLng, equals(testLatLng));
    });

    test('camera position is updated when camera moves', () {
      final testPosition = CameraPosition(
        target: const LatLng(1.0, 2.0),
        zoom: 15.0,
        bearing: 45.0,
        tilt: 30.0,
      );

      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      mockPlatform.onCameraMovePlatform.call(testPosition);

      expect(notified, true);
      expect(controller.cameraPosition, equals(testPosition));
    });

    test('isCameraMoving is set to true when camera movement starts', () {
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      mockPlatform.onCameraMoveStartedPlatform.call(null);

      expect(notified, true);
      expect(controller.isCameraMoving, isTrue);
    });

    test('onStyleLoaded callback is called when map style is loaded', () {
      bool callbackCalled = false;

      controller = NextbillionMapController(
        nbMapsGlPlatform: mockPlatform,
        initialCameraPosition: initialCameraPosition,
        annotationOrder: [AnnotationType.symbol],
        annotationConsumeTapEvents: [AnnotationType.symbol],
        onStyleLoadedCallback: () {
          callbackCalled = true;
        },
      );

      mockPlatform.onMapStyleLoadedPlatform.add((_) {
        controller.onStyleLoadedCallback?.call();
      });

      mockPlatform.onMapStyleLoadedPlatform.call(null);

      expect(callbackCalled, isTrue);
    });

    test('onAttributionClick callback is called when attribution is clicked', () {
      bool callbackCalled = false;

      controller = NextbillionMapController(
        nbMapsGlPlatform: mockPlatform,
        initialCameraPosition: initialCameraPosition,
        annotationOrder: [AnnotationType.symbol],
        annotationConsumeTapEvents: [AnnotationType.symbol],
        onAttributionClick: () {
          callbackCalled = true;
        },
      );

      mockPlatform.onAttributionClickPlatform.add((_) {
        controller.onAttributionClick?.call();
      });

      mockPlatform.onAttributionClickPlatform.call(null);

      expect(callbackCalled, isTrue);
    });

    test('onCameraTrackingChanged callback is called when tracking mode changes', () {
      bool callbackCalled = false;
      MyLocationTrackingMode? receivedMode;

      controller = NextbillionMapController(
        nbMapsGlPlatform: mockPlatform,
        initialCameraPosition: initialCameraPosition,
        annotationOrder: [AnnotationType.symbol],
        annotationConsumeTapEvents: [AnnotationType.symbol],
        onCameraTrackingChanged: (mode) {
          callbackCalled = true;
          receivedMode = mode;
        },
      );

      const testMode = MyLocationTrackingMode.trackingCompass;

      mockPlatform.onCameraTrackingChangedPlatform.add((mode) {
        controller.onCameraTrackingChanged?.call(mode);
      });

      mockPlatform.onCameraTrackingChangedPlatform.call(testMode);

      expect(callbackCalled, isTrue);
      expect(receivedMode, equals(testMode));
    });

    test('onCameraTrackingDismissed callback is called when tracking is dismissed', () {
      bool callbackCalled = false;

      controller = NextbillionMapController(
        nbMapsGlPlatform: mockPlatform,
        initialCameraPosition: initialCameraPosition,
        annotationOrder: [AnnotationType.symbol],
        annotationConsumeTapEvents: [AnnotationType.symbol],
        onCameraTrackingDismissed: () {
          callbackCalled = true;
        },
      );

      mockPlatform.onCameraTrackingDismissedPlatform.add((_) {
        controller.onCameraTrackingDismissed?.call();
      });

      mockPlatform.onCameraTrackingDismissedPlatform.call(null);

      expect(callbackCalled, isTrue);
    });

    test('onMapIdle callback is called when map becomes idle', () {
      bool callbackCalled = false;

      controller = NextbillionMapController(
        nbMapsGlPlatform: mockPlatform,
        initialCameraPosition: initialCameraPosition,
        annotationOrder: [AnnotationType.symbol],
        annotationConsumeTapEvents: [AnnotationType.symbol],
        onMapIdle: () {
          callbackCalled = true;
        },
      );

      mockPlatform.onMapIdlePlatform.add((_) {
        controller.onMapIdle?.call();
      });

      mockPlatform.onMapIdlePlatform.call(null);

      expect(callbackCalled, isTrue);
    });

    test('Camera position updates properly trigger notifications', () {
      final controller = NextbillionMapController(
        nbMapsGlPlatform: mockPlatform,
        initialCameraPosition: const CameraPosition(target: LatLng(0, 0)),
        annotationOrder: const [],
        annotationConsumeTapEvents: const [],
      );

      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      final newPosition = CameraPosition(
        target: const LatLng(1, 1),
        zoom: 10,
      );
      
      mockPlatform.onCameraMovePlatform.call(newPosition);

      expect(notified, true);
      expect(controller.cameraPosition, newPosition);
    });

    test('Camera movement state changes trigger notifications', () {
      final controller = NextbillionMapController(
        nbMapsGlPlatform: mockPlatform,
        initialCameraPosition: const CameraPosition(target: LatLng(0, 0)),
        annotationOrder: const [],
        annotationConsumeTapEvents: const [],
      );

      int notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      // Start camera movement
      mockPlatform.onCameraMoveStartedPlatform.call(null);
      expect(controller.isCameraMoving, true);
      expect(notificationCount, 1);

      // End camera movement
      mockPlatform.onCameraIdlePlatform.call(null);
      expect(controller.isCameraMoving, false);
      expect(notificationCount, 2);
    });
  });
} 