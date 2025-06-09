import 'package:flutter/material.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

import 'package:nb_maps_flutter_example/page.dart';

class FullMapPage extends ExamplePage {
  const FullMapPage() : super(const Icon(Icons.map), 'Full screen map');

  @override
  Widget build(BuildContext context) {
    return const FullMap();
  }
}

class FullMap extends StatefulWidget {
  const FullMap();

  @override
  State createState() => FullMapState();
}

class FullMapState extends State<FullMap> {
  NextbillionMapController? mapController;
  bool isLight = true;

  void _onMapCreated(NextbillionMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  void _onStyleLoadedCallback() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("Style loaded :)"),
      backgroundColor: Theme.of(context).primaryColor,
      duration: const Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(32.0),
          child: FloatingActionButton(
            child: const Icon(Icons.swap_horiz),
            onPressed: () => setState(
              () => isLight = !isLight,
            ),
          ),
        ),
        body: NBMap(
          styleString: isLight ? NbMapStyles.light : NbMapStyles.dark,
          onMapCreated: _onMapCreated,
          initialCameraPosition:
              const CameraPosition(target: LatLng(0.0, 0.0), zoom: 14),
          onStyleLoadedCallback: _onStyleLoadedCallback,
          myLocationTrackingMode: MyLocationTrackingMode.tracking,
          myLocationEnabled: true,
          trackCameraPosition: true,
        ));
  }
}
