import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('Line', () {
    test('toGeoJson should return the correct GeoJSON representation', () {
      // Arrange
      const lineOptions = LineOptions(
        lineJoin: 'round',
        lineOpacity: 0.8,
        lineColor: '#FF0000',
        lineWidth: 2.0,
        lineGapWidth: 0.0,
        lineOffset: 0.0,
        lineBlur: 0.0,
        linePattern: 'solid',
        geometry: [
          LatLng(37.7749, -122.4194),
          LatLng(37.8095, -122.3927),
        ],
        draggable: true,
      );
      final line = Line('line1', lineOptions);

      // Act
      final geoJson = line.toGeoJson();
      final properties = geoJson['properties'] as Map<String, dynamic>?;
      final geometry = geoJson['geometry'] as Map<String, dynamic>?;
      // Assert
      expect(line.data, isNull);
      expect(geoJson['type'], equals('Feature'));
      expect(properties?['lineJoin'], equals('round'));
      expect(properties?['lineOpacity'], equals(0.8));
      expect(properties?['lineColor'], equals('#FF0000'));
      expect(properties?['lineWidth'], equals(2.0));
      expect(properties?['lineGapWidth'], equals(0.0));
      expect(properties?['lineOffset'], equals(0.0));
      expect(properties?['lineBlur'], equals(0.0));
      expect(properties?['linePattern'], equals('solid'));
      expect(properties?['draggable'], equals(true));
      expect(geometry?['type'], equals('LineString'));
      expect(
        geometry?['coordinates'],
        equals([
          [-122.4194, 37.7749],
          [-122.3927, 37.8095],
        ]),
      );
    });

    test('translate should update the line geometry correctly', () {
      // Arrange
      const lineOptions = LineOptions(
        geometry: [
          LatLng(37.7749, -122.4194),
          LatLng(37.8095, -122.3927),
        ],
      );
      final line = Line('line1', lineOptions);

      // Act
      line.translate(const LatLng(0.1, 0.1));

      // Assert

      expect(line.options.geometry![0].latitude, closeTo(37.8749, 0.0001));
      expect(line.options.geometry![0].longitude, closeTo(-122.3194, 0.0001));
      expect(line.options.geometry![1].latitude, closeTo(37.9095, 0.0001));
      expect(line.options.geometry![1].longitude, closeTo(-122.2927, 0.0001));
    });

    test(
        'LineOption.toJson should contain geometry by default(addGeometry == true)',
        () {
      const lineOptions = LineOptions(
        lineJoin: 'round',
        lineOpacity: 0.8,
        lineColor: '#FF0000',
        lineWidth: 2.0,
        lineGapWidth: 0.0,
        lineOffset: 0.0,
        lineBlur: 0.0,
        linePattern: 'solid',
        geometry: [
          LatLng(37.7749, -122.4194),
          LatLng(37.8095, -122.3927),
        ],
        draggable: true,
      );

      final json = lineOptions.toJson();
      expect(json.containsKey('geometry'), true);
    });

    test('LineOption.toJson should not contain geometry if addGeometry != true',
        () {
      const lineOptions = LineOptions(
        lineJoin: 'round',
        lineOpacity: 0.8,
        lineColor: '#FF0000',
        lineWidth: 2.0,
        lineGapWidth: 0.0,
        lineOffset: 0.0,
        lineBlur: 0.0,
        linePattern: 'solid',
        geometry: [
          LatLng(37.7749, -122.4194),
          LatLng(37.8095, -122.3927),
        ],
        draggable: true,
      );
      final json = lineOptions.toJson(false);
      expect(json.containsKey('geometry'), false);
    });
  });
}
