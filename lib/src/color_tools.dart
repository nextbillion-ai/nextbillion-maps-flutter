part of "../nb_maps_flutter.dart";

extension NbMapColorConversion on Color {

  String toHexStringRGB() {
    // final r = (this.r * 255).round().toRadixString(16).padLeft(2, '0');
    // final g = (this.g * 255).round().toRadixString(16).padLeft(2, '0');
    // final b = (this.b * 255).round().toRadixString(16).padLeft(2, '0');
    
    // ignore: deprecated_member_use
    final r = red.toRadixString(16).padLeft(2, '0');
    // ignore: deprecated_member_use
    final g = green.toRadixString(16).padLeft(2, '0');
    // ignore: deprecated_member_use
    final b = blue.toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }
}
