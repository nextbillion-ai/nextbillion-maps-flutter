part of "../../nb_maps_flutter.dart";

class Line implements Annotation {
  Line(this._id, this.options, [this._data]);

  /// A unique identifier for this line.
  ///
  /// The identifier is an arbitrary unique string.
  final String _id;

  String get id => _id;

  final Map? _data;

  Map? get data => _data;

  /// The line configuration options most recently applied programmatically
  /// via the map controller.
  ///
  /// The returned value does not reflect any changes made to the line through
  /// touch events. Add listeners to the owning map controller to track those.
  LineOptions options;

  Map<String, dynamic> toGeoJson() {
    final geojson = options.toGeoJson();
    geojson["id"] = id;
    geojson["properties"]["id"] = id;

    return geojson;
  }

  @override
  void translate(LatLng delta) {
    options = options.copyWith(LineOptions(
        geometry: this.options.geometry?.map((e) => e + delta).toList()));
  }
}

/// Configuration options for [Line] instances.
///
/// When used to change configuration, null values will be interpreted as
/// "do not change this configuration option".
class LineOptions {
  /// Creates a set of line configuration options.
  ///
  /// By default, every non-specified field is null, meaning no desire to change
  /// line defaults or current configuration.
  /// 
  /// For geometry, you can provide either:
  /// - [geometry]: A list of LatLng points (traditional approach)
  /// - [encodedGeometry]: An encoded polyline string for better performance with large datasets
  /// 
  /// Note: If both [geometry] and [encodedGeometry] are provided, [encodedGeometry] takes precedence.
  const LineOptions({
    this.lineJoin,
    this.lineOpacity,
    this.lineColor,
    this.lineWidth,
    this.lineGapWidth,
    this.lineOffset,
    this.lineBlur,
    this.linePattern,
    this.geometry,
    this.encodedGeometry,
    this.encodedGeometryPrecision,
    this.draggable,
  });

  final String? lineJoin;
  final double? lineOpacity;
  final String? lineColor;
  final double? lineWidth;
  final double? lineGapWidth;
  final double? lineOffset;
  final double? lineBlur;
  final String? linePattern;
  
  /// Traditional geometry as a list of LatLng points.
  /// This will be ignored if [encodedGeometry] is provided.
  final List<LatLng>? geometry;
  
  /// Encoded polyline string for better performance with large datasets.
  /// This takes precedence over [geometry] if both are provided.
  /// The string should be encoded using polyline encoding algorithm.
  final String? encodedGeometry;
  
  /// Precision used for encoding the geometry string.
  /// Default precision is 5 if not specified.
  /// This is only used when [encodedGeometry] is provided.
  final int? encodedGeometryPrecision;
  
  final bool? draggable;

  static const LineOptions defaultOptions = LineOptions();

  LineOptions copyWith(LineOptions changes) {
    return LineOptions(
      lineJoin: changes.lineJoin ?? lineJoin,
      lineOpacity: changes.lineOpacity ?? lineOpacity,
      lineColor: changes.lineColor ?? lineColor,
      lineWidth: changes.lineWidth ?? lineWidth,
      lineGapWidth: changes.lineGapWidth ?? lineGapWidth,
      lineOffset: changes.lineOffset ?? lineOffset,
      lineBlur: changes.lineBlur ?? lineBlur,
      linePattern: changes.linePattern ?? linePattern,
      geometry: changes.geometry ?? geometry,
      encodedGeometry: changes.encodedGeometry ?? encodedGeometry,
      encodedGeometryPrecision: changes.encodedGeometryPrecision ?? encodedGeometryPrecision,
      draggable: changes.draggable ?? draggable,
    );
  }

  dynamic toJson([bool addGeometry = true]) {
    final Map<String, dynamic> json = <String, dynamic>{};

    void addIfPresent(String fieldName, dynamic value) {
      if (value != null) {
        json[fieldName] = value;
      }
    }

    addIfPresent('lineJoin', lineJoin);
    addIfPresent('lineOpacity', lineOpacity);
    addIfPresent('lineColor', lineColor);
    addIfPresent('lineWidth', lineWidth);
    addIfPresent('lineGapWidth', lineGapWidth);
    addIfPresent('lineOffset', lineOffset);
    addIfPresent('lineBlur', lineBlur);
    addIfPresent('linePattern', linePattern);
    
    if (addGeometry) {
      // Priority: encodedGeometry > geometry
      if (encodedGeometry != null) {
        addIfPresent('encodedGeometry', encodedGeometry);
        addIfPresent('encodedGeometryPrecision', encodedGeometryPrecision ?? 5);
      } else if (geometry != null) {
        addIfPresent('geometry',
            geometry?.map((LatLng latLng) => latLng.toJson()).toList());
      }
    }
    
    addIfPresent('draggable', draggable);
    return json;
  }

  Map<String, dynamic> toGeoJson() {
    final Map<String, dynamic> geoJson = {
      "type": "Feature",
      "properties": toJson(false),
    };
    
    // For GeoJSON, we need actual coordinates
    // If we have encodedGeometry, we'll let the native layer handle the decoding
    // and provide a placeholder here
    if (encodedGeometry != null) {
      geoJson["geometry"] = {
        "type": "LineString",
        "coordinates": [], // Placeholder - will be decoded on native side
        "encodedGeometry": encodedGeometry,
        "encodedGeometryPrecision": encodedGeometryPrecision ?? 5,
      };
    } else if (geometry != null) {
      geoJson["geometry"] = {
        "type": "LineString",
        "coordinates": geometry!.map((c) => c.toGeoJsonCoordinates()).toList()
      };
    }
    
    return geoJson;
  }
}
