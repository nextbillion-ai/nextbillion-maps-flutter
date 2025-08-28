import 'package:flutter_test/flutter_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

void main() {
  group('Encoded Geometry Integration Tests', () {
    test('should create LineOptions with encoded geometry correctly', () {
      const String testEncodedGeometry = 'u{~vFvyys@fS]';
      const int testPrecision = 5;

      final lineOptions = LineOptions(
        encodedGeometry: testEncodedGeometry,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
        lineWidth: 4.0,
        lineOpacity: 0.8,
      );

      // Verify the line options are created correctly
      expect(lineOptions.encodedGeometry, equals(testEncodedGeometry));
      expect(lineOptions.encodedGeometryPrecision, equals(testPrecision));
      expect(lineOptions.lineColor, equals('#FF0000'));
      expect(lineOptions.lineWidth, equals(4.0));
      expect(lineOptions.lineOpacity, equals(0.8));
    });

    test('should serialize to JSON correctly for platform communication', () {
      const String testEncodedGeometry = 'u{~vFvyys@fS]';
      const int testPrecision = 5;

      final lineOptions = LineOptions(
        encodedGeometry: testEncodedGeometry,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
        lineWidth: 4.0,
        lineOpacity: 0.8,
      );

      final json = lineOptions.toJson();

      // Verify JSON structure for platform communication
      expect(json['encodedGeometry'], equals(testEncodedGeometry));
      expect(json['encodedGeometryPrecision'], equals(testPrecision));
      expect(json['lineColor'], equals('#FF0000'));
      expect(json['lineWidth'], equals(4.0));
      expect(json['lineOpacity'], equals(0.8));
      expect(json.containsKey('geometry'), isFalse); // Should not include regular geometry
    });

    test('should create GeoJSON correctly for native processing', () {
      const String testEncodedGeometry = 'u{~vFvyys@fS]';
      const int testPrecision = 5;

      final lineOptions = LineOptions(
        encodedGeometry: testEncodedGeometry,
        encodedGeometryPrecision: testPrecision,
        lineColor: '#FF0000',
        lineWidth: 4.0,
        lineOpacity: 0.8,
        draggable: true,
      );

      final geoJson = lineOptions.toGeoJson();

      // Verify GeoJSON structure
      expect(geoJson['type'], equals('Feature'));
      expect(geoJson['properties'], isNotNull);
      expect(geoJson['geometry'], isNotNull);

      // Verify geometry
      final geometry = geoJson['geometry'] as Map<String, dynamic>;
      expect(geometry['type'], equals('LineString'));
      expect(geometry['encodedGeometry'], equals(testEncodedGeometry));
      expect(geometry['encodedGeometryPrecision'], equals(testPrecision));
      expect(geometry['coordinates'], isEmpty); // Placeholder for native processing

      // Verify properties
      final properties = geoJson['properties'] as Map<String, dynamic>;
      expect(properties['lineColor'], equals('#FF0000'));
      expect(properties['lineWidth'], equals(4.0));
      expect(properties['lineOpacity'], equals(0.8));
      expect(properties['draggable'], equals(true));
    });

    test('should handle copyWith preserving encoded geometry', () {
      final originalOptions = LineOptions(
        encodedGeometry: 'u{~vFvyys@fS]',
        encodedGeometryPrecision: 5,
        lineColor: '#FF0000',
        lineWidth: 4.0,
      );

      final updatedOptions = originalOptions.copyWith(
        LineOptions(
          lineColor: '#00FF00',
          lineWidth: 6.0,
        ),
      );

      expect(updatedOptions.encodedGeometry, equals('u{~vFvyys@fS]'));
      expect(updatedOptions.encodedGeometryPrecision, equals(5));
      expect(updatedOptions.lineColor, equals('#00FF00'));
      expect(updatedOptions.lineWidth, equals(6.0));
    });

    test('should handle copyWith updating encoded geometry', () {
      final originalOptions = LineOptions(
        encodedGeometry: 'originalEncoded',
        encodedGeometryPrecision: 5,
        lineColor: '#FF0000',
      );

      final updatedOptions = originalOptions.copyWith(
        LineOptions(
          encodedGeometry: 'newEncoded',
          encodedGeometryPrecision: 6,
        ),
      );

      expect(updatedOptions.encodedGeometry, equals('newEncoded'));
      expect(updatedOptions.encodedGeometryPrecision, equals(6));
      expect(updatedOptions.lineColor, equals('#FF0000'));
    });

    test('should prioritize encoded geometry over regular geometry', () {
      const List<LatLng> regularGeometry = [
        LatLng(12.96206481, 77.56687669),
        LatLng(12.96306481, 77.56787669),
      ];

      final lineOptions = LineOptions(
        encodedGeometry: 'u{~vFvyys@fS]',
        encodedGeometryPrecision: 5,
        geometry: regularGeometry,
        lineColor: '#FF0000',
      );

      final json = lineOptions.toJson();

      // Should include encoded geometry and not regular geometry
      expect(json['encodedGeometry'], equals('u{~vFvyys@fS]'));
      expect(json['encodedGeometryPrecision'], equals(5));
      expect(json.containsKey('geometry'), isFalse);
    });

    test('should fallback to regular geometry when encoded geometry is null', () {
      const List<LatLng> regularGeometry = [
        LatLng(12.96206481, 77.56687669),
        LatLng(12.96306481, 77.56787669),
      ];

      final lineOptions = LineOptions(
        geometry: regularGeometry,
        lineColor: '#FF0000',
      );

      final json = lineOptions.toJson();

      // Should include regular geometry and not encoded geometry
      expect(json.containsKey('encodedGeometry'), isFalse);
      expect(json.containsKey('encodedGeometryPrecision'), isFalse);
      expect(json['geometry'], isNotNull);
      expect(json['geometry'], hasLength(2));
    });

    test('should handle multiple lines with different encoded geometries', () {
      final lines = [
        LineOptions(
          encodedGeometry: 'firstEncoded',
          encodedGeometryPrecision: 5,
          lineColor: '#FF0000',
        ),
        LineOptions(
          encodedGeometry: 'secondEncoded',
          encodedGeometryPrecision: 6,
          lineColor: '#00FF00',
        ),
        LineOptions(
          encodedGeometry: 'thirdEncoded',
          encodedGeometryPrecision: 7,
          lineColor: '#0000FF',
        ),
      ];

      for (int i = 0; i < lines.length; i++) {
        final geoJson = lines[i].toGeoJson();
        expect(geoJson['geometry']['encodedGeometry'], contains('Encoded'));
        expect(geoJson['geometry']['encodedGeometryPrecision'], equals(5 + i));
      }
    });

    test('should handle FeatureCollection structure for Android processing', () {
      final feature1 = LineOptions(
        encodedGeometry: 'u{~vFvyys@fS]',
        encodedGeometryPrecision: 5,
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
      expect(firstFeature['geometry']['encodedGeometry'], equals('u{~vFvyys@fS]'));
    });

    test('should handle mixed geometry types in FeatureCollection', () {
      final encodedFeature = LineOptions(
        encodedGeometry: 'u{~vFvyys@fS]',
        encodedGeometryPrecision: 5,
        lineColor: '#FF0000',
      ).toGeoJson();

      final regularFeature = LineOptions(
        geometry: const [
          LatLng(12.96206481, 77.56687669),
          LatLng(12.96306481, 77.56787669),
        ],
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

    test('should validate data flow from Flutter to native platforms', () {
      // Simulate the complete data flow from Flutter to native platforms
      final lineOptions = LineOptions(
        encodedGeometry: 'u{~vFvyys@fS]',
        encodedGeometryPrecision: 5,
        lineColor: '#FF0000',
        lineWidth: 4.0,
        lineOpacity: 0.8,
      );

      // Step 1: Convert to JSON (what gets sent to platform method channel)
      final json = lineOptions.toJson();
      expect(json['encodedGeometry'], equals('u{~vFvyys@fS]'));
      expect(json['encodedGeometryPrecision'], equals(5));

      // Step 2: Convert to GeoJSON (what gets processed by native PolylineDecoder)
      final geoJson = lineOptions.toGeoJson();
      expect(geoJson['geometry']['encodedGeometry'], equals('u{~vFvyys@fS]'));
      expect(geoJson['geometry']['encodedGeometryPrecision'], equals(5));
      expect(geoJson['geometry']['coordinates'], isEmpty); // Placeholder for native processing

      // Step 3: Verify properties are preserved throughout the process
      final properties = geoJson['properties'] as Map<String, dynamic>;
      expect(properties['lineColor'], equals('#FF0000'));
      expect(properties['lineWidth'], equals(4.0));
      expect(properties['lineOpacity'], equals(0.8));

      // Step 4: Verify structure is compatible with both Android and iOS processing
      expect(geoJson['type'], equals('Feature'));
      expect(geoJson['geometry']['type'], equals('LineString'));
    });
  });

  group('Encoded Geometry Performance Tests', () {
    test('should handle large encoded geometry strings efficiently', () {
      // Create a large encoded string by repeating the test string
      final largeEncodedString = 'u{~vFvyys@fS]' * 1000;

      final stopwatch = Stopwatch()..start();

      final lineOptions = LineOptions(
        encodedGeometry: largeEncodedString,
        encodedGeometryPrecision: 5,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();

      stopwatch.stop();

      expect(geoJson['geometry']['encodedGeometry'], equals(largeEncodedString));
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
    });

    test('should handle many line options efficiently', () {
      final stopwatch = Stopwatch()..start();

      final lines = List.generate(1000, (index) => LineOptions(
        encodedGeometry: 'encoded_$index',
        encodedGeometryPrecision: 5,
        lineColor: '#FF0000',
      ));

      for (final line in lines) {
        line.toGeoJson();
      }

      stopwatch.stop();

      expect(lines, hasLength(1000));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be reasonably fast
    });
  });

  group('Encoded Geometry Error Handling Tests', () {
    test('should handle null encoded geometry gracefully', () {
      final lineOptions = LineOptions(
        lineColor: '#FF0000',
        lineWidth: 4.0,
      );

      final json = lineOptions.toJson();
      final geoJson = lineOptions.toGeoJson();

      expect(json.containsKey('encodedGeometry'), isFalse);
      expect(json.containsKey('encodedGeometryPrecision'), isFalse);
      expect(geoJson.containsKey('geometry'), isFalse);
    });

    test('should handle empty encoded geometry string', () {
      final lineOptions = LineOptions(
        encodedGeometry: '',
        encodedGeometryPrecision: 5,
        lineColor: '#FF0000',
      );

      final json = lineOptions.toJson();
      final geoJson = lineOptions.toGeoJson();

      expect(json['encodedGeometry'], equals(''));
      expect(json['encodedGeometryPrecision'], equals(5));
      expect(geoJson['geometry']['encodedGeometry'], equals(''));
      expect(geoJson['geometry']['coordinates'], isEmpty);
    });

    test('should handle extreme precision values', () {
      final testCases = [0, 1, 10, 100, -1];
      
      for (final precision in testCases) {
        final lineOptions = LineOptions(
          encodedGeometry: 'u{~vFvyys@fS]',
          encodedGeometryPrecision: precision,
          lineColor: '#FF0000',
        );

        final json = lineOptions.toJson();
        expect(json['encodedGeometryPrecision'], equals(precision));
      }
    });

    test('should handle special characters in encoded geometry', () {
      const String specialEncodedString = 'u{~vF@#\$%^&*()_+[]{}|;:,.<>?';
      
      final lineOptions = LineOptions(
        encodedGeometry: specialEncodedString,
        encodedGeometryPrecision: 5,
        lineColor: '#FF0000',
      );

      final geoJson = lineOptions.toGeoJson();
      expect(geoJson['geometry']['encodedGeometry'], equals(specialEncodedString));
    });
  });
}