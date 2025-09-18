part of "../../nb_maps_flutter.dart";

class NbDefaultStyle {
  final String url;
  final String name;
  final int version;

  NbDefaultStyle({
    required this.name,
    required this.url,
    required this.version,
  });

  factory NbDefaultStyle.fromJson(Map json) {
    return NbDefaultStyle(
      name: json['name'] as String,
      url: json['url'] as String,
      version: json['version'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'version': version,
    };
  }

  @override
  String toString() => 'NbDefaultStyle(name: $name, url: $url, version: $version)';
}
