import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/page.dart';
import 'package:path_provider/path_provider.dart';

class LocalStylePage extends ExamplePage {
  const LocalStylePage() : super(const Icon(Icons.map), 'Local style');

  @override
  Widget build(BuildContext context) {
    return const LocalStyle();
  }
}

class LocalStyle extends StatefulWidget {
  const LocalStyle();

  @override
  State createState() => LocalStyleState();
}

class LocalStyleState extends State<LocalStyle> {
  NextbillionMapController? mapController;
  String? styleAbsoluteFilePath;

  @override
  void initState() {
    super.initState();

    getApplicationDocumentsDirectory().then((dir) async {
      final String documentDir = dir.path;
      final String stylesDir = '$documentDir/styles';
      const String styleJSON =
          '{"version":8,"name":"Basic","constants":{},"sources":{"mapillary":{"type":"vector","tiles":["https://d25uarhxywzl1j.cloudfront.net/v0.1/{z}/{x}/{y}.mvt"],"attribution":"<a href=\\"https://www.mapillary.com\\" target=\\"_blank\\">© Mapillary, CC BY</a>","maxzoom":14}},"sprite":"","glyphs":"","layers":[{"id":"background","type":"background","paint":{"background-color":"rgba(135, 149, 154, 1)"}},{"id":"water","type":"fill","source":"nbmap","source-layer":"water","paint":{"fill-color":"rgba(108, 148, 120, 1)"}}]}';

      await Directory(stylesDir).create(recursive: true);

      final File styleFile = File('$stylesDir/style.json');

      await styleFile.writeAsString(styleJSON);

      setState(() {
        styleAbsoluteFilePath = styleFile.path;
      });
    });
  }

  void _onMapCreated(NextbillionMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (styleAbsoluteFilePath == null) {
      return const Scaffold(
        body: Center(child: Text('Creating local style file...')),
      );
    }

    return Scaffold(
        body: NBMap(
      styleString: styleAbsoluteFilePath,
      onMapCreated: _onMapCreated,
      initialCameraPosition: const CameraPosition(target: LatLng(0.0, 0.0)),
      onStyleLoadedCallback: onStyleLoadedCallback,
    ));
  }

  void onStyleLoadedCallback() {}
}
