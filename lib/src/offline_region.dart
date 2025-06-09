part of "../nb_maps_flutter.dart";

/// Description of region to be downloaded. Identifier will be generated when
/// the download is initiated.
class OfflineRegionDefinition {
  const OfflineRegionDefinition({
    required this.bounds,
    required this.mapStyleUrl,
    required this.minZoom,
    required this.maxZoom,
    this.includeIdeographs = false,
  });

  final LatLngBounds bounds;
  final String mapStyleUrl;
  final double minZoom;
  final double maxZoom;
  final bool includeIdeographs;

  @override
  String toString() =>
      "OfflineRegionDefinition, bounds = $bounds, mapStyleUrl = $mapStyleUrl, minZoom = $minZoom, maxZoom = $maxZoom";

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['bounds'] = bounds.toList();
    data['mapStyleUrl'] = mapStyleUrl;
    data['minZoom'] = minZoom;
    data['maxZoom'] = maxZoom;
    data['includeIdeographs'] = includeIdeographs;
    return data;
  }

  factory OfflineRegionDefinition.fromMap(Map<String, dynamic> map) {
    return OfflineRegionDefinition(
      bounds: _latLngBoundsFromList(map['bounds'] as List<dynamic>),
      mapStyleUrl: map['mapStyleUrl'] as String? ?? "",
      minZoom: (map['minZoom'] as num?)?.toDouble() ?? 0.0,
      maxZoom: (map['maxZoom'] as num?)?.toDouble() ?? 0.0,
      includeIdeographs: (map['includeIdeographs'] as bool?) ?? false,
    );
  }


  static LatLngBounds _latLngBoundsFromList(List<dynamic> json) {
    final List<List<dynamic>> coordinates = json.cast<List<dynamic>>();
    final LatLngBounds latLngBounds = LatLngBounds(
      southwest: LatLng(_toDouble(coordinates[0][0]), _toDouble(coordinates[0][1])),
      northeast: LatLng(_toDouble(coordinates[1][0]), _toDouble(coordinates[1][1])),
    );

    return latLngBounds;
  }


  static double _toDouble(dynamic value) => (value as num).toDouble();
}

/// Description of a downloaded region including its identifier.
class OfflineRegion {
  const OfflineRegion({
    required this.id,
    required this.definition,
    required this.metadata,
  });

  final int id;
  final OfflineRegionDefinition definition;
  final Map<String, dynamic> metadata;

  // factory OfflineRegion.fromMap(Map<String, dynamic> json) {
  //   return OfflineRegion(
  //     id: json['id'],
  //     definition: OfflineRegionDefinition.fromMap(json['definition']),
  //     metadata: json['metadata'],
  //   );
  // }

  factory OfflineRegion.fromMap(Map<String, dynamic> json) {
    final id = json['id'];
    final definition = json['definition'];
    final metadata = json['metadata'] as Map<String, dynamic>?;

    if (id == null || definition == null || metadata == null) {
      throw ArgumentError('Missing required OfflineRegion fields in JSON');
    }

    return OfflineRegion(
      id: id as int,
      definition: OfflineRegionDefinition.fromMap(definition as Map<String, dynamic>),
      metadata: metadata,
    );
  }


  @override
  String toString() =>
      "OfflineRegion, id = $id, definition = $definition, metadata = $metadata";
}
