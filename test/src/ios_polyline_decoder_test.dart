import 'package:flutter_test/flutter_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

void main() {
  // Test data consistent with Android tests
  const String testEncodedPolyline = 'u{~vFvyys@fS]';
  const int testPrecision = 5;
  
  group('iOS PolylineDecoder Tests', () {
    
    // Expected coordinates for the test polyline
    const List<LatLng> expectedCoordinates = [
      LatLng(12.96206481, 77.56687669),
      LatLng(12.96306481, 77.56787669),
    ];

    test('should handle valid encoded polyline for iOS processing', () {
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
      
      // iOS expects coordinates array to be empty initially (placeholder)
      expect(geoJson['geometry']['coordinates'], isEmpty);
    });

    test('should handle FeatureCollection processing for iOS', () {
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

      // Simulate FeatureCollection structure that iOS will process
      final featureCollection = {
        'type': 'FeatureCollection',
        'features': [feature1, feature2],
      };

      expect(featureCollection['type'], equals('FeatureCollection'));
      expect(featureCollection['features'], hasLength(2));
      
      // Verify each feature has the required structure for iOS processing
      final features = featureCollection['features'] as List;
      for (final feature in features) {
        final featureMap = feature as Map<String, dynamic>;
        expect(featureMap['type'], equals('Feature'));
        expect(featureMap['geometry']['type'], equals('LineString'));
        expect(featureMap['geometry'].containsKey('encodedGeometry'), isTrue);
      }
    });

    test('should handle single Feature processing for iOS', () {
      final lineOptions = LineOptions(
        encodedGeometry: testEncodedPolyline,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
        lineWidth: 4.0,
        lineOpacity: 0.8,
      );

      final feature = lineOptions.toGeoJson();

      // Verify structure expected by iOS PolylineDecoder
      expect(feature['type'], equals('Feature'));
      expect(feature['properties'], isNotNull);
      expect(feature['geometry'], isNotNull);
      expect(feature['geometry']['type'], equals('LineString'));
      expect(feature['geometry']['encodedGeometry'], equals(testEncodedPolyline));
      expect(feature['geometry']['encodedGeometryPrecision'], equals(testPrecision));
      
      // iOS expects empty coordinates initially
      expect(feature['geometry']['coordinates'], isEmpty);
    });

    test('should handle coordinate format for iOS (longitude, latitude)', () {
      final lineOptions = LineOptions(
        geometry: expectedCoordinates,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      final coordinates = geoJson['geometry']['coordinates'] as List;
      
      expect(coordinates, hasLength(2));
      
      // Verify coordinate format: [longitude, latitude]
      for (final coord in coordinates) {
        final coordList = coord as List;
        expect(coordList, hasLength(2));
        expect(coordList[0], isA<double>()); // longitude
        expect(coordList[1], isA<double>()); // latitude
      }
    });

    test('should handle different precision values for iOS', () {
      final precisionValues = [1, 5, 6, 7, 8];
      
      for (final precision in precisionValues) {
        final lineOptions = LineOptions(
          encodedGeometry: testEncodedPolyline,
          encodedGeometryPrecision: precision,
          lineColor: '#FF0000',
        );

        final geoJson = lineOptions.toGeoJson();
        expect(geoJson['geometry']['encodedGeometryPrecision'], equals(precision));
      }
    });

    test('should handle empty encoded geometry for iOS', () {
      final lineOptions = LineOptions(
        encodedGeometry: '',
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      
      expect(geoJson['geometry']['encodedGeometry'], equals(''));
      expect(geoJson['geometry']['encodedGeometryPrecision'], equals(testPrecision));
      expect(geoJson['geometry']['coordinates'], isEmpty);
    });

    test('should handle null encoded geometry fallback to regular coordinates', () {
      final lineOptions = LineOptions(
        geometry: expectedCoordinates,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      
      expect(geoJson['geometry'].containsKey('encodedGeometry'), isFalse);
      expect(geoJson['geometry']['coordinates'], isNotEmpty);
      expect(geoJson['geometry']['coordinates'], hasLength(2));
    });

    test('should preserve line properties during iOS processing', () {
      final lineOptions = LineOptions(
        encodedGeometry: testEncodedPolyline,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
        lineWidth: 4.0,
        lineOpacity: 0.8,
        lineBlur: 1.0,
        draggable: true,
      );

      final geoJson = lineOptions.toGeoJson();
      final properties = geoJson['properties'] as Map<String, dynamic>;

      expect(properties['lineColor'], equals('#FF0000'));
      expect(properties['lineWidth'], equals(4.0));
      expect(properties['lineOpacity'], equals(0.8));
      expect(properties['lineBlur'], equals(1.0));
      expect(properties['draggable'], equals(true));
    });

    test('should handle mixed geometry types in FeatureCollection for iOS', () {
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
      
      // First feature should have encoded geometry
      expect(firstFeature['geometry'].containsKey('encodedGeometry'), isTrue);
      expect(firstFeature['geometry']['coordinates'], isEmpty);
      
      // Second feature should have regular coordinates
      expect(secondFeature['geometry'].containsKey('encodedGeometry'), isFalse);
      expect(secondFeature['geometry']['coordinates'], isNotEmpty);
    });

    test('should handle CLLocationCoordinate2D format expectations', () {
      // Test that coordinates are in the format iOS CLLocationCoordinate2D expects
      final lineOptions = LineOptions(
        geometry: [
          const LatLng(12.96206481, 77.56687669), // latitude, longitude
          const LatLng(12.96306481, 77.56787669),
        ],
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      final coordinates = geoJson['geometry']['coordinates'] as List;
      
      // GeoJSON format: [longitude, latitude] (opposite of LatLng constructor)
      final firstCoord = coordinates[0] as List;
      expect(firstCoord[0], closeTo(77.56687669, 0.0001)); // longitude
      expect(firstCoord[1], closeTo(12.96206481, 0.0001)); // latitude
    });
  });

  group('iOS PolylineDecoder Error Handling Tests', () {
    test('should handle malformed encoded geometry gracefully', () {
      final lineOptions = LineOptions(
        encodedGeometry: 'invalid_encoded_string!@#\\\$%',
        encodedGeometryPrecision: 5,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      
      // Should still create valid structure for iOS to process
      expect(geoJson['type'], equals('Feature'));
      expect(geoJson['geometry']['type'], equals('LineString'));
      expect(geoJson['geometry']['encodedGeometry'], equals('invalid_encoded_string!@#\\\$%'));
      expect(geoJson['geometry']['coordinates'], isEmpty);
    });

    test('should handle special characters in encoded geometry', () {
      const String specialEncodedString = 'u{~vF@#\\\$%^&*()_+';
      
      final lineOptions = LineOptions(
        encodedGeometry: specialEncodedString,
        encodedGeometryPrecision: 5,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      expect(geoJson['geometry']['encodedGeometry'], equals(specialEncodedString));
    });

    test('should handle very long encoded geometry strings', () {
      final longEncodedString = 'u{~vFvyys@fS]' * 100; // Repeat 100 times
      
      final lineOptions = LineOptions(
        encodedGeometry: longEncodedString,
        encodedGeometryPrecision: 5,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      expect(geoJson['geometry']['encodedGeometry'], equals(longEncodedString));
      expect(geoJson['geometry']['encodedGeometry'].length, equals(13 * 100));
    });

    test('should handle zero precision value', () {
      final lineOptions = LineOptions(
        encodedGeometry: testEncodedPolyline,
        encodedGeometryPrecision: 0,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      expect(geoJson['geometry']['encodedGeometryPrecision'], equals(0));
    });

    test('should handle missing geometry data', () {
      final lineOptions = LineOptions(
        lineColor: '#FF0000',
        lineWidth: 4.0,
      );

      final geoJson = lineOptions.toGeoJson();
      
      expect(geoJson['type'], equals('Feature'));
      expect(geoJson.containsKey('geometry'), isFalse); // No geometry when neither encodedGeometry nor geometry is provided
    });
  });

  group('iOS PolylineDecoder Integration Tests', () {
    test('should handle complete workflow from Flutter to iOS', () {
      // Simulate the complete data flow from Flutter to iOS
      final lineOptions = LineOptions(
        encodedGeometry: testEncodedPolyline,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
        lineWidth: 4.0,
        lineOpacity: 0.8,
      );

      // Step 1: Convert to JSON (what gets sent to platform)
      final json = lineOptions.toJson();
      expect(json['encodedGeometry'], equals(testEncodedPolyline));
      expect(json['encodedGeometryPrecision'], equals(testPrecision));

      // Step 2: Convert to GeoJSON (what gets processed by iOS)
      final geoJson = lineOptions.toGeoJson();
      expect(geoJson['geometry']['encodedGeometry'], equals(testEncodedPolyline));
      expect(geoJson['geometry']['encodedGeometryPrecision'], equals(testPrecision));
      expect(geoJson['geometry']['coordinates'], isEmpty); // Placeholder for iOS

      // Step 3: Verify properties are preserved
      final properties = geoJson['properties'] as Map<String, dynamic>;
      expect(properties['lineColor'], equals('#FF0000'));
      expect(properties['lineWidth'], equals(4.0));
      expect(properties['lineOpacity'], equals(0.8));
    });
  });
}
