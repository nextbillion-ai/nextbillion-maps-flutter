part of "../../nb_maps_flutter.dart";

class NbMapStyles {
  static const String nbmapStreets =
      "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-light";

  /// Outdoors: A general-purpose style tailored to outdoor activities. Using this constant means
  /// your map style will always use the latest version and may change as we improve the style.
  static const String outdoors =
      "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-light";

  /// Light: Subtle light backdrop for data visualizations. Using this constant means your map
  /// style will always use the latest version and may change as we improve the style.
  static const String light =
      "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-light";

  /// Empty: Basic empty style
  static const String empty =
      "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-light";

  /// Dark: Subtle dark backdrop for data visualizations. Using this constant means your map style
  /// will always use the latest version and may change as we improve the style.
  static const String dark =
      "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-dark";

  /// Satellite: A beautiful global satellite and aerial imagery layer. Using this constant means
  /// your map style will always use the latest version and may change as we improve the style.
  static const String satellite =
      "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-satellite";

  /// Satellite Streets: Global satellite and aerial imagery with unobtrusive labels. Using this
  /// constant means your map style will always use the latest version and may change as we
  /// improve the style.
  static const String satelliteStreets =
      "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-satellite";

  /// Traffic Day: Color-coded roads based on live traffic congestion data. Traffic data is currently
  /// available in
  /// countries</a>. Using this constant means your map style will always use the latest version and
  /// may change as we improve the style.
  static const String trafficDay =
      "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-light&traffic_incidents=2/incidents_light&traffic_flow=2/flow_relative-light";

  /// Traffic Night: Color-coded roads based on live traffic congestion data, designed to maximize
  /// legibility in low-light situations. Traffic data is currently available in
  /// countries</a>. Using this constant means your map style will always use the latest version and
  /// may change as we improve the style.
  static const String trafficNight =
      "https://api.nextbillion.io/tt/style/1/style/22.2.1-9?map=2/basic_street-dark&traffic_incidents=2/incidents_dark&traffic_flow=2/flow_relative-dark";
}

/// The camera mode, which determines how the map camera will track the rendered location.
enum MyLocationTrackingMode {
  none,
  tracking,
  trackingCompass,
  trackingGPS,
}

/// Render mode
enum MyLocationRenderMode {
  normal,
  compass,
  gps,
}

/// Compass View Position
enum CompassViewPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Attribution Button Position
enum AttributionButtonPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Bounds for the map camera target.
// Used with [NbMapOptions] to wrap a [LatLngBounds] value. This allows
// distinguishing between specifying an unbounded target (null `LatLngBounds`)
// from not specifying anything (null `CameraTargetBounds`).
class CameraTargetBounds {
  /// Creates a camera target bounds with the specified bounding box, or null
  /// to indicate that the camera target is not bounded.
  const CameraTargetBounds(this.bounds);

  /// The geographical bounding box for the map camera target.
  ///
  /// A null value means the camera target is unbounded.
  final LatLngBounds? bounds;

  /// Unbounded camera target.
  static const CameraTargetBounds unbounded = CameraTargetBounds(null);

  dynamic toJson() => <dynamic>[bounds?.toList()];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;

    return other is CameraTargetBounds && bounds == other.bounds;
  }

  @override
  int get hashCode => bounds.hashCode;

  @override
  String toString() {
    return 'CameraTargetBounds(bounds: $bounds)';
  }
}

/// Preferred bounds for map camera zoom level.
// Used with [NbMapOptions] to wrap min and max zoom. This allows
// distinguishing between specifying unbounded zooming (null `minZoom` and
// `maxZoom`) from not specifying anything (null `MinMaxZoomPreference`).
class MinMaxZoomPreference {
  const MinMaxZoomPreference(this.minZoom, this.maxZoom)
      : assert(minZoom == null || maxZoom == null || minZoom <= maxZoom);

  /// The preferred minimum zoom level or null, if unbounded from below.
  final double? minZoom;

  /// The preferred maximum zoom level or null, if unbounded from above.
  final double? maxZoom;

  /// Unbounded zooming.
  static const MinMaxZoomPreference unbounded =
      MinMaxZoomPreference(null, null);

  dynamic toJson() => <dynamic>[minZoom, maxZoom];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;

    return other is MinMaxZoomPreference &&
        minZoom == other.minZoom &&
        maxZoom == other.maxZoom;
  }

  @override
  int get hashCode => Object.hash(minZoom, maxZoom);

  @override
  String toString() {
    return 'MinMaxZoomPreference(minZoom: $minZoom, maxZoom: $maxZoom)';
  }
}
