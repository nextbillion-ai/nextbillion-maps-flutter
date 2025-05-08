import 'dart:ui';

import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('CameraPosition', () {
    test('toMap should convert CameraPosition to a map correctly', () {
      // Arrange
      const CameraPosition cameraPosition = CameraPosition(
        bearing: 90.0,
        target: LatLng(37.7749, -122.4194),
        tilt: 45.0,
        zoom: 10.0,
      );

      // Act
      final Map<String, dynamic> result = cameraPosition.toMap();

      // Assert
      expect(result['bearing'], equals(90.0));
      expect(result['target'], equals(cameraPosition.target.toJson()));
      expect(result['tilt'], equals(45.0));
      expect(result['zoom'], equals(10.0));
    });

    test('fromMap should convert a map to CameraPosition correctly', () {
      // Arrange
      final Map<String, dynamic> json = <String, dynamic>{
        'bearing': 90.0,
        'target': const LatLng(37.7749, -122.4194).toJson(),
        'tilt': 45.0,
        'zoom': 10.0,
      };

      // Act
      final CameraPosition? result = CameraPosition.fromMap(json);

      // Assert
      expect(result?.bearing, equals(90.0));
      expect(result?.target, equals(const LatLng(37.7749, -122.4194)));
      expect(result?.tilt, equals(45.0));
      expect(result?.zoom, equals(10.0));
    });

    test('CameraPosition instances with the same values should be equal', () {
      // Arrange
      const CameraPosition cameraPosition1 = CameraPosition(
        bearing: 90.0,
        target: LatLng(37.7749, -122.4194),
        tilt: 45.0,
        zoom: 10.0,
      );
      const CameraPosition cameraPosition2 = CameraPosition(
        bearing: 90.0,
        target: LatLng(37.7749, -122.4194),
        tilt: 45.0,
        zoom: 10.0,
      );

      // Act
      final bool result = cameraPosition1 == cameraPosition2;

      // Assert
      expect(result, isTrue);
    });

    test(
        'hashCode should return the same value for equal CameraPosition instances',
        () {
      // Arrange
      const CameraPosition cameraPosition1 = CameraPosition(
        bearing: 90.0,
        target: LatLng(37.7749, -122.4194),
        tilt: 45.0,
        zoom: 10.0,
      );
      const CameraPosition cameraPosition2 = CameraPosition(
        bearing: 90.0,
        target: LatLng(37.7749, -122.4194),
        tilt: 45.0,
        zoom: 10.0,
      );

      // Act
      final int hashCode1 = cameraPosition1.hashCode;
      final int hashCode2 = cameraPosition2.hashCode;

      // Assert
      expect(hashCode1, equals(hashCode2));
    });

    test('toString should return a string representation of CameraPosition',
        () {
      // Arrange
      const CameraPosition cameraPosition = CameraPosition(
        bearing: 90.0,
        target: LatLng(37.7749, -122.4194),
        tilt: 45.0,
        zoom: 10.0,
      );

      // Act
      final String result = cameraPosition.toString();

      // Assert
      expect(
        result,
        equals(
            'CameraPosition(bearing: 90.0, target: LatLng(37.7749, -122.4194), tilt: 45.0, zoom: 10.0)'),
      );
    });
  });

  group('CameraUpdate', () {
    test(
        'newCameraPosition should create a CameraUpdate with newCameraPosition action',
        () {
      // Arrange
      const CameraPosition cameraPosition = CameraPosition(
        bearing: 90.0,
        target: LatLng(37.7749, -122.4194),
        tilt: 45.0,
        zoom: 10.0,
      );

      // Act
      final CameraUpdate result =
          CameraUpdate.newCameraPosition(cameraPosition);

      // Assert
      expect(result.toJson(),
          equals(['newCameraPosition', cameraPosition.toMap()]));
    });

    test('newLatLng should create a CameraUpdate with newLatLng action', () {
      // Arrange
      const LatLng latLng = LatLng(37.7749, -122.4194);

      // Act
      final CameraUpdate result = CameraUpdate.newLatLng(latLng);

      // Assert
      expect(result.toJson(), equals(['newLatLng', latLng.toJson()]));
    });

    test(
        'newLatLngBounds should create a CameraUpdate with newLatLngBounds action',
        () {
      // Arrange
      final LatLngBounds bounds = LatLngBounds(
        southwest: const LatLng(37.7749, -122.4194),
        northeast: const LatLng(37.8095, -122.3927),
      );
      const double left = 10.0;
      const double top = 20.0;
      const double right = 30.0;
      const double bottom = 40.0;

      // Act
      final CameraUpdate result = CameraUpdate.newLatLngBounds(bounds,
          left: left, top: top, right: right, bottom: bottom);

      // Assert
      expect(
          result.toJson(),
          equals(
              ['newLatLngBounds', bounds.toList(), left, top, right, bottom]));
    });

    test('newLatLngZoom should create a CameraUpdate with newLatLngZoom action',
        () {
      // Arrange
      const LatLng latLng = LatLng(37.7749, -122.4194);
      const double zoom = 10.0;

      // Act
      final CameraUpdate result = CameraUpdate.newLatLngZoom(latLng, zoom);

      // Assert
      expect(result.toJson(), equals(['newLatLngZoom', latLng.toJson(), zoom]));
    });

    test('scrollBy should create a CameraUpdate with scrollBy action', () {
      // Arrange
      const double dx = 50.0;
      const double dy = 75.0;

      // Act
      final CameraUpdate result = CameraUpdate.scrollBy(dx, dy);

      // Assert
      expect(result.toJson(), equals(['scrollBy', dx, dy]));
    });

    test('zoomBy should create a CameraUpdate with zoomBy action', () {
      // Arrange
      const double amount = 2.0;
      const Offset focus = Offset(100.0, 200.0);

      // Act
      final CameraUpdate result = CameraUpdate.zoomBy(amount, focus);

      // Assert
      expect(
          result.toJson(),
          equals([
            'zoomBy',
            amount,
            [focus.dx, focus.dy]
          ]));
    });

    test('zoomIn should create a CameraUpdate with zoomIn action', () {
      // Act
      final CameraUpdate result = CameraUpdate.zoomIn();

      // Assert
      expect(result.toJson(), equals(['zoomIn']));
    });

    test('zoomOut should create a CameraUpdate with zoomOut action', () {
      // Act
      final CameraUpdate result = CameraUpdate.zoomOut();

      // Assert
      expect(result.toJson(), equals(['zoomOut']));
    });

    test('zoomTo should create a CameraUpdate with zoomTo action', () {
      // Arrange
      const double zoom = 10.0;

      // Act
      final CameraUpdate result = CameraUpdate.zoomTo(zoom);

      // Assert
      expect(result.toJson(), equals(['zoomTo', zoom]));
    });

    test('bearingTo should create a CameraUpdate with bearingTo action', () {
      // Arrange
      const double bearing = 90.0;

      // Act
      final CameraUpdate result = CameraUpdate.bearingTo(bearing);

      // Assert
      expect(result.toJson(), equals(['bearingTo', bearing]));
    });

    test('tiltTo should create a CameraUpdate with tiltTo action', () {
      // Arrange
      const double tilt = 45.0;

      // Act
      final CameraUpdate result = CameraUpdate.tiltTo(tilt);

      // Assert
      expect(result.toJson(), equals(['tiltTo', tilt]));
    });
  });
}
