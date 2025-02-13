part of "../../nb_maps_flutter.dart";

abstract class Annotation {
  String get id;
  Map<String, dynamic> toGeoJson();

  void translate(LatLng delta);
}
