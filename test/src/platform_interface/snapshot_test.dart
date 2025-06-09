import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:test/test.dart';

class MockPlatformWrapper extends PlatformWrapper {
  @override
  bool get isAndroid => true;
}

void main() {
  test('SnapshotOptions toJson should convert to map correctly', () {
    // Arrange
    const double width = 500.0;
    const double height = 300.0;
    const LatLng centerCoordinate = LatLng(37.7749, -122.4194);
    final LatLngBounds bounds = LatLngBounds(
      southwest: const LatLng(37.7749, -122.4194),
      northeast: const LatLng(37.8095, -122.3927),
    );
    const double zoomLevel = 10.0;
    const double pitch = 45.0;
    const double heading = 90.0;
    const String styleUri = "https://example.com/mapstyle";
    const String styleJson = '{"key": "value"}';
    const bool withLogo = true;
    const bool writeToDisk = false;

    final SnapshotOptions options = SnapshotOptions(
      width: width,
      height: height,
      centerCoordinate: centerCoordinate,
      bounds: bounds,
      zoomLevel: zoomLevel,
      pitch: pitch,
      heading: heading,
      styleUri: styleUri,
      styleJson: styleJson,
      withLogo: withLogo,
      writeToDisk: writeToDisk,
    );

    // Act
    final Map<String, dynamic> result = options.toJson();

    // Assert
    expect(result['width'], equals(width));
    expect(result['height'], equals(height));
    expect(result['centerCoordinate'],
        equals([centerCoordinate.latitude, centerCoordinate.longitude]));
    expect(
        result['bounds'],
        equals([
          [bounds.southwest.latitude, bounds.southwest.longitude],
          [bounds.northeast.latitude, bounds.northeast.longitude]
        ]));
    expect(result['zoomLevel'], equals(zoomLevel));
    expect(result['pitch'], equals(pitch));
    expect(result['heading'], equals(heading));
    expect(result['styleUri'], equals(styleUri));
    expect(result['styleJson'], equals(styleJson));
    expect(result['withLogo'], equals(withLogo));
    expect(result['writeToDisk'], equals(writeToDisk));
  });

  test(
      'SnapshotOptions toJson should convert to map correctly when isAndroid == true',
      () {
    // Arrange
    const double width = 500.0;
    const double height = 300.0;

    const LatLng centerCoordinate = LatLng(37.7749, -122.4194);

    final LatLngBounds bounds = LatLngBounds(
      southwest: const LatLng(37.7749, -122.4194),
      northeast: const LatLng(37.8095, -122.3927),
    );
    const double zoomLevel = 10.0;
    const double pitch = 45.0;
    const double heading = 90.0;
    const String styleUri = "https://example.com/mapstyle";
    const String styleJson = '{"key": "value"}';
    const bool withLogo = true;
    const bool writeToDisk = false;

    final SnapshotOptions options = SnapshotOptions(
      width: width,
      height: height,
      centerCoordinate: centerCoordinate,
      bounds: bounds,
      zoomLevel: zoomLevel,
      pitch: pitch,
      heading: heading,
      styleUri: styleUri,
      styleJson: styleJson,
      withLogo: withLogo,
      writeToDisk: writeToDisk,
      platformWrapper: MockPlatformWrapper(),
    );

    final featureCollection = {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "properties": {},
          "geometry": {
            "type": "Point",
            "coordinates": [
              bounds.northeast.longitude,
              bounds.northeast.latitude
            ]
          }
        },
        {
          "type": "Feature",
          "properties": {},
          "geometry": {
            "type": "Point",
            "coordinates": [
              bounds.southwest.longitude,
              bounds.southwest.latitude
            ]
          }
        }
      ]
    };

    final feature = {
      "type": "Feature",
      "properties": {},
      "geometry": {
        "type": "Point",
        "coordinates": [centerCoordinate.longitude, centerCoordinate.latitude]
      }
    };

    // Act
    final Map<String, dynamic> result = options.toJson();

    // Assert
    expect(result['width'], equals(width));
    expect(result['height'], equals(height));

    //{type: Feature, properties: {}, geometry: {type: Point, coordinates: [-122.4194, 37.7749]}}
    expect(result['centerCoordinate'], equals(feature.toString()));
    expect(result['bounds'], equals(featureCollection.toString()));
    expect(result['zoomLevel'], equals(zoomLevel));
    expect(result['pitch'], equals(pitch));
    expect(result['heading'], equals(heading));
    expect(result['styleUri'], equals(styleUri));
    expect(result['styleJson'], equals(styleJson));
    expect(result['withLogo'], equals(withLogo));
    expect(result['writeToDisk'], equals(writeToDisk));
  });
}
