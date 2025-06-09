import 'dart:ui';

import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('NbMapColorConversion', () {
    test('toHexStringRGB should convert color to hex string correctly', () {
      // Arrange
      const color = Color.fromARGB(255, 255, 0, 0);

      // Act
      final result = color.toHexStringRGB();

      // Assert
      expect(result, equals('#ff0000'));
    });

    test('toHexStringRGB should pad single-digit values with zeros', () {
      // Arrange
      const color = Color.fromARGB(255, 1, 2, 3);

      // Act
      final result = color.toHexStringRGB();

      // Assert
      expect(result, equals('#010203'));
    });

    test('toHexStringRGB should handle transparent color', () {
      // Arrange
      const color = Color.fromARGB(0, 255, 0, 0);

      // Act
      final result = color.toHexStringRGB();

      // Assert
      expect(result, equals('#ff0000'));
    });
  });
}
