import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/main.dart' show MapsDemo;
import 'package:nb_maps_flutter_example/offline_navigation.dart';

/// Run TEST_PROVIDER=tomtom/maptiler/orbis separately, each in a fresh process.
/// Existing-MapView cross-provider switching is excluded from this release.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
      'fixed provider initialization, style cycle and route restoration',
      (tester) async {
    const name =
        String.fromEnvironment('TEST_PROVIDER', defaultValue: 'tomtom');
    final server = switch (name) {
      'tomtom' => WellKnownTileServer.nbTomtom,
      'maptiler' => WellKnownTileServer.nbMapTiler,
      'orbis' => WellKnownTileServer.nbTomtomOrbis,
      _ =>
        throw ArgumentError('TEST_PROVIDER must be tomtom, maptiler or orbis'),
    };
    final initId = switch (server) {
      WellKnownTileServer.nbTomtom => 'INIT-001',
      WellKnownTileServer.nbMapTiler => 'INIT-002',
      WellKnownTileServer.nbTomtomOrbis => 'INIT-003',
    };
    final results = <Map<String, Object?>>[];
    final images = <String, String>{};
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'provider': name,
      'scope': 'fixed-provider, fresh process, no cross-provider switching',
      'requiresCompletion': true,
      'completed': false,
      'results': results,
      'snapshots': images,
    };
    void record(Map<String, Object?> value) {
      results.add(value);
      // ignore: avoid_print
      print('NB_DEVICE_CASE ${jsonEncode(value)}');
    }

    Future<void> waitFor(bool Function() ready, [int seconds = 45]) async {
      final until = DateTime.now().add(Duration(seconds: seconds));
      while (!ready() && DateTime.now().isBefore(until)) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(ready(), isTrue,
          reason: 'Expected style/route within ${seconds}s');
    }

    final key = GlobalKey<OfflineNavigationState>();
    try {
      // Provider selection happens once, before any MapView is constructed.
      await NextBillion.initNextBillionWithTileServer(
          MapsDemo.accessKey, server);
      final expectedSupport = server == WellKnownTileServer.nbTomtom
          ? RegionalOfflineSupportStatus.supported
          : RegionalOfflineSupportStatus.tomtomRequired;
      expect(await RegionalOffline.supportStatus(), expectedSupport);
      await tester.pumpWidget(MaterialApp(
          home: OfflineNavigationView(
              key: key,
              autoInitialize: false,
              initialTrack: PlaybackTrack.presets[2])));
      await waitFor(() => key.currentState?.routeReady == true);
      final state = key.currentState!;
      final originalMap = state.map!;
      expect(state.configured, isFalse);
      expect(state.error, isNull);
      record({
        'id': initId,
        'status': 'pass',
        'provider': name,
        'evidence':
            'Provider selected before map creation; initial style and local route loaded without offline setup'
      });
      final initialCatalog =
          (await NextBillion.predefinedStyles())!.map((s) => s.url).toList();
      final observations = <Map<String, Object?>>[];
      final failedSnapshots = <Map<String, Object?>>[];
      final incompleteRenders = <String>[];
      for (final style in [
        NBMapStyleType.bright,
        NBMapStyleType.night,
        NBMapStyleType.satellite,
        NBMapStyleType.bright
      ]) {
        final before = state.styleLoads;
        final idleBefore = state.mapIdleEvents;
        await originalMap.setStyleType(style);
        await waitFor(() => state.styleLoads > before && state.routeReady);
        expect(state.error, isNull);
        expect(identical(originalMap, state.map), isTrue);
        expect(await RegionalOffline.supportStatus(), expectedSupport);
        expect(
            (await NextBillion.predefinedStyles())!.map((s) => s.url).toList(),
            initialCatalog);
        final imageName = '$name-${observations.length + 1}-${style.name}';
        final idleDeadline = DateTime.now().add(const Duration(seconds: 20));
        while (state.mapIdleEvents <= idleBefore &&
            DateTime.now().isBefore(idleDeadline)) {
          await tester.pump(const Duration(milliseconds: 100));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        final renderIdle = state.mapIdleEvents > idleBefore;
        if (!renderIdle) incompleteRenders.add(style.name);
        await tester.pump(const Duration(seconds: 2));
        if (Platform.isIOS) {
          final bytes =
              await const MethodChannel('plugins.flutter.io/integration_test')
                  .invokeMethod<List<dynamic>>(
                      'captureScreenshot', {'name': imageName});
          if (bytes != null)
            images['$imageName-ui'] = base64Encode(bytes.cast<int>());
        }
        // An adb host watcher captures the physical Android view in this window.
        // ignore: avoid_print
        print('NB_STYLE_SCREENSHOT_READY $imageName');
        await Future<void>.delayed(const Duration(seconds: 3));
        var snapshotPassed = false;
        try {
          final snapshot = await originalMap
              .takeSnapshot(
                  SnapshotOptions(width: 320, height: 240, writeToDisk: false))
              .timeout(const Duration(seconds: 75));
          expect(snapshot, isNotNull);
          final encoded =
              snapshot!.contains(',') ? snapshot.split(',').last : snapshot;
          expect(base64Decode(encoded).length, greaterThan(500));
          images['$imageName-native'] = encoded;
          snapshotPassed = true;
        } catch (error) {
          // A snapshot failure must not prevent testing the remaining styles.
          // Retain it as a separate failing result and fail the run at the end.
          failedSnapshots.add({
            'style': style.name,
            'error': error is PlatformException
                ? error.code
                : error.runtimeType.toString(),
          });
        }
        observations.add({
          'style': style.name,
          'styleCallbackArrived': true,
          'sameController': true,
          'routeRestored': state.routeReady,
          'renderIdle': renderIdle,
          'onlineSnapshot': snapshotPassed
        });
      }
      record({
        'id': 'MAP-017',
        // Host UI images and native resource errors still need review: idle
        // can also follow failed tile requests, so callbacks alone cannot pass.
        'status': incompleteRenders.isEmpty ? 'partial' : 'fail',
        'provider': name,
        'styles': observations,
        'incompleteRenders': incompleteRenders,
        'evidence':
            'Fixed provider; bright/night/satellite/bright enum reloads and route restoration on the same controller. Host must review physical screenshots and resource errors before marking the full case passed. Snapshots recorded separately.'
      });
      record({
        'id': 'SNAP-001',
        'status': failedSnapshots.isEmpty ? 'partial' : 'fail',
        'provider': name,
        'failures': failedSnapshots,
        'evidence':
            'Online snapshots for four fixed-provider styles only; physical offline snapshots require the separate offline test',
      });
      if (server == WellKnownTileServer.nbTomtom) {
        await state.configureOffline();
        expect(state.configured, isTrue);
        await waitFor(() => state.routeReady);
        final installed = await RegionalOffline.listInstalledRegions();
        const preserved = int.fromEnvironment('PRESERVE_REGION_ID');
        if (preserved > 0) {
          expect(installed.any((r) => r.regionId == preserved && r.allTarsOk),
              isTrue);
        }
        record({
          'id': 'CFG-001',
          'status': 'partial',
          'installedRegionIds': installed.map((r) => r.regionId).toList(),
          'evidence':
              'Default-storage configure after map/style loading; concurrency tested separately'
        });
      } else {
        await expectLater(
            RegionalOffline.configure(),
            throwsA(isA<PlatformException>()
                .having((e) => e.code, 'code', 'UNSUPPORTED_TILE_SERVER')));
        expect(state.routeReady, isTrue);
        record({
          'id': 'FIXED-PROVIDER-OFFLINE-GUARD',
          'status': 'pass',
          'evidence':
              'Unsupported offline setup rejected without changing provider or disturbing the map'
        });
      }
      binding.reportData!['completed'] = true;
      expect(incompleteRenders, isEmpty,
          reason: 'Map never became idle after these style changes');
      expect(failedSnapshots, isEmpty,
          reason: 'Online snapshot failures retained above');
    } catch (error) {
      record({
        'id': 'FIXED-PROVIDER-REGRESSION',
        'status': 'fail',
        'error': error is PlatformException
            ? error.code
            : error
                .toString()
                .replaceAll(MapsDemo.accessKey, '<key>')
                .replaceAll(
                    RegExp(r'(?:https?|maptiler|tomtom|orbis)://\S+'), '<url>')
      });
      rethrow;
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  }, timeout: const Timeout(Duration(minutes: 8)));
}
