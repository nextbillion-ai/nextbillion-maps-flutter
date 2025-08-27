part of "../../nb_maps_flutter.dart";

enum WellKnownTileServer {
  nbTomtom,
  nbMapTiler
}

extension WellKnownTileServerExt on WellKnownTileServer {
  String get value {
    switch (this) {
      case WellKnownTileServer.nbTomtom:
        return 'NGLTomTom';
      case WellKnownTileServer.nbMapTiler:
        return 'NGLMapTiler';
    }
  }

  static WellKnownTileServer? fromString(String value) {
    switch (value) {
      case 'NGLTomTom':
        return WellKnownTileServer.nbTomtom;
      case 'NGLMapTiler':
        return WellKnownTileServer.nbMapTiler;
      default:
        return null;
    }
  }
}