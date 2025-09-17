import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('Symbol', () {
    test('toGeoJson should return the correct GeoJSON representation', () {
      // Arrange
      const options = SymbolOptions(
        iconSize: 1.0,
        iconImage: 'symbol_icon',
        geometry: LatLng(37.7749, -122.4194),
      );
      final symbol = Symbol('symbol_id', options);

      // Act
      final geoJson = symbol.toGeoJson();

      // Assert
      expect(symbol.data, isNull);
      expect(geoJson['type'], equals('Feature'));

      final properties = geoJson['properties'] as Map<String, dynamic>;
      expect(properties['iconSize'], equals(1.0));
      expect(properties['iconImage'], equals('symbol_icon'));
      expect(properties['id'], equals('symbol_id'));

      final geometry = geoJson['geometry'] as Map<String, dynamic>;
      expect(geometry['type'], equals('Point'));
      expect(geometry['coordinates'], equals([-122.4194, 37.7749]));
    });


    test('translate should update the symbol options geometry', () {
      // Arrange
      const options = SymbolOptions(
        geometry: LatLng(37.7749, -122.4194),
      );
      final symbol = Symbol('symbol_id', options);
      const delta = LatLng(0.1, 0.1);

      // Act
      symbol.translate(delta);

      // Assert
      // expect(symbol.options.geometry, equals(LatLng(37.8749, -122.3194)));
      expect(symbol.options.geometry!.latitude, closeTo(37.8749, 0.00001));
      expect(symbol.options.geometry!.longitude, closeTo(-122.3194, 0.00001));
    });
  });

  group('SymbolOptions', () {
    test('toJson should return the correct JSON representation', () {
      // Arrange
      const options = SymbolOptions(
        iconSize: 1.0,
        iconImage: 'symbol_icon',
        geometry: LatLng(37.7749, -122.4194),
      );

      // Act
      final json = options.toJson();

      // Assert
      expect(json['iconSize'], equals(1.0));
      expect(json['iconImage'], equals('symbol_icon'));

      final geometry = json['geometry'] as List<dynamic>;
      expect(geometry, equals([37.7749, -122.4194]));
    });


    test('toGeoJson should return the correct GeoJSON representation', () {
      // Arrange
      const options = SymbolOptions(
        iconSize: 1.0,
        iconImage: 'symbol_icon',
        geometry: LatLng(37.7749, -122.4194),
      );

      // Act
      final geoJson = options.toGeoJson();

      // Assert
      expect(geoJson['type'], equals('Feature'));

      final properties = geoJson['properties'] as Map<String, dynamic>;
      expect(properties['iconSize'], equals(1.0));
      expect(properties['iconImage'], equals('symbol_icon'));

      final geometry = geoJson['geometry'] as Map<String, dynamic>;
      expect(geometry['type'], equals('Point'));
      expect(geometry['coordinates'], equals([-122.4194, 37.7749]));
    });


    test('copyWith should create a new SymbolOptions with the given changes',
        () {
      // Arrange
          const options = SymbolOptions(
        iconSize: 1.0,
        iconImage: 'symbol_icon',
        geometry:  LatLng(37.7749, -122.4194),
      );
          const changes = SymbolOptions(
        iconSize: 2.0,
        iconImage: 'new_symbol_icon',
      );

      // Act
      final newOptions = options.copyWith(changes);

      // Assert
      expect(newOptions.iconSize, equals(2.0));
      expect(newOptions.iconImage, equals('new_symbol_icon'));
      expect(newOptions.geometry, equals(const LatLng(37.7749, -122.4194)));
    });
  });
}
