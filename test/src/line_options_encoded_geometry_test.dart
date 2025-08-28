import 'package:flutter_test/flutter_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

void main() {
  group('LineOptions Encoded Geometry Tests', () {
    const String testEncodedGeometry = 'u{~vFvyys@fS]';
    const int testPrecision = 5;
    const List<LatLng> testGeometry = [
      LatLng(12.96206481, 77.56687669),
      LatLng(12.96306481, 77.56787669),
    ];

    test('LineOptions with encodedGeometry should be created correctly', () {
      final lineOptions = LineOptions(
        encodedGeometry: testEncodedGeometry,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
        lineWidth: 4.0,
      );

      expect(lineOptions.encodedGeometry, equals(testEncodedGeometry));
      expect(lineOptions.encodedGeometryPrecision, equals(testPrecision));
      expect(lineOptions.lineColor, equals('#FF0000'));
      expect(lineOptions.lineWidth, equals(4.0));
      expect(lineOptions.geometry, isNull);
    });

    test('LineOptions with both encodedGeometry and geometry should prioritize encodedGeometry', () {
      final lineOptions = LineOptions(
        encodedGeometry: testEncodedGeometry,
        encodedGeometryPrecision: testPrecision,
        geometry: testGeometry,
        lineColor: '#FF0000',
      );

      expect(lineOptions.encodedGeometry, equals(testEncodedGeometry));
      expect(lineOptions.encodedGeometryPrecision, equals(testPrecision));
      expect(lineOptions.geometry, equals(testGeometry));
    });

    test('LineOptions copyWith should preserve encodedGeometry fields', () {
      final originalOptions = LineOptions(
        encodedGeometry: testEncodedGeometry,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
        lineWidth: 4.0,
      );

      final copiedOptions = originalOptions.copyWith(
        LineOptions(lineColor: '#00FF00'),
      );

      expect(copiedOptions.encodedGeometry, equals(testEncodedGeometry));
      expect(copiedOptions.encodedGeometryPrecision, equals(testPrecision));
      expect(copiedOptions.lineColor, equals('#00FF00'));
      expect(copiedOptions.lineWidth, equals(4.0));
    });

    test('LineOptions copyWith should update encodedGeometry fields', () {
      const String newEncodedGeometry = 'newEncodedString';
      const int newPrecision = 6;

      final originalOptions = LineOptions(
        encodedGeometry: testEncodedGeometry,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
      );

      final copiedOptions = originalOptions.copyWith(
        LineOptions(
          encodedGeometry: newEncodedGeometry,
          encodedGeometryPrecision: newPrecision,
        ),
      );

      expect(copiedOptions.encodedGeometry, equals(newEncodedGeometry));
      expect(copiedOptions.encodedGeometryPrecision, equals(newPrecision));
      expect(copiedOptions.lineColor, equals('#FF0000'));
    });

    test('LineOptions toJson should include encodedGeometry when present', () {
      final lineOptions = LineOptions(
        encodedGeometry: testEncodedGeometry,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
        lineWidth: 4.0,
        lineOpacity: 0.8,
      );

      final json = lineOptions.toJson();

      expect(json['encodedGeometry'], equals(testEncodedGeometry));
      expect(json['encodedGeometryPrecision'], equals(testPrecision));
      expect(json['lineColor'], equals('#FF0000'));
      expect(json['lineWidth'], equals(4.0));
      expect(json['lineOpacity'], equals(0.8));
      expect(json.containsKey('geometry'), isFalse);
    });

    test('LineOptions toJson should include geometry when encodedGeometry is null', () {
      final lineOptions = LineOptions(
        geometry: testGeometry,
        lineColor: '#FF0000',
        lineWidth: 4.0,
      );

      final json = lineOptions.toJson();

      expect(json.containsKey('encodedGeometry'), isFalse);
      expect(json.containsKey('encodedGeometryPrecision'), isFalse);
      expect(json['geometry'], isNotNull);
      expect(json['geometry'], hasLength(2));
    });

    test('LineOptions toJson should use default precision when encodedGeometryPrecision is null', () {
      final lineOptions = LineOptions(
        encodedGeometry: testEncodedGeometry,
        lineColor: '#FF0000',
      );

      final json = lineOptions.toJson();

      expect(json['encodedGeometry'], equals(testEncodedGeometry));
      expect(json['encodedGeometryPrecision'], equals(5)); // default precision
    });

    test('LineOptions toGeoJson should include encodedGeometry in geometry', () {
      final lineOptions = LineOptions(
        encodedGeometry: testEncodedGeometry,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
        lineWidth: 4.0,
      );

      final geoJson = lineOptions.toGeoJson();

      expect(geoJson['type'], equals('Feature'));
      expect(geoJson['properties'], isNotNull);
      expect(geoJson['geometry'], isNotNull);
      expect(geoJson['geometry']['type'], equals('LineString'));
      expect(geoJson['geometry']['encodedGeometry'], equals(testEncodedGeometry));
      expect(geoJson['geometry']['encodedGeometryPrecision'], equals(testPrecision));
      expect(geoJson['geometry']['coordinates'], isEmpty);
    });

    test('LineOptions toGeoJson should include regular coordinates when encodedGeometry is null', () {
      final lineOptions = LineOptions(
        geometry: testGeometry,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();

      expect(geoJson['type'], equals('Feature'));
      expect(geoJson['geometry']['type'], equals('LineString'));
      expect(geoJson['geometry']['coordinates'], hasLength(2));
      expect(geoJson['geometry'].containsKey('encodedGeometry'), isFalse);
    });

    test('LineOptions with null encodedGeometry should not include it in JSON', () {
      final lineOptions = LineOptions(
        geometry: testGeometry,
        lineColor: '#FF0000',
      );

      final json = lineOptions.toJson();

      expect(json.containsKey('encodedGeometry'), isFalse);
      expect(json.containsKey('encodedGeometryPrecision'), isFalse);
      expect(json['geometry'], isNotNull);
    });

    test('LineOptions equality should consider encodedGeometry fields', () {
      final options1 = LineOptions(
        encodedGeometry: testEncodedGeometry,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
      );

      final options2 = LineOptions(
        encodedGeometry: testEncodedGeometry,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
      );

      final options3 = LineOptions(
        encodedGeometry: 'different',
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
      );

      expect(options1.toJson(), equals(options2.toJson()));
      expect(options1.toJson(), isNot(equals(options3.toJson())));
    });
  });
}
