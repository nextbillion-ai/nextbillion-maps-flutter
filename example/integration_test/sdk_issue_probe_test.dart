import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/main.dart' show MapsDemo;
import 'package:nb_maps_flutter_example/offline_navigation.dart';

/// Diagnostic observations, not a replacement for the full release checklist.
/// Keep the app installed when driving this test to preserve offline fixtures.
/// Historical cross-provider iOS investigation is excluded from release tests.
/// Opt in only for SDK diagnosis with RUN_EXCLUDED_PROVIDER_SWITCH=true.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('SDK source investigation probes', (tester) async {
    final results = <Map<String, Object?>>[];
    final images = <String, String>{};
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'results': results,
      'snapshots': images
    };
    await NextBillion.initNextBillionWithTileServer(
        MapsDemo.accessKey, WellKnownTileServer.nbTomtom);
    final key = GlobalKey<OfflineNavigationState>();
    await tester.pumpWidget(MaterialApp(
        home: OfflineNavigationView(
            key: key,
            autoInitialize: false,
            initialTrack: PlaybackTrack.presets[2])));
    Future<bool> waitFor(bool Function() ready, [int seconds = 45]) async {
      final until = DateTime.now().add(Duration(seconds: seconds));
      while (!ready() && DateTime.now().isBefore(until)) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return ready();
    }

    expect(await waitFor(() => key.currentState?.routeReady == true), isTrue);
    final state = key.currentState!;
    if (Platform.isIOS) {
      try {
        for (final server in [
          WellKnownTileServer.nbMapTiler,
          WellKnownTileServer.nbTomtomOrbis
        ]) {
          final oldMap = state.map;
          final oldLoads = state.styleLoads;
          // A cached style callback is not proof that the new provider's network
          // resources loaded; native request errors are inspected separately.
          // ignore: avoid_print
          print('NB_PROBE_SWITCH_BEGIN ${server.name}');
          final accepted = await NextBillion.switchWellKnownTileServer(server);
          await state.map!.setStyleType(NBMapStyleType.bright);
          final loadedInOldMap = await waitFor(
              () => state.styleLoads > oldLoads && state.routeReady, 8);
          final oldBytes =
              await const MethodChannel('plugins.flutter.io/integration_test')
                  .invokeMethod<List<dynamic>>(
                      'captureScreenshot', {'name': 'before-${server.name}'});
          if (oldBytes != null)
            images['before-remount-${server.name}'] =
                base64Encode(oldBytes.cast<int>());
          // ignore: avoid_print
          print('NB_PROBE_REMOUNT_BEGIN ${server.name}');
          state.remountMap();
          final loadedAfterRemount = await waitFor(() => state.routeReady);
          results.add({
            'id': 'IOS-PROVIDER-${server.name}',
            'status': 'observation',
            'switchAccepted': accepted,
            'existingMapStyleCallbackArrived': loadedInOldMap,
            'sameProcessRemountStyleCallbackArrived': loadedAfterRemount,
            'controllerChanged': !identical(oldMap, state.map)
          });
          expect(loadedAfterRemount, isTrue);
          await Future<void>.delayed(const Duration(seconds: 2));
          final bytes =
              await const MethodChannel('plugins.flutter.io/integration_test')
                  .invokeMethod<List<dynamic>>(
                      'captureScreenshot', {'name': server.name});
          if (bytes != null)
            images['remounted-${server.name}'] =
                base64Encode(bytes.cast<int>());
          await NextBillion.switchWellKnownTileServer(
              WellKnownTileServer.nbTomtom);
          state.remountMap();
          expect(await waitFor(() => state.routeReady), isTrue);
        }
      } finally {
        await NextBillion.switchWellKnownTileServer(
            WellKnownTileServer.nbTomtom);
      }
    } else {
      final map = state.map!;
      await map.setSymbolTextAllowOverlap(true);
      await map.addSymbol(const SymbolOptions(
          geometry: LatLng(-33.8680, 151.2070),
          textField: 'MANAGER',
          textSize: 22,
          textColor: '#c00000',
          textHaloColor: '#ffffff',
          textHaloWidth: 2));
      await map.addSymbol(const SymbolOptions(
          geometry: LatLng(-33.8690, 151.2070),
          fontNames: null,
          textField: 'FALLBACK',
          textSize: 22,
          textColor: '#008000',
          textHaloColor: '#ffffff',
          textHaloWidth: 2));
      await map.addSource(
          'font-probe',
          const GeojsonSourceProperties(data: {
            'type': 'FeatureCollection',
            'features': [
              {
                'type': 'Feature',
                'properties': <String, dynamic>{},
                'geometry': {
                  'type': 'Point',
                  'coordinates': [151.2070, -33.8685]
                }
              }
            ]
          }));
      await map.addSymbolLayer(
          'font-probe',
          'font-probe-literal',
          const SymbolLayerProperties(
              textField: 'LITERAL',
              textFont: [
                'literal',
                ['Noto-Regular']
              ],
              textSize: 22,
              textColor: '#0000c0',
              textHaloColor: '#ffffff',
              textHaloWidth: 2,
              textAllowOverlap: true));
      await Future<void>.delayed(const Duration(seconds: 6));
      Future<Map<String, Object?>> observations() async {
        final counts = <String, Object?>{};
        for (final layer in [
          'symbol-nbmap-annotation-0',
          'font-probe-literal'
        ]) {
          final found = await map.queryRenderedFeaturesInRect(
              const Rect.fromLTRB(0, 0, 10000, 10000), [layer], null);
          final labels = <String>[];
          for (var feature in found ?? []) {
            if (feature is String) feature = jsonDecode(feature);
            if (feature is Map)
              labels.add((feature['properties']?['textField'] ?? 'literal')
                  .toString());
          }
          counts[layer] = labels;
        }
        return counts;
      }

      results.add({
        'id': 'ANDROID-FONT-BEFORE',
        'status': 'observation',
        'renderedTextFeatures': await observations()
      });
      // Layer changes invoke native glyph-cache eviction using static font sets.
      await map.addCircle(const CircleOptions(
          geometry: LatLng(-33.8685, 151.2068), circleRadius: 3));
      await map.setSymbolTextAllowOverlap(false);
      await map.setSymbolTextAllowOverlap(true);
      await Future<void>.delayed(const Duration(seconds: 3));
      results.add({
        'id': 'ANDROID-FONT-AFTER',
        'status': 'observation',
        'renderedTextFeatures': await observations()
      });
      await map.removeLayer('font-probe-literal');
      await map.removeSource('font-probe');
      await map.setSymbolTextAllowOverlap(false);
      await map.setSymbolTextAllowOverlap(true);
      await Future<void>.delayed(const Duration(seconds: 3));
      results.add({
        'id': 'ANDROID-FONT-WITHOUT-LITERAL-CONTROL',
        'status': 'observation',
        'renderedTextFeatures': await observations()
      });
      // Host captures the physical platform view with adb during this window.
      // ignore: avoid_print
      print('NB_PROBE_WAIT_SCREENSHOT android');
      await Future<void>.delayed(const Duration(seconds: 15));
    }
    for (final value in results) {
      // ignore: avoid_print
      print('NB_DEVICE_CASE ${jsonEncode(value)}');
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }, timeout: const Timeout(Duration(minutes: 5)),
      skip: Platform.isIOS &&
          !const bool.fromEnvironment('RUN_EXCLUDED_PROVIDER_SWITCH'));
}
