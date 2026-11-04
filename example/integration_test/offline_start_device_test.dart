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

/// Requires an installed region and physically disabled device radios BEFORE
/// launch. A human confirmation/host radio change is required in addition to
/// failed network probes; an HTTP error alone does not establish offline mode.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  var heapCaptured = false;
  developer.registerExtension('ext.nbmapsTest.control', (_, parameters) async {
    if (parameters['action'] == 'heap') heapCaptured = true;
    return developer.ServiceExtensionResponse.result('{"ok":true}');
  });
  testWidgets('cold start using physical-device offline data', (tester) async {
    final results = <Map<String, Object?>>[];
    final images = <String, String>{};
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'requiresCompletion': true,
      'completed': false,
      'results': results,
      'snapshots': images,
      'physicalOfflineConfirmed':
          const bool.fromEnvironment('PHYSICAL_OFFLINE_CONFIRMED'),
    };
    expect(const bool.fromEnvironment('PHYSICAL_OFFLINE_CONFIRMED'), isTrue,
        reason: 'Confirm actual system radio changes before this test');
    var failedProbes = 0;
    for (var i = 0; i < 3; i++) {
      if (!await canReachHttpServer(Uri.parse(
          'https://nb-oregon-cdn.nextbillion.io/navigation/us_telangana/maps/1/basic/regions/7242.gz?probe=${DateTime.now().microsecondsSinceEpoch}'))) {
        failedProbes++;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    binding.reportData!['offlineProbeFailures'] = failedProbes;
    expect(failedProbes, 3);
    await NextBillion.initNextBillionWithTileServer(
        MapsDemo.accessKey, WellKnownTileServer.nbTomtom);
    await RegionalOffline.configure();
    final installed = await RegionalOffline.listInstalledRegions();
    final region = [
      7242,
      3474,
      6980
    ].firstWhere((id) => installed.any((r) => r.regionId == id && r.allTarsOk));
    binding.reportData!['primaryRegionId'] = region;
    expect((await RegionalOffline.loadOfflineDetail(region)).detail?.regionId,
        region);
    final center = region == 7242
        ? const LatLng(-33.9135, 151.2055)
        : region == 3474
            ? const LatLng(37.725, -122.433)
            : const LatLng(17.348, 78.486);
    final key = GlobalKey<OfflineNavigationState>();
    await tester.pumpWidget(MaterialApp(
        home: OfflineNavigationView(
            key: key,
            initialTrack: PlaybackTrack('Offline verification track', [
              center,
              LatLng(center.latitude + 0.001, center.longitude + 0.001),
              LatLng(center.latitude + 0.002, center.longitude + 0.002)
            ]))));
    Future<void> waitFor(bool Function() ready) async {
      final end = DateTime.now().add(const Duration(seconds: 90));
      while (!ready() && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(ready(), isTrue);
    }

    final state = key.currentState!;
    await waitFor(() => state.routeReady && state.configured);
    await state.seek(0.4);
    state.setPlaying(true);
    await Future<void>.delayed(const Duration(seconds: 2));
    state.setPlaying(false);
    expect(state.fraction, greaterThan(0.4));
    expect(state.error, isNull);
    // Allow local vector tiles and Metal/GPU frames to settle before evidence.
    await Future<void>.delayed(const Duration(seconds: 3));
    if (Platform.isIOS) {
      final bytes =
          await const MethodChannel('plugins.flutter.io/integration_test')
              .invokeMethod<List<dynamic>>(
                  'captureScreenshot', {'name': 'cold-offline-ui'});
      if (bytes != null)
        images['cold-offline-ui'] = base64Encode(bytes.cast<int>());
    }
    // Host captures the Android platform view independently of native snapshot.
    // ignore: avoid_print
    print('NB_COLD_OFFLINE_SCREENSHOT_READY');
    if (Platform.isAndroid) {
      await Future<void>.delayed(const Duration(seconds: 3));
    }
    try {
      final snapshot = await state.map!.takeSnapshot(
          SnapshotOptions(width: 320, height: 240, writeToDisk: false));
      expect(snapshot, isNotNull);
      images['cold-offline-map'] =
          snapshot!.contains(',') ? snapshot.split(',').last : snapshot;
    } on PlatformException catch (error) {
      results.add({
        'id': 'SNAP-001',
        'status': 'fail',
        'error':
            '${error.code}: offline native snapshot failed; full UI image captured independently'
      });
    }
    results.add({
      'id': 'NET-009',
      'status': 'partial',
      'evidence':
          'Human/host confirmed radios disabled before process launch; 3 failed probes, local metadata, fresh high-zoom map, timed route playback, native and UI images. Images require visual review.'
    });
    for (var i = 0; i < 15; i++) {
      state.remountMap();
      await tester.pump(const Duration(milliseconds: 20));
    }
    await waitFor(() => state.routeReady);
    for (var i = 0; i < 25; i++) {
      final previous = state.styleLoads;
      await state.reloadStyle();
      await waitFor(() => state.styleLoads > previous && state.routeReady);
      expect(state.map!.onFeatureTapped.length, 4);
      expect(state.map!.onFeatureDrag.length, 4);
    }
    for (final id in ['MAP-004', 'MAP-009', 'ANN-001', 'ANN-002', 'ANN-012']) {
      results.add({
        'id': id,
        'status': 'partial',
        'evidence':
            '15 map replacements and 25 style reloads while system offline; listener counts 4. Dart GC sample collected separately; native leaks not established.'
      });
    }
    // ignore: avoid_print
    print('NB_TEST_WAIT_HEAP ${Platform.operatingSystem}');
    final deadline = DateTime.now().add(const Duration(minutes: 3));
    while (!heapCaptured && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    binding.reportData!['heapCaptured'] = heapCaptured;
    binding.reportData!['page'] = state.report;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    for (final result in results) {
      // ignore: avoid_print
      print('NB_DEVICE_CASE ${jsonEncode(result)}');
    }
    // ignore: avoid_print
    print('NB_TEST_OFFLINE_COMPLETE ${Platform.operatingSystem}');
    binding.reportData!['completed'] = true;
    expect(results.where((r) => r['status'] == 'fail'), isEmpty,
        reason: 'See results JSON for native failures');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
