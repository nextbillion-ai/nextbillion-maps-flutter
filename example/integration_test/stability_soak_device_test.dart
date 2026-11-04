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

import 'support/process_memory.dart';

/// One-hour wall-clock soak, with equivalent empty-page GC checkpoints.
/// Host captures native process memory separately. A passing run does not prove
/// absence of C++/Metal leaks, nor cover device-wide disk exhaustion.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  var acknowledgements = 0;
  String? waitingHeapPhase;
  var completed = false;
  developer.registerExtension('ext.nbmapsTest.control', (_, parameters) async {
    if (parameters['action'] == 'heap') acknowledgements++;
    return developer.ServiceExtensionResponse.result(jsonEncode({
      'ok': true,
      'waitingHeapPhase': waitingHeapPhase,
      'completed': completed,
    }));
  });
  const minutes = int.fromEnvironment('SOAK_MINUTES', defaultValue: 60);
  testWidgets('sustained map rendering and page lifecycles', (tester) async {
    expect(minutes, greaterThan(0));
    final results = <Map<String, Object?>>[];
    final samples = <Map<String, Object?>>[];
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'requiresCompletion': true,
      'completed': false,
      'requestedMinutes': minutes,
      'results': results,
      'checkpoints': samples,
    };
    Future<void> waitFor(bool Function() ready, int seconds) async {
      final deadline = DateTime.now().add(Duration(seconds: seconds));
      while (!ready() && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(ready(), isTrue);
    }

    Future<void> sample(String phase) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      final before = acknowledgements;
      waitingHeapPhase = phase;
      // ignore: avoid_print
      print('NB_TEST_WAIT_HEAP $phase');
      await waitFor(() => acknowledgements > before, 120);
      waitingHeapPhase = null;
      final memory = {'phase': phase, ...processMemorySample()};
      if (Platform.isIOS) {
        try {
          memory['nativeWeakCounts'] =
              await const MethodChannel('plugins.flutter.io/nb_maps_flutter')
                  .invokeMapMethod<String, dynamic>('test#nativeRetention');
        } on MissingPluginException {
          memory['nativeWeakCounts'] = 'probe not installed';
        }
      }
      samples.add(memory);
      // ignore: avoid_print
      print('NB_PROCESS_MEMORY ${jsonEncode(memory)}');
    }

    var visits = 0;
    var writes = 0;
    var reloads = 0;
    var snapshots = 0;
    Future<void> visit({required bool warmup}) async {
      final key = GlobalKey<OfflineNavigationState>();
      await tester.pumpWidget(MaterialApp(
          home: OfflineNavigationView(
              key: key, initialTrack: PlaybackTrack.presets[2])));
      await waitFor(
          () =>
              key.currentState?.routeReady == true &&
              key.currentState?.configured == true,
          45);
      final state = key.currentState!;
      expect(state.error, isNull);
      final end = DateTime.now().add(Duration(seconds: warmup ? 2 : 50));
      var step = 0;
      while (DateTime.now().isBefore(end)) {
        await state.seek((step++ % 101) / 100);
        writes++;
        if (!warmup && step == 20) {
          final before = state.styleLoads;
          await state.map!.setStyleType(
              visits.isEven ? NBMapStyleType.night : NBMapStyleType.bright);
          await waitFor(
              () => state.styleLoads > before && state.routeReady, 45);
          reloads++;
        }
        expect(state.error, isNull);
        expect(state.map!.onFeatureTapped.length, 4);
        expect(state.map!.onFeatureDrag.length, 4);
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 900));
      }
      if (!warmup && visits % 5 == 0) {
        final image = await state.map!
            .takeSnapshot(
                SnapshotOptions(width: 160, height: 120, writeToDisk: false))
            .timeout(const Duration(seconds: 30));
        expect(image, isNotNull);
        final raw = image!.contains(',') ? image.split(',').last : image;
        expect(base64Decode(raw).length, greaterThan(500));
        snapshots++;
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      visits++;
    }

    try {
      await NextBillion.initNextBillionWithTileServer(
          MapsDemo.accessKey, WellKnownTileServer.nbTomtom);
      await visit(warmup: true);
      await sample('soak-baseline');
      final clock = Stopwatch()..start();
      var nextSample = 10;
      while (clock.elapsed < const Duration(minutes: minutes)) {
        await visit(warmup: false);
        // ignore: avoid_print
        print('NB_SOAK_PROGRESS ${clock.elapsed.inSeconds} $visits $writes');
        if (clock.elapsed.inMinutes >= nextSample) {
          await sample('soak-${nextSample}m');
          samples.add({
            'minute': nextSample,
            'elapsedSeconds': clock.elapsed.inSeconds,
            'visits': visits,
            'routeWrites': writes,
            'styleReloads': reloads,
          });
          nextSample += 10;
        }
      }
      await sample('soak-final');
      results.add({
        'id': 'MEM-ONE-HOUR',
        'status': minutes >= 60 ? 'partial' : 'observation',
        'elapsedSeconds': clock.elapsed.inSeconds,
        'visits': visits,
        'routeWrites': writes,
        'styleReloads': reloads,
        'snapshots': snapshots,
        'evidence':
            'Completed wall-clock soak; host GC/native-memory samples must be assessed separately. Native/GPU retain graphs and background stress are separate cases.',
      });
      binding.reportData!['completed'] = true;
      completed = true;
      // ignore: avoid_print
      print('NB_DEVICE_CASE ${jsonEncode(results.last)}');
    } finally {
      await tester.pumpWidget(const SizedBox());
    }
  }, timeout: Timeout(Duration(minutes: minutes + 15)));
}
