import 'package:flutter_test/flutter_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

void main() {
  group('Android PolylineDecoder Tests', () {
    // Test data based on the encoded geometry example
    const String testEncodedPolyline = 'u{~vFvyys@fS]';
    const int testPrecision = 5;
    
    // Expected coordinates for the test polyline (approximate)
    const List<LatLng> expectedCoordinates = [
      LatLng(12.96206481, 77.56687669),
      LatLng(12.96306481, 77.56787669),
    ];

    test('should handle valid encoded polyline string', () {
      // This test verifies the structure and format that would be sent to Android
      final lineOptions = LineOptions(
        encodedGeometry: testEncodedPolyline,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
        lineWidth: 4.0,
      );

      final geoJson = lineOptions.toGeoJson();
      
      expect(geoJson['geometry']['encodedGeometry'], equals(testEncodedPolyline));
      expect(geoJson['geometry']['encodedGeometryPrecision'], equals(testPrecision));
      expect(geoJson['geometry']['type'], equals('LineString'));
    });

    test('should handle FeatureCollection with encoded geometry', () {
      final feature1 = LineOptions(
        encodedGeometry: testEncodedPolyline,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
      ).toGeoJson();

      final feature2 = LineOptions(
        encodedGeometry: 'anotherEncodedString',
        encodedGeometryPrecision: 6,
        lineColor: '#00FF00',
      ).toGeoJson();

      // Simulate FeatureCollection structure
      final featureCollection = {
        'type': 'FeatureCollection',
        'features': [feature1, feature2],
      };

      expect(featureCollection['type'], equals('FeatureCollection'));
      expect(featureCollection['features'], hasLength(2));
      
      final features = featureCollection['features'] as List;
      final firstFeature = features[0] as Map<String, dynamic>;
      expect(firstFeature['geometry']['encodedGeometry'], equals(testEncodedPolyline));
    });

    test('should handle single Feature with encoded geometry', () {
      final lineOptions = LineOptions(
        encodedGeometry: testEncodedPolyline,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
        lineWidth: 4.0,
        lineOpacity: 0.8,
      );

      final feature = lineOptions.toGeoJson();

      expect(feature['type'], equals('Feature'));
      expect(feature['properties']['lineColor'], equals('#FF0000'));
      expect(feature['properties']['lineWidth'], equals(4.0));
      expect(feature['properties']['lineOpacity'], equals(0.8));
      expect(feature['geometry']['encodedGeometry'], equals(testEncodedPolyline));
      expect(feature['geometry']['encodedGeometryPrecision'], equals(testPrecision));
    });

    test('should handle empty encoded geometry string', () {
      final lineOptions = LineOptions(
        encodedGeometry: '',
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      
      expect(geoJson['geometry']['encodedGeometry'], equals(''));
      expect(geoJson['geometry']['encodedGeometryPrecision'], equals(testPrecision));
    });

    test('should handle null encoded geometry', () {
      final lineOptions = LineOptions(
        geometry: expectedCoordinates,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      
      expect(geoJson['geometry'].containsKey('encodedGeometry'), isFalse);
      expect(geoJson['geometry']['coordinates'], isNotEmpty);
      expect(geoJson['geometry']['coordinates'], hasLength(2));
    });

    test('should handle different precision values', () {
      for (int precision in [1, 5, 6, 7]) {
        final lineOptions = LineOptions(
          encodedGeometry: testEncodedPolyline,
          encodedGeometryPrecision: precision,
          lineColor: '#FF0000',
        );

        final geoJson = lineOptions.toGeoJson();
        expect(geoJson['geometry']['encodedGeometryPrecision'], equals(precision));
      }
    });

    test('should handle default precision when not specified', () {
      final lineOptions = LineOptions(
        encodedGeometry: testEncodedPolyline,
        lineColor: '#FF0000',
      );

      final json = lineOptions.toJson();
      expect(json['encodedGeometryPrecision'], equals(5)); // default precision
    });

    test('should preserve other line properties with encoded geometry', () {
      final lineOptions = LineOptions(
        encodedGeometry: testEncodedPolyline,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
        lineWidth: 4.0,
        lineOpacity: 0.8,
        lineBlur: 1.0,
        linePattern: 'dash',
        draggable: true,
      );

      final properties = lineOptions.toJson(false); // properties only

      expect(properties['lineColor'], equals('#FF0000'));
      expect(properties['lineWidth'], equals(4.0));
      expect(properties['lineOpacity'], equals(0.8));
      expect(properties['lineBlur'], equals(1.0));
      expect(properties['linePattern'], equals('dash'));
      expect(properties['draggable'], equals(true));
    });

    test('should handle mixed FeatureCollection with encoded and regular geometry', () {
      final encodedFeature = LineOptions(
        encodedGeometry: testEncodedPolyline,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
      ).toGeoJson();

      final regularFeature = LineOptions(
        geometry: expectedCoordinates,
        lineColor: '#00FF00',
      ).toGeoJson();

      final featureCollection = {
        'type': 'FeatureCollection',
        'features': [encodedFeature, regularFeature],
      };

      expect(featureCollection['features'], hasLength(2));
      
      final features = featureCollection['features'] as List;
      final firstFeature = features[0] as Map<String, dynamic>;
      final secondFeature = features[1] as Map<String, dynamic>;
      
      expect(firstFeature['geometry'].containsKey('encodedGeometry'), isTrue);
      expect(secondFeature['geometry'].containsKey('encodedGeometry'), isFalse);
      expect(secondFeature['geometry']['coordinates'], isNotEmpty);
    });

    test('should handle LineString geometry type validation', () {
      final lineOptions = LineOptions(
        encodedGeometry: testEncodedPolyline,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      
      expect(geoJson['geometry']['type'], equals('LineString'));
      expect(geoJson['type'], equals('Feature'));
    });
  });

  group('Android PolylineDecoder Error Handling Tests', () {
    test('should handle malformed encoded geometry gracefully', () {
      final lineOptions = LineOptions(
        encodedGeometry: 'invalid_encoded_string!@#',
        encodedGeometryPrecision: 5,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      
      // Should still create valid GeoJSON structure
      expect(geoJson['type'], equals('Feature'));
      expect(geoJson['geometry']['type'], equals('LineString'));
      expect(geoJson['geometry']['encodedGeometry'], equals('invalid_encoded_string!@#'));
    });

    test('should handle negative precision values', () {
      final lineOptions = LineOptions(
        encodedGeometry: 'u{~vFvyys@fS]',
        encodedGeometryPrecision: -1,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      expect(geoJson['geometry']['encodedGeometryPrecision'], equals(-1));
    });

    test('should handle very large precision values', () {
      final lineOptions = LineOptions(
        encodedGeometry: 'u{~vFvyys@fS]',
        encodedGeometryPrecision: 999,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      expect(geoJson['geometry']['encodedGeometryPrecision'], equals(999));
    });
  });
}
