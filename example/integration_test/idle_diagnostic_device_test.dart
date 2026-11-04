import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/main.dart' show MapsDemo;

/// Isolates render-idle from route playback, annotation managers and downloads.
/// A local background has no remote resources and must also become idle.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('render idle with local and provider styles', (tester) async {
    final results = <Map<String, Object?>>[];
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'requiresCompletion': true,
      'completed': false,
      'results': results,
    };
    await NextBillion.initNextBillionWithTileServer(
        MapsDemo.accessKey, WellKnownTileServer.nbTomtom);
    final temporary = await Directory.systemTemp.createTemp('nbmaps_idle_');
    final background = File('${temporary.path}/background.json');
    await background.writeAsString(
        '{"version":8,"sources":{},"layers":[{"id":"background","type":"background","paint":{"background-color":"#556677"}}]}');
    addTearDown(() => temporary.delete(recursive: true));
    for (final local in [true, false]) {
      NextbillionMapController? controller;
      var styles = 0;
      var idles = 0;
      var cameraIdles = 0;
      await tester.pumpWidget(MaterialApp(
          home: NBMap(
        key: ValueKey(local),
        initialCameraPosition:
            const CameraPosition(target: LatLng(-33.8685, 151.2070), zoom: 13),
        myLocationEnabled: false,
        annotationOrder: const [],
        // iOS custom style configuration accepts URLs rather than inline JSON.
        styleString: local ? background.uri.toString() : null,
        styleType: NBMapStyleType.bright,
        onMapCreated: (value) => controller = value,
        onStyleLoadedCallback: () => styles++,
        onMapIdle: () => idles++,
        onCameraIdle: () => cameraIdles++,
      )));
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while ((styles == 0 || idles == 0) && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      final initialIdle = idles;
      expect(controller, isNotNull);
      await controller!
          .moveCamera(CameraUpdate.newLatLng(const LatLng(-33.8690, 151.2075)));
      final movedDeadline = DateTime.now().add(const Duration(seconds: 15));
      while (idles <= initialIdle && DateTime.now().isBefore(movedDeadline)) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      final record = {
        'id': local ? 'IDLE-LOCAL' : 'IDLE-PROVIDER-BARE',
        'status': styles > 0 && initialIdle > 0 && idles > initialIdle
            ? 'pass'
            : 'fail',
        'styleCallbacks': styles,
        'initialIdle': initialIdle,
        'afterMoveIdle': idles,
        'cameraIdleCallbacks': cameraIdles,
        'scope': 'No route, annotation managers, offline setup or animation',
      };
      results.add(record);
      if (local) {
        // A nonzero rectangle origin must not enlarge its width/height.
        await controller!.addSource(
            'query-boundary',
            GeojsonSourceProperties(data: {
              'type': 'FeatureCollection',
              'features': [
                for (final entry in [
                  // CJK and accented text exercise UTF-8 feature serialization.
                  ['inside \u4e2d\u6587 Café', -33.8690],
                  ['outside', -33.8720],
                ])
                  {
                    'type': 'Feature',
                    'properties': {'label': entry[0]},
                    'geometry': {
                      'type': 'Point',
                      'coordinates': [151.2075, entry[1]]
                    },
                  },
              ],
            }));
        await controller!.addCircleLayer(
            'query-boundary',
            'query-boundary-layer',
            const CircleLayerProperties(circleRadius: 5));
        await Future<void>.delayed(const Duration(seconds: 2));
        final point = await controller!
            .toScreenLocation(const LatLng(-33.8690, 151.2075));
        expect(point, isNotNull);
        final features = await controller!.queryRenderedFeaturesInRect(
            Rect.fromLTWH(
                point!.x.toDouble() - 8, point.y.toDouble() - 8, 16, 16),
            ['query-boundary-layer'],
            null);
        final labels = (features ?? []).map((feature) {
          final parsed = feature is String ? jsonDecode(feature) : feature;
          return (parsed as Map)['properties']['label'];
        }).toList();
        results.add({
          'id': 'QUERY-RECT-UTF8',
          'status':
              labels.length == 1 && labels.single == 'inside \u4e2d\u6587 Café'
                  ? 'pass'
                  : 'fail',
          'labels': labels,
        });
      }
      // ignore: avoid_print
      print('NB_DEVICE_CASE ${jsonEncode(record)}');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
    binding.reportData!['completed'] = true;
    expect(results.where((r) => r['status'] == 'fail'), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
