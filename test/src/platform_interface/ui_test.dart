import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:test/test.dart';

void main() {
  test('NbMapStyles constants should have correct URLs', () {
    expect(
        NbMapStyles.nbmapStreets,
        equals(
            "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-light"));
    expect(
        NbMapStyles.outdoors,
        equals(
            "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-light"));
    expect(
        NbMapStyles.light,
        equals(
            "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-light"));
    expect(
        NbMapStyles.empty,
        equals(
            "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-light"));
    expect(
        NbMapStyles.dark,
        equals(
            "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-dark"));
    expect(
        NbMapStyles.satellite,
        equals(
            "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-satellite"));
    expect(
        NbMapStyles.satelliteStreets,
        equals(
            "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-satellite"));
    expect(
        NbMapStyles.trafficDay,
        equals(
            "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-light&traffic_incidents=2/incidents_light&traffic_flow=2/flow_relative-light"));
    expect(
        NbMapStyles.trafficNight,
        equals(
            "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-dark&traffic_incidents=2/incidents_dark&traffic_flow=2/flow_relative-dark"));
  });

  test('CameraTargetBounds should have correct values', () {
    final bounds = LatLngBounds(
      southwest: const LatLng(37.7749, -122.4194),
      northeast: const LatLng(37.8095, -122.3927),
    );
    final cameraTargetBounds = CameraTargetBounds(bounds);

    expect(cameraTargetBounds.bounds, equals(bounds));
    expect(cameraTargetBounds.toJson(), equals([bounds.toList()]));
    expect(cameraTargetBounds.toString(),
        equals('CameraTargetBounds(bounds: $bounds)'));
  });

  test('CameraTargetBounds should have unbounded value', () {
    const cameraTargetBounds = CameraTargetBounds.unbounded;

    expect(cameraTargetBounds.bounds, isNull);
    expect(cameraTargetBounds.toJson(), equals([null]));
    expect(cameraTargetBounds.toString(),
        equals('CameraTargetBounds(bounds: null)'));
  });

  test('MinMaxZoomPreference should have correct values', () {
    const minZoom = 10.0;
    const maxZoom = 15.0;
    const minMaxZoomPreference = MinMaxZoomPreference(minZoom, maxZoom);

    expect(minMaxZoomPreference.minZoom, equals(minZoom));
    expect(minMaxZoomPreference.maxZoom, equals(maxZoom));
    expect(minMaxZoomPreference.toJson(), equals([minZoom, maxZoom]));
    expect(minMaxZoomPreference.toString(),
        equals('MinMaxZoomPreference(minZoom: $minZoom, maxZoom: $maxZoom)'));
  });

  test('MinMaxZoomPreference should have unbounded values', () {
    const minMaxZoomPreference = MinMaxZoomPreference.unbounded;

    expect(minMaxZoomPreference.minZoom, isNull);
    expect(minMaxZoomPreference.maxZoom, isNull);
    expect(minMaxZoomPreference.toJson(), equals([null, null]));
    expect(minMaxZoomPreference.toString(),
        equals('MinMaxZoomPreference(minZoom: null, maxZoom: null)'));
  });

  group('CameraTargetBounds', () {
    test('== returns true for identical objects', () {
      final bounds = LatLngBounds(
        southwest: const LatLng(37.7749, -122.4194),
        northeast: const LatLng(37.8095, -122.3927),
      );
      final bounds1 = CameraTargetBounds(bounds);
      final bounds2 = bounds1;

      expect(bounds1 == bounds2, isTrue);
    });

    test('== returns false for different types', () {
      const bounds = CameraTargetBounds.unbounded;
      const other = 'not a CameraTargetBounds';

      expect(bounds == other as Object, isFalse);
    });


    test('== returns true for equal bounds', () {
      final bounds = LatLngBounds(
        southwest: const LatLng(37.7749, -122.4194),
        northeast: const LatLng(37.8095, -122.3927),
      );
      final bounds1 = CameraTargetBounds(bounds);
      final bounds2 = CameraTargetBounds(bounds);

      expect(bounds1 == bounds2, isTrue);
    });

    test('== returns false for unequal bounds', () {
      final bounds1 = LatLngBounds(
        southwest: const LatLng(37.7749, -122.4194),
        northeast: const LatLng(37.8095, -122.3927),
      );
      final cameraTargetBounds1 = CameraTargetBounds(bounds1);

      final bounds2 = LatLngBounds(
          southwest: const LatLng(37.7649, -122.5194),
          northeast: const LatLng(37.8095, -122.3727));
      final cameraTargetBounds2 = CameraTargetBounds(bounds2);

      expect(cameraTargetBounds1 == cameraTargetBounds2, isFalse);
    });

    test('hashCode returns consistent value', () {
      final bounds = LatLngBounds(
        southwest: const LatLng(37.7749, -122.4194),
        northeast: const LatLng(37.8095, -122.3927),
      );
      final cameraTargetBounds = CameraTargetBounds(bounds);

      final hashCode1 = cameraTargetBounds.hashCode;
      final hashCode2 = cameraTargetBounds.hashCode;

      expect(hashCode1, hashCode2);
    });

    test('hashCode returns different values for different objects', () {
      final bounds1 = LatLngBounds(
        southwest: const LatLng(37.7749, -122.4194),
        northeast: const LatLng(37.8095, -122.3927),
      );
      final cameraTargetBounds1 = CameraTargetBounds(bounds1);

      final bounds2 = LatLngBounds(
          southwest: const LatLng(37.7649, -122.5194),
          northeast: const LatLng(37.8095, -122.3727));
      final cameraTargetBounds2 = CameraTargetBounds(bounds2);

      expect(cameraTargetBounds1.hashCode, isNot(equals(cameraTargetBounds2.hashCode)));
    });
  });

  group('MinMaxZoomPreference', () {
    test('== returns true for identical objects', () {
      const minZoom = 10.0;
      const maxZoom = 15.0;
      const zoomPreference1 = MinMaxZoomPreference(minZoom, maxZoom);

      const zoomPreference2 = zoomPreference1;

      expect(zoomPreference1 == zoomPreference2, isTrue);
    });

    test('== returns false for different types', () {
      const minZoom = 10.0;
      const maxZoom = 15.0;
      const zoomPreference = MinMaxZoomPreference(minZoom, maxZoom);

      const other = 'not a MinMaxZoomPreference';

      expect(zoomPreference == (other as Object), isFalse);
    });


    test('== returns true for equal minZoom and maxZoom', () {
      const minZoom = 10.0;
      const maxZoom = 15.0;
      const zoomPreference1 = MinMaxZoomPreference(minZoom, maxZoom);
      const zoomPreference2 = MinMaxZoomPreference(minZoom, maxZoom);
      expect(zoomPreference1 == zoomPreference2, isTrue);
    });

    test('== returns false for unequal minZoom and maxZoom', () {
      const minZoom = 10.0;
      const maxZoom = 15.0;
      const zoomPreference1 = MinMaxZoomPreference(minZoom, maxZoom);

      const zoomPreference2 = MinMaxZoomPreference(minZoom + 1.0, maxZoom + 1.0);

      expect(zoomPreference1 == zoomPreference2, isFalse);
    });
    test('hashCode returns consistent value', () {
      const minZoom = 10.0;
      const maxZoom = 15.0;
      const zoomPreference = MinMaxZoomPreference(minZoom, maxZoom);

      final hashCode1 = zoomPreference.hashCode;
      final hashCode2 = zoomPreference.hashCode;

      expect(hashCode1, hashCode2);
    });

    test('hashCode returns different values for different objects', () {
      const minZoom = 10.0;
      const maxZoom = 15.0;
      const zoomPreference1 = MinMaxZoomPreference(minZoom, maxZoom);

      const zoomPreference2 = MinMaxZoomPreference(minZoom + 1.0, maxZoom + 1.0);

      expect(zoomPreference1.hashCode, isNot(equals(zoomPreference2.hashCode)));
    });
  });
}
