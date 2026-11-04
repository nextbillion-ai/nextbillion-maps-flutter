import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/main.dart' show MapsDemo;
import 'package:nb_maps_flutter_example/offline_navigation.dart';

import 'support/network_probe.dart';

/// Physical offline glyph check using the SDK's installed/default database.
/// No literal control layer seeds the manager's font stack. Rendered-feature
/// queries are supplemented by physical UI captures, not treated as pixel proof.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  var offline = false;
  var online = false;
  developer.registerExtension('ext.nbmapsTest.control', (_, parameters) async {
    if (parameters['action'] == 'offline') offline = true;
    if (parameters['action'] == 'online') online = true;
    return developer.ServiceExtensionResponse.result('{"ok":true}');
  });
  testWidgets('default and explicit glyph stacks after real disconnection',
      (tester) async {
    final results = <Map<String, Object?>>[];
    final images = <String, String>{};
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'requiresCompletion': true,
      'completed': false,
      'results': results,
      'snapshots': images,
    };
    Future<void> waitFor(bool Function() ready, int seconds) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (!ready() && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(ready(), isTrue);
    }

    final key = GlobalKey<OfflineNavigationState>();
    Future<void> addLabels(String phase) async {
      final map = key.currentState!.map!;
      await map.setSymbolTextAllowOverlap(true);
      const labels = [
        'DEFAULT ABC 012',
        'EXPLICIT Café Zürich',
        'NULL FALLBACK',
        'BOLD DEF 345',
        '\u4e2d\u6587\u5730\u56fe', // CJK glyph fixture.
        'カタカナ',
        'العربية',
        'हिन्दी'
      ];
      for (var i = 0; i < labels.length; i++) {
        final geometry = LatLng(-33.8645 - i * 0.0014, 151.2070);
        final options = i == 0
            ? SymbolOptions(
                geometry: geometry,
                textField: labels[i],
                textSize: 17,
                textColor: '#a00000',
                textHaloColor: '#ffffff',
                textHaloWidth: 2)
            : i == 2
                ? SymbolOptions(
                    geometry: geometry,
                    fontNames: null,
                    textField: labels[i],
                    textSize: 17,
                    textColor: '#a00000',
                    textHaloColor: '#ffffff',
                    textHaloWidth: 2)
                : SymbolOptions(
                    geometry: geometry,
                    fontNames: i == 3 ? ['Noto-Bold'] : ['Noto-Regular'],
                    textField: labels[i],
                    textSize: 17,
                    textColor: '#a00000',
                    textHaloColor: '#ffffff',
                    textHaloWidth: 2);
        await map.addSymbol(options);
      }
      await map.moveCamera(
          CameraUpdate.newLatLngZoom(const LatLng(-33.8685, 151.2070), 12.5));
      await Future<void>.delayed(const Duration(seconds: 12));
      final features = await map.queryRenderedFeaturesInRect(
          const Rect.fromLTRB(0, 0, 10000, 10000),
          ['symbol-nbmap-annotation-0'],
          null);
      final rendered = <String>[];
      for (var feature in features ?? []) {
        if (feature is String) feature = jsonDecode(feature);
        if (feature is Map && feature['properties']?['textField'] is String) {
          rendered.add(feature['properties']['textField'] as String);
        }
      }
      results.add({
        'id': 'FONT-$phase',
        'status': labels.take(4).every(rendered.contains) ? 'partial' : 'fail',
        'requested': labels,
        'missingBasicLabels':
            labels.take(4).where((label) => !rendered.contains(label)).toList(),
        'renderedFeatures': rendered.toSet().toList(),
        'evidence': 'Physical image review required; multilingual glyphs are '
            'observations, not a promise of every language/font being bundled.',
      });
      if (Platform.isIOS) {
        final bytes =
            await const MethodChannel('plugins.flutter.io/integration_test')
                .invokeMethod<List<dynamic>>(
                    'captureScreenshot', {'name': phase});
        if (bytes != null) images[phase] = base64Encode(bytes.cast<int>());
      }
      // ignore: avoid_print
      print('NB_FONT_SCREENSHOT_READY $phase');
      await Future<void>.delayed(const Duration(seconds: 5));
    }

    try {
      await NextBillion.initNextBillionWithTileServer(
          MapsDemo.accessKey, WellKnownTileServer.nbTomtom);
      await tester.pumpWidget(MaterialApp(
          home: OfflineNavigationView(
              key: key, initialTrack: PlaybackTrack.presets[2])));
      await waitFor(
          () =>
              key.currentState?.configured == true &&
              key.currentState?.routeReady == true,
          60);
      expect(
          (await RegionalOffline.listInstalledRegions())
              .any((r) => r.regionId == 7242 && r.allTarsOk),
          isTrue);
      const offlineStart = bool.fromEnvironment('OFFLINE_START');
      if (offlineStart) {
        expect(
            const bool.fromEnvironment('PHYSICAL_OFFLINE_CONFIRMED'), isTrue);
      } else {
        await addLabels('online-warm');
        // ignore: avoid_print
        print('NB_FONT_WAIT_OFFLINE');
        await waitFor(() => offline, 1800);
      }
      for (var i = 0; i < 3; i++) {
        expect(
            await canReachHttpServer(Uri.parse(
                'https://nb-oregon-cdn.nextbillion.io/?probe=${DateTime.now().microsecondsSinceEpoch}')),
            isFalse);
      }
      await Future<void>.delayed(const Duration(seconds: 5));
      key.currentState!.remountMap();
      await waitFor(() => key.currentState!.routeReady, 60);
      await addLabels('offline-fresh-map');
      // Retain the snapshot API's independent result even when it fails.
      try {
        final image = await key.currentState!.map!
            .takeSnapshot(
                SnapshotOptions(width: 320, height: 240, writeToDisk: false))
            .timeout(const Duration(seconds: 60));
        expect(image, isNotNull);
        results.add({'id': 'SNAP-OFFLINE', 'status': 'pass'});
      } catch (error) {
        results.add({
          'id': 'SNAP-OFFLINE',
          'status': 'fail',
          'error': error is PlatformException
              ? error.code
              : error.runtimeType.toString()
        });
      }
      // ignore: avoid_print
      print('NB_FONT_WAIT_ONLINE');
      await waitFor(() => online, 1800);
      await RegionalOffline.refreshEngine();
      binding.reportData!['completed'] = true;
      for (final result in results) {
        // ignore: avoid_print
        print('NB_DEVICE_CASE ${jsonEncode(result)}');
      }
    } finally {
      await tester.pumpWidget(const SizedBox());
    }
  }, timeout: const Timeout(Duration(minutes: 65)));
}
