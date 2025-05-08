import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

import 'package:nb_maps_flutter_example/page.dart';

class PlaceSourcePage extends ExamplePage {
  const PlaceSourcePage() : super(const Icon(Icons.place), 'Place source');

  @override
  Widget build(BuildContext context) {
    return const PlaceSymbolBody();
  }
}

class PlaceSymbolBody extends StatefulWidget {
  const PlaceSymbolBody();

  @override
  State<StatefulWidget> createState() => PlaceSymbolBodyState();
}

class PlaceSymbolBodyState extends State<PlaceSymbolBody> {
  PlaceSymbolBodyState();

  static const sourceId = 'sydney_source';
  static const layerId = 'sydney_layer';

  bool sourceAdded = false;
  bool layerAdded = false;
  late NextbillionMapController controller;

  void _onMapCreated(NextbillionMapController controller) {
    setState(() {
      this.controller = controller;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Adds an asset image as a source to the currently displayed style
  Future<void> addImageSourceFromAsset(
      String imageSourceId, String assetName) async {
    final ByteData bytes = await rootBundle.load(assetName);
    final Uint8List list = bytes.buffer.asUint8List();
    return controller.addImageSource(
      imageSourceId,
      list,
      const LatLngQuad(
        bottomRight: LatLng(-33.86264728692581, 151.19916915893555),
        bottomLeft: LatLng(-33.86264728692581, 151.2288236618042),
        topLeft: LatLng(-33.84322353475214, 151.2288236618042),
        topRight: LatLng(-33.84322353475214, 151.19916915893555),
      ),
    );
  }

  /// Update an asset image as a source to the currently displayed style
  Future<void> updateImageSourceFromAsset(
      String imageSourceId, String assetName) async {
    final ByteData bytes = await rootBundle.load(assetName);
    final Uint8List list = bytes.buffer.asUint8List();
    return controller.updateImageSource(
      imageSourceId,
      list,
      const LatLngQuad(
        bottomRight: LatLng(-33.89884564291081, 151.25229835510254),
        bottomLeft: LatLng(-33.89884564291081, 151.20131492614746),
        topLeft: LatLng(-33.934601369931634, 151.20131492614746),
        topRight: LatLng(-33.934601369931634, 151.25229835510254),
      ),
    );
  }

  Future<void> removeImageSource(String imageSourceId) {
    return controller.removeSource(imageSourceId);
  }

  Future<void> addLayer(String imageLayerId, String imageSourceId) {
    if (layerAdded) {
      removeLayer(imageLayerId);
    }
    setState(() => layerAdded = true);
    return controller.addImageLayer(imageLayerId, imageSourceId);
  }

  Future<void> addLayerBelow(
      String imageLayerId, String imageSourceId, String belowLayerId) {
    if (layerAdded) {
      removeLayer(imageLayerId);
    }
    setState(() => layerAdded = true);
    return controller.addImageLayerBelow(
        imageLayerId, imageSourceId, belowLayerId);
  }

  Future<void> removeLayer(String imageLayerId) {
    setState(() => layerAdded = false);
    return controller.removeLayer(imageLayerId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 300.0,
          child: NBMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(-33.852, 151.211),
              zoom: 10.0,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    TextButton(
                      onPressed: sourceAdded
                          ? null
                          : () {
                              addImageSourceFromAsset(sourceId,
                                      'assets/symbols/custom-icon.png')
                                  .then((value) {
                                setState(() => sourceAdded = true);
                              });
                            },
                      child: const Text('Add source (asset image)'),
                    ),
                    TextButton(
                      onPressed: !sourceAdded
                          ? null
                          : () {
                              updateImageSourceFromAsset(sourceId,
                                      'assets/symbols/custom-icon.png')
                                  .then((value) {
                                setState(() => sourceAdded = true);
                              });
                            },
                      child: const Text('Update source (asset image)'),
                    ),
                    TextButton(
                      onPressed: sourceAdded
                          ? () async {
                              await removeLayer(layerId);
                              removeImageSource(sourceId).then((value) {
                                setState(() => sourceAdded = false);
                              });
                            }
                          : null,
                      child: const Text('Remove source (asset image)'),
                    ),
                    TextButton(
                      onPressed: sourceAdded
                          ? () => addLayer(layerId, sourceId)
                          : null,
                      child: const Text('Show layer'),
                    ),
                    TextButton(
                      onPressed: sourceAdded
                          ? () => addLayerBelow(layerId, sourceId, 'water')
                          : null,
                      child: const Text('Show layer below water'),
                    ),
                    TextButton(
                      onPressed:
                          sourceAdded ? () => removeLayer(layerId) : null,
                      child: const Text('Hide layer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
