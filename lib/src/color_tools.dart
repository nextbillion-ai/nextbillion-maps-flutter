part of nb_maps_flutter;

extension NbMapColorConversion on Color {
  String toHexStringRGB() {
    final rHex = ((r * 255).toInt() & 0xff).toRadixString(16).padLeft(2, '0');
    final gHex = ((g * 255).toInt() & 0xff).toRadixString(16).padLeft(2, '0');
    final bHex = ((b * 255).toInt() & 0xff).toRadixString(16).padLeft(2, '0');
    return '#$rHex$gHex$bHex';
  }
}
