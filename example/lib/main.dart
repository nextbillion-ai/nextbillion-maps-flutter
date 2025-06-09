import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/animate_camera.dart';
import 'package:nb_maps_flutter_example/annotation_order_maps.dart';
import 'package:nb_maps_flutter_example/click_annotations.dart';
import 'package:nb_maps_flutter_example/custom_marker.dart';
import 'package:nb_maps_flutter_example/full_map.dart';
import 'package:nb_maps_flutter_example/layer.dart';
import 'package:nb_maps_flutter_example/line.dart';
import 'package:nb_maps_flutter_example/local_style.dart';
import 'package:nb_maps_flutter_example/map_ui.dart';
import 'package:nb_maps_flutter_example/move_camera.dart';
import 'package:nb_maps_flutter_example/offline_regions.dart';
import 'package:nb_maps_flutter_example/page.dart';
import 'package:nb_maps_flutter_example/place_batch.dart';
import 'package:nb_maps_flutter_example/place_circle.dart';
import 'package:nb_maps_flutter_example/place_fill.dart';
import 'package:nb_maps_flutter_example/place_source.dart';
import 'package:nb_maps_flutter_example/place_symbol.dart';
import 'package:nb_maps_flutter_example/scrolling_map.dart';
import 'package:nb_maps_flutter_example/sources.dart';
import 'package:nb_maps_flutter_example/take_snapshot.dart';
import 'package:nb_maps_flutter_example/track_current_location.dart';
import 'package:permission_handler/permission_handler.dart';

final List<ExamplePage> _allPages = <ExamplePage>[
  const MapUiPage(),
  const FullMapPage(),
  const AnimateCameraPage(),
  const MoveCameraPage(),
  const PlaceSymbolPage(),
  const PlaceSourcePage(),
  const LinePage(),
  const LocalStylePage(),
  const LayerPage(),
  const PlaceCirclePage(),
  const PlaceFillPage(),
  const ScrollingMapPage(),
  const OfflineRegionsPage(),
  const AnnotationOrderPage(),
  const CustomMarkerPage(),
  const BatchAddPage(),
  const TakeSnapPage(),
  const ClickAnnotationPage(),
  const Sources(),
  const TrackCurrentLocationPage()
];

class MapsDemo extends StatefulWidget {
  static const String accessKey = String.fromEnvironment("ACCESS_KEY");

  @override
  State<MapsDemo> createState() => _MapsDemoState();
}

class _MapsDemoState extends State<MapsDemo> {
  @override
  void initState() {
    super.initState();
    NextBillion.initNextBillion(MapsDemo.accessKey);

    NextBillion.getUserId().then((value) {
      if (kDebugMode) {
        print("User id: $value");
      }
    });
    NextBillion.setUserId("1234");
    NextBillion.getNbId().then((value) {
      if (kDebugMode) {
        print("NB id: $value");
      }
    });

    NextBillion.getUserId().then((value) {
      if (kDebugMode) {
        print("User id: $value");
      }
    });
  }

  /// Determine the android version of the phone and turn off HybridComposition
  /// on older sdk versions to improve performance for these
  ///
  /// !!! Hybrid composition is currently broken do no use !!!
  Future<void> initHybridComposition() async {
    if (!kIsWeb && Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;
      if (sdkVersion >= 29) {
        NBMap.useHybridComposition = true;
      } else {
        NBMap.useHybridComposition = false;
      }
    }
  }

  Future<void> _pushPage(BuildContext context, ExamplePage page) async {
    final status = await Permission.location.status;
    if (status.isDenied) {
      await [Permission.location].request();
    }

    if (!mounted) return; // Check if the widget is still mounted

    // ignore: use_build_context_synchronously
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(page.title)),
        body: page,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NbMaps examples')),
      body: MapsDemo.accessKey.isEmpty ||
              MapsDemo.accessKey.contains("YOUR_TOKEN")
          ? buildAccessTokenWarning()
          : ListView.separated(
              itemCount: _allPages.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(height: 1),
              itemBuilder: (_, int index) => ListTile(
                leading: _allPages[index].leading,
                title: Text(_allPages[index].title),
                onTap: () {
                  _pushPage(context, _allPages[index]);
                },
              ),
            ),
    );
  }

  Widget buildAccessTokenWarning() {
    return Container(
      color: Colors.red[900],
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            "Using MapView requires calling Nextbillion.initNextbillion(String accessKey) before inflating or creating NBMap Widget."
          ]
              .map((text) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ))
              .toList(),
        ),
      ),
    );
  }

}

void main() {
  runApp(MaterialApp(home: MapsDemo()));
}
