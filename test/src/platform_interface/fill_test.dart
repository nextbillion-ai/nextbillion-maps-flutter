import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('translateFillOptions', () {
    test('should translate fill options correctly', () {
      // Arrange
      const FillOptions options = FillOptions(
        fillOpacity: 0.5,
        fillColor: '#FF0000',
        fillOutlineColor: '#000000',
        fillPattern: 'pattern',
        geometry: [
          [
            LatLng(37.7749, -122.4194),
            LatLng(37.8095, -122.3927),
          ],
        ],
        draggable: true,
      );
      const LatLng delta = LatLng(1.0, 1.0);

      // Act
      final FillOptions result = translateFillOptions(options, delta);

      // Assert
      expect(result.fillOpacity, equals(options.fillOpacity));
      expect(result.fillColor, equals(options.fillColor));
      expect(result.fillOutlineColor, equals(options.fillOutlineColor));
      expect(result.fillPattern, equals(options.fillPattern));
      expect(result.geometry, isNotNull);
      expect(result.geometry!.length, equals(options.geometry!.length));
      expect(result.geometry![0].length, equals(options.geometry![0].length));
      expect(result.geometry![0][0].latitude,
          equals(options.geometry![0][0].latitude + delta.latitude));
      expect(result.geometry![0][0].longitude,
          equals(options.geometry![0][0].longitude + delta.longitude));
      expect(result.geometry![0][1].latitude,
          equals(options.geometry![0][1].latitude + delta.latitude));
      expect(result.geometry![0][1].longitude,
          equals(options.geometry![0][1].longitude + delta.longitude));
      expect(result.draggable, equals(options.draggable));
    });

    test('should return options as is if geometry is null', () {
      // Arrange
      const FillOptions options = FillOptions.defaultOptions;

      // Act
      final FillOptions result = translateFillOptions(options, const LatLng(1.0, 1.0));

      // Assert
      expect(result, equals(options));
    });
  });

  group('Fill', () {
    test('should create Fill instance correctly', () {
      // Arrange
      const String id = 'fill_1';
      const FillOptions options = FillOptions(
        fillOpacity: 0.5,
        fillColor: '#FF0000',
        fillOutlineColor: '#000000',
        fillPattern: 'pattern',
        geometry: [
          [
            LatLng(37.7749, -122.4194),
            LatLng(37.8095, -122.3927),
          ],
        ],
        draggable: true,
      );
      const Map<String, dynamic> data = {'key': 'value'};

      // Act
      final Fill fill = Fill(id, options, data);

      // Assert
      expect(fill.id, equals(id));
      expect(fill.options, equals(options));
      expect(fill.data, equals(data));
    });

    test('should translate fill options correctly', () {
      // Arrange
      const String id = 'fill_1';
      const FillOptions options = FillOptions(
        fillOpacity: 0.5,
        fillColor: '#FF0000',
        fillOutlineColor: '#000000',
        fillPattern: 'pattern',
        geometry: [
          [
            LatLng(37.7749, -122.4194),
            LatLng(37.8095, -122.3927),
          ],
        ],
        draggable: true,
      );
      const Map<String, dynamic> data = {'key': 'value'};
      final Fill fill = Fill(id, options, data);
      const LatLng delta = LatLng(1.0, 1.0);

      // Act
      fill.translate(delta);

      // Assert
      expect(fill.options.fillOpacity, equals(options.fillOpacity));
      expect(fill.options.fillColor, equals(options.fillColor));
      expect(fill.options.fillOutlineColor, equals(options.fillOutlineColor));
      expect(fill.options.fillPattern, equals(options.fillPattern));
      expect(fill.options.geometry, isNotNull);
      expect(fill.options.geometry!.length, equals(options.geometry!.length));
      expect(fill.options.geometry![0].length,
          equals(options.geometry![0].length));
      expect(fill.options.geometry![0][0].latitude,
          equals(options.geometry![0][0].latitude + delta.latitude));
      expect(fill.options.geometry![0][0].longitude,
          equals(options.geometry![0][0].longitude + delta.longitude));
      expect(fill.options.geometry![0][1].latitude,
          equals(options.geometry![0][1].latitude + delta.latitude));
      expect(fill.options.geometry![0][1].longitude,
          equals(options.geometry![0][1].longitude + delta.longitude));
      expect(fill.options.draggable, equals(options.draggable));
    });

    test('should convert to GeoJSON correctly', () {
      // Arrange
      const String id = 'fill_1';
      const FillOptions options = FillOptions(
        fillOpacity: 0.5,
        fillColor: '#FF0000',
        fillOutlineColor: '#000000',
        fillPattern: 'pattern',
        geometry: [
          [
            LatLng(37.7749, -122.4194),
            LatLng(37.8095, -122.3927),
          ],
        ],
        draggable: true,
      );
      final Fill fill = Fill(id, options);

      // Act
      final Map<String, dynamic> result = fill.toGeoJson();
      final properties = result['properties'] as Map<String, dynamic>;
      final geometry = result['geometry'] as Map<String, dynamic>;
      // Assert
      expect(result['type'], equals('Feature'));
      expect(properties['id'], equals(id));
      expect(geometry['type'], equals('Polygon'));

      final coordinates = geometry['coordinates'] as List<dynamic>;
      expect(coordinates, isNotNull);

      final List<dynamic> ring = coordinates[0] as List<dynamic>;
      final List<dynamic> firstPoint = ring[0] as List<dynamic>;
      final List<dynamic> secondPoint = ring[1] as List<dynamic>;

      expect(coordinates.length, equals(options.geometry!.length));
      expect((coordinates[0] as List).length, equals(options.geometry![0].length));

      expect(firstPoint[0], equals(options.geometry![0][0].longitude));
      expect(firstPoint[1], equals(options.geometry![0][0].latitude));
      expect(secondPoint[0], equals(options.geometry![0][1].longitude));
      expect(secondPoint[1], equals(options.geometry![0][1].latitude));
    });
  });

  group('FillOptions', () {
    test('should create FillOptions instance correctly', () {
      // Arrange
      const double fillOpacity = 0.5;
      const String fillColor = '#FF0000';
      const String fillOutlineColor = '#000000';
      const String fillPattern = 'pattern';
      const List<List<LatLng>> geometry = [
        [
          LatLng(37.7749, -122.4194),
          LatLng(37.8095, -122.3927),
        ],
      ];
      const bool draggable = true;

      // Act
      const FillOptions options = FillOptions(
        fillOpacity: fillOpacity,
        fillColor: fillColor,
        fillOutlineColor: fillOutlineColor,
        fillPattern: fillPattern,
        geometry: geometry,
        draggable: draggable,
      );

      // Assert
      expect(options.fillOpacity, equals(fillOpacity));
      expect(options.fillColor, equals(fillColor));
      expect(options.fillOutlineColor, equals(fillOutlineColor));
      expect(options.fillPattern, equals(fillPattern));
      expect(options.geometry, equals(geometry));
      expect(options.draggable, equals(draggable));
    });

    test('should create default FillOptions instance correctly', () {
      // Arrange

      // Act
      const FillOptions options = FillOptions.defaultOptions;

      // Assert
      expect(options.fillOpacity, isNull);
      expect(options.fillColor, isNull);
      expect(options.fillOutlineColor, isNull);
      expect(options.fillPattern, isNull);
      expect(options.geometry, isNull);
      expect(options.draggable, isNull);
    });

    test('should copy FillOptions correctly', () {
      // Arrange
      const FillOptions options = FillOptions(
        fillOpacity: 0.5,
        fillColor: '#FF0000',
        fillOutlineColor: '#000000',
        fillPattern: 'pattern',
        geometry: [
          [
            LatLng(37.7749, -122.4194),
            LatLng(37.8095, -122.3927),
          ],
        ],
        draggable: true,
      );
      const FillOptions changes = FillOptions(
        fillOpacity: 0.8,
        fillColor: '#00FF00',
        fillOutlineColor: '#FFFFFF',
        fillPattern: 'newPattern',
        geometry: [
          [
            LatLng(37.7749, -122.4194),
            LatLng(37.8095, -122.3927),
          ],
          [
            LatLng(37.7749, -122.4194),
            LatLng(37.8095, -122.3927),
          ],
        ],
        draggable: false,
      );

      // Act
      final FillOptions result = options.copyWith(changes);

      // Assert
      expect(result.fillOpacity, equals(changes.fillOpacity));
      expect(result.fillColor, equals(changes.fillColor));
      expect(result.fillOutlineColor, equals(changes.fillOutlineColor));
      expect(result.fillPattern, equals(changes.fillPattern));
      expect(result.geometry, equals(changes.geometry));
      expect(result.draggable, equals(changes.draggable));
    });

    test('should convert to JSON correctly', () {
      // Arrange
      const double fillOpacity = 0.5;
      const String fillColor = '#FF0000';
      const String fillOutlineColor = '#000000';
      const String fillPattern = 'pattern';
      const List<List<LatLng>> geometry = [
        [
          LatLng(37.7749, -122.4194),
          LatLng(37.8095, -122.3927),
        ],
      ];
      const FillOptions options = FillOptions(
        fillOpacity: fillOpacity,
        fillColor: fillColor,
        fillOutlineColor: fillOutlineColor,
        fillPattern: fillPattern,
        geometry: geometry,
      );

      // Act
      final Map<String, dynamic> result = options.toJson();

      // Assert
      expect(result['fillOpacity'], equals(fillOpacity));
      expect(result['fillColor'], equals(fillColor));
      expect(result['fillOutlineColor'], equals(fillOutlineColor));
      expect(result['fillPattern'], equals(fillPattern));
      expect(result['geometry'], isNotNull);

      final List<dynamic> outer = result['geometry'] as List<dynamic>;
      final List<dynamic> inner = outer[0] as List<dynamic>;
      final List<dynamic> firstPoint = inner[0] as List<dynamic>;
      final List<dynamic> secondPoint = inner[1] as List<dynamic>;

      expect(outer.length, equals(geometry.length));
      expect(inner.length, equals(geometry[0].length));
      expect(firstPoint[0], equals(geometry[0][0].latitude));
      expect(firstPoint[1], equals(geometry[0][0].longitude));
      expect(secondPoint[0], equals(geometry[0][1].latitude));
      expect(secondPoint[1], equals(geometry[0][1].longitude));
    });


    test('should convert to GeoJSON correctly', () {
      // Arrange
      const double fillOpacity = 0.5;
      const String fillColor = '#FF0000';
      const String fillOutlineColor = '#000000';
      const String fillPattern = 'pattern';
      const List<List<LatLng>> geometry = [
        [
          LatLng(37.7749, -122.4194),
          LatLng(37.8095, -122.3927),
        ],
      ];
      const FillOptions options = FillOptions(
        fillOpacity: fillOpacity,
        fillColor: fillColor,
        fillOutlineColor: fillOutlineColor,
        fillPattern: fillPattern,
        geometry: geometry,
      );

      // Act
      final Map<String, dynamic> result = options.toGeoJson();

      // Assert
      expect(result['type'], equals('Feature'));
      expect(result['properties'], isNotNull);

      final Map<String, dynamic> properties = result['properties'] as Map<String, dynamic>;
      expect(properties['fillOpacity'], equals(fillOpacity));
      expect(properties['fillColor'], equals(fillColor));
      expect(properties['fillOutlineColor'], equals(fillOutlineColor));
      expect(properties['fillPattern'], equals(fillPattern));

      expect(result['geometry'], isNotNull);

      final Map<String, dynamic> geometryResult = result['geometry'] as Map<String, dynamic>;
      expect(geometryResult['type'], equals('Polygon'));
      expect(geometryResult['coordinates'], isNotNull);

      final List<dynamic> coordinates = geometryResult['coordinates'] as List<dynamic>;

      final List<dynamic> firstRing = coordinates[0] as List<dynamic>;
      final List<dynamic> firstPoint = firstRing[0] as List<dynamic>;
      final List<dynamic> secondPoint = firstRing[1] as List<dynamic>;

      expect(coordinates.length, equals(geometry.length));
      expect(firstRing.length, equals(geometry[0].length));
      expect(firstPoint[0], equals(geometry[0][0].longitude));
      expect(firstPoint[1], equals(geometry[0][0].latitude));
      expect(secondPoint[0], equals(geometry[0][1].longitude));
      expect(secondPoint[1], equals(geometry[0][1].latitude));
    });

  });
}
