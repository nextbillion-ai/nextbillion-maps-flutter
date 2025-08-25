part of "../../nb_maps_flutter.dart";

enum NBMapStyleType {
  bright,
  night,
  satellite,
}

extension NBMapStyleTypeExt on NBMapStyleType {
  String get value {
    switch (this) {
      case NBMapStyleType.bright:
        return 'bright';
      case NBMapStyleType.night:
        return 'night';
      case NBMapStyleType.satellite:
        return 'satellite';
    }
  }

  /// string -> enum
  static NBMapStyleType? fromString(String value) {
    switch (value) {
      case 'bright':
        return NBMapStyleType.bright;
      case 'night':
        return NBMapStyleType.night;
      case 'satellite':
        return NBMapStyleType.satellite;
      default:
        return null;
    }
  }
}
