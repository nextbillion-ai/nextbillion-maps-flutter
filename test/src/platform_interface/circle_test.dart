import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:test/test.dart';

void main() {
  test('Circle toGeoJson should return a valid GeoJSON representation', () {
    // Arrange
    const CircleOptions options = CircleOptions(
      circleRadius: 10.0,
      circleColor: "#FF0000",
      circleBlur: 0.5,
      circleOpacity: 0.8,
      circleStrokeWidth: 2.0,
      circleStrokeColor: "#000000",
      circleStrokeOpacity: 1.0,
      geometry: LatLng(37.7749, -122.4194),
      draggable: true,
    );
    final Circle circle = Circle("circle1", options);

    // Act
    final Map<String, dynamic> result = circle.toGeoJson();

    final Map<String, dynamic> properties = result["properties"] as Map<String, dynamic>;
    final Map<String, dynamic> geometry = result["geometry"] as Map<String, dynamic>;

    // Assert
    expect(circle.data, isNull);
    expect(result["type"], equals("Feature"));

    expect(properties["circleRadius"], equals(10.0));
    expect(properties["circleColor"], equals("#FF0000"));
    expect(properties["circleBlur"], equals(0.5));
    expect(properties["circleOpacity"], equals(0.8));
    expect(properties["circleStrokeWidth"], equals(2.0));
    expect(properties["circleStrokeColor"], equals("#000000"));
    expect(properties["circleStrokeOpacity"], equals(1.0));

    expect(geometry["type"], equals("Point"));
    expect(geometry["coordinates"], equals([-122.4194, 37.7749]));
  });


  test(
      'test CircleOptions.toJson(addGeometry = true) should contain geometry in the json',
      () {
    const LatLng geometry = LatLng(37.7749, -122.4194);
    const CircleOptions options = CircleOptions(
      circleRadius: 10.0,
      circleColor: "#FF0000",
      circleBlur: 0.5,
      circleOpacity: 0.8,
      circleStrokeWidth: 2.0,
      circleStrokeColor: "#000000",
      circleStrokeOpacity: 1.0,
      geometry: geometry,
      draggable: true,
    );

    final Map<String, dynamic> result = options.toJson();
    expect(result["circleRadius"], equals(10.0));
    expect(result["circleColor"], equals("#FF0000"));
    expect(result["circleBlur"], equals(0.5));
    expect(result["circleOpacity"], equals(0.8));
    expect(result["circleStrokeWidth"], equals(2.0));
    expect(result["circleStrokeColor"], equals("#000000"));
    expect(result["circleStrokeOpacity"], equals(1.0));
    expect(result["geometry"], equals(geometry.toJson()));
  });

  test(
      'test CircleOptions.toJson(addGeometry = false) should not contain geometry in the json',
      () {
        const LatLng geometry = LatLng(37.7749, -122.4194);
        const CircleOptions options = CircleOptions(
      circleRadius: 10.0,
      circleColor: "#FF0000",
      circleBlur: 0.5,
      circleOpacity: 0.8,
      circleStrokeWidth: 2.0,
      circleStrokeColor: "#000000",
      circleStrokeOpacity: 1.0,
      geometry: geometry,
      draggable: true,
    );

    final Map<String, dynamic> result = options.toJson(false);
    expect(result["circleRadius"], equals(10.0));
    expect(result["circleColor"], equals("#FF0000"));
    expect(result["circleBlur"], equals(0.5));
    expect(result["circleOpacity"], equals(0.8));
    expect(result["circleStrokeWidth"], equals(2.0));
    expect(result["circleStrokeColor"], equals("#000000"));
    expect(result["circleStrokeOpacity"], equals(1.0));
    expect(result.containsKey("geometry"), equals(false));
  });

  test('Circle translate should update the circle geometry', () {
    // Arrange
    const CircleOptions options = CircleOptions(
      geometry: LatLng(37.7749, -122.4194),
    );
    final Circle circle = Circle("circle1", options);
    const LatLng delta = LatLng(0.1, 0.2);

    // Act
    circle.translate(delta);

    // Assert
    // due to the inherent imprecision of floating point arithmetic, we use closeTo instead of equals.
    // expect(circle.options.geometry, equals(LatLng(37.8749, -122.2194)));
    expect(circle.options.geometry!.latitude, closeTo(37.8749, 0.0001));
    expect(circle.options.geometry!.longitude, closeTo(-122.2194, 0.0001));
  });
}
