import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/main.dart' show MapsDemo;
import 'package:nb_maps_flutter_example/offline_navigation.dart';

/// USB VM-service heap samples at baseline and after 100 complete page visits.
/// These are Dart samples, not evidence of native/GPU leak absence.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  var heapAcknowledgements = 0;
  developer.registerExtension('ext.nbmapsTest.control', (_, parameters) async {
    if (parameters['action'] == 'heap') heapAcknowledgements++;
    return developer.ServiceExtensionResponse.result('{"ok":true}');
  });
  testWidgets('100 full map and download-page lifecycles', (tester) async {
    final results = <Map<String, Object?>>[];
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'requiresCompletion': true,
      'completed': false,
      'results': results,
    };
    Future<void> waitFor(bool Function() ready, Duration timeout) async {
      final deadline = DateTime.now().add(timeout);
      while (!ready() && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 50));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(ready(), isTrue);
    }

    Future<void> sample(String phase) async {
      final before = heapAcknowledgements;
      // ignore: avoid_print
      print('NB_TEST_WAIT_HEAP $phase');
      await waitFor(
          () => heapAcknowledgements > before, const Duration(seconds: 90));
    }

    Future<void> visit() async {
      final key = GlobalKey<OfflineNavigationState>();
      await tester.pumpWidget(MaterialApp(
          home: OfflineNavigationView(
              key: key, initialTrack: PlaybackTrack.presets[2])));
      await waitFor(
          () =>
              key.currentState?.routeReady == true &&
              key.currentState?.configured == true,
          const Duration(seconds: 40));
      final state = key.currentState!;
      expect(state.error, isNull);
      await state.seek(0.5);
      expect(state.map!.onFeatureTapped.length, 4);
      expect(state.map!.onFeatureDrag.length, 4);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    try {
      await NextBillion.initNextBillionWithTileServer(
          MapsDemo.accessKey, WellKnownTileServer.nbTomtom);
      // Warm caches once, then compare equivalent empty-page states.
      await visit();
      await sample('baseline');
      for (var i = 0; i < 100; i++) {
        await visit();
        if ((i + 1) % 10 == 0) {
          // ignore: avoid_print
          print('NB_LIFECYCLE_VISITS ${i + 1}');
        }
      }
      await tester.pump(const Duration(seconds: 2));
      await sample('after-100');
      for (final id in ['MEM-001', 'MEM-003']) {
        final record = {
          'id': id,
          'status': 'partial',
          'evidence':
              '100 complete map/download-page visits with style, route, camera and event subscriptions; four manager listeners each visit; empty-page forced-GC baseline and final samples captured by host. Native MapView/observer/GPU allocations not instrumented.'
        };
        results.add(record);
        // ignore: avoid_print
        print('NB_DEVICE_CASE ${jsonEncode(record)}');
      }
      binding.reportData!['completed'] = true;
    } finally {
      await tester.pumpWidget(const SizedBox());
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
