import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/main.dart' show MapsDemo;
import 'package:nb_maps_flutter_example/offline_navigation.dart';

import 'support/network_probe.dart';

// Set by the host only after real radio changes / physical tester confirmation.
bool systemOfflineConfirmed = false;
bool systemOnlineConfirmed = false;
bool heapCaptured = false;

void main() {
  developer.registerExtension('ext.nbmapsTest.control',
      (method, parameters) async {
    switch (parameters['action']) {
      case 'offline':
        systemOfflineConfirmed = true;
      case 'online':
        systemOnlineConfirmed = true;
      case 'heap':
        heapCaptured = true;
    }
    return developer.ServiceExtensionResponse.result('{"ok":true}');
  });
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('physical device offline SDK checklist', (tester) async {
    final results = <Map<String, Object?>>[];
    final key = GlobalKey<OfflineNavigationState>();
    final initialIds = <int>{};
    final artifacts = <String, String>{};
    final clock = Stopwatch()..start();
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'requiresCompletion': true,
      'completed': false,
      'results': results,
      'snapshots': artifacts
    };

    Future<void> waitFor(bool Function() condition, {int seconds = 45}) async {
      final deadline = DateTime.now().add(Duration(seconds: seconds));
      while (!condition() && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(condition(), isTrue, reason: 'Timed out after ${seconds}s');
    }

    Future<void> check(List<String> ids, Future<void> Function() action,
        {String? evidence, bool complete = true}) async {
      final resultStart = results.length;
      final started = clock.elapsedMilliseconds;
      try {
        await action();
        for (final id in ids) {
          results.add({
            'id': id,
            'status': complete ? 'pass' : 'partial',
            'ms': clock.elapsedMilliseconds - started,
            'evidence': evidence ?? 'Real native SDK assertions'
          });
        }
      } catch (error) {
        final description = error is PlatformException
            ? error.code
            : error.toString().replaceAll(RegExp(r'https?://\S+'), '<url>');
        for (final id in ids) {
          results.add({
            'id': id,
            'status': 'fail',
            'error': description.substring(0, min(600, description.length))
          });
        }
      }
      // Machine-readable checkpoints, without credentials or request URLs.
      // ignore: avoid_print
      for (final result in results.skip(resultStart)) {
        // ignore: avoid_print
        print('NB_DEVICE_CASE ${jsonEncode(result)}');
      }
    }

    Future<void> blocked(List<String> ids, String reason) async {
      for (final id in ids) {
        results.add({'id': id, 'status': 'blocked', 'reason': reason});
      }
    }

    Future<void> expectCode(Future<dynamic> future, String code) => expectLater(
        future,
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', code)));

    Future<void> saveSnapshot(String name) async {
      if (Platform.isIOS) {
        final bytes =
            await const MethodChannel('plugins.flutter.io/integration_test')
                .invokeMethod<List<dynamic>>(
                    'captureScreenshot', {'name': '$name-ui'});
        if (bytes != null)
          artifacts['$name-ui'] = base64Encode(bytes.cast<int>());
      }
      try {
        final value = await key.currentState!.map!.takeSnapshot(
            SnapshotOptions(width: 320, height: 240, writeToDisk: false));
        expect(value, isNotNull);
        final raw = value!.contains(',')
            ? value.substring(value.indexOf(',') + 1)
            : value;
        expect(base64Decode(raw).length, greaterThan(500));
        artifacts[name] = raw;
      } on PlatformException catch (error) {
        if (!name.contains('offline')) rethrow;
        results.add({
          'id': 'SNAP-001',
          'status': 'fail',
          'error':
              '${error.code}: native offline snapshot failed; UI captured independently'
        });
      }
    }

    Future<bool> reachable() async {
      return canReachHttpServer(Uri.parse(
          'https://nb-oregon-cdn.nextbillion.io/navigation/us_telangana/maps/1/basic/regions/7242.gz?probe=${DateTime.now().millisecondsSinceEpoch}'));
    }

    await check(['INIT-010'], () async {
      expect(await RegionalOffline.supportStatus(),
          RegionalOfflineSupportStatus.nextbillionNotInitialized);
    });
    await NextBillion.initNextBillionWithTileServer(
        MapsDemo.accessKey, WellKnownTileServer.nbTomtom);
    await check(['INIT-001'], () async {
      expect(await RegionalOffline.supportStatus(),
          RegionalOfflineSupportStatus.supported);
    },
        evidence: 'Account and support status; map style verified separately',
        complete: false);
    await check(['INIT-011'],
        () => expectCode(RegionalOffline.fetchRegionList(), 'NOT_INITIALIZED'));

    await tester.pumpWidget(MaterialApp(
        home: OfflineNavigationView(
            key: key,
            autoInitialize: false,
            initialTrack: PlaybackTrack.presets[2])));
    await check(['BOOT-001', 'MAP-013'], () async {
      await waitFor(() => key.currentState?.map != null);
      expect(key.currentState!.configured, isFalse);
      await waitFor(() => key.currentState!.routeReady);
      expect(key.currentState!.error, isNull);
    },
        evidence:
            'Real platform view and route/style loaded before any offline configuration');

    final state = key.currentState!;
    // Current release keeps the provider fixed for each MapView. Provider
    // startup/style acceptance runs separately via provider_start_device_test.
    await blocked(['INIT-002', 'INIT-003'],
        'Run TEST_PROVIDER=maptiler/orbis in separate fresh processes');
    for (final id in ['INIT-006', if (Platform.isIOS) 'INIT-007']) {
      results.add({
        'id': id,
        'status': 'excluded',
        'reason': 'Same-MapView cross-provider switching is outside this '
            'release scope; historical SDK failures retained',
      });
    }
    await check(['CFG-001'], () async {
      await state.configureOffline();
      expect(state.configured, isTrue);
      await Future.wait(
          [RegionalOffline.configure(), RegionalOffline.configure()]);
      initialIds.addAll((await RegionalOffline.listInstalledRegions())
          .map((r) => r.regionId));
    });
    await check(
        ['CFG-003'],
        () => expectCode(
            RegionalOffline.configure(
                mapsBaseUrl: 'https://example.invalid/maps'),
            'CONFIGURATION_FAILED'));
    if (Platform.isAndroid) {
      await check(
          ['INIT-004'],
          () => expectCode(
              NextBillion.switchWellKnownTileServer(
                  WellKnownTileServer.nbTomtomOrbis),
              'SDK_UPDATE_REQUIRED'),
          evidence:
              'Post-initialization protection; in-flight race requires dedicated injection',
          complete: false);
      await check(
          ['INIT-005'],
          () => expectCode(
              NextBillion.initNextBillionWithTileServer(
                  MapsDemo.accessKey, WellKnownTileServer.nbTomtomOrbis),
              'SDK_UPDATE_REQUIRED'),
          evidence:
              'Post-initialization protection; in-flight race requires dedicated injection',
          complete: false);
    }
    await check(['INIT-013'], () async {
      await NextBillion.setApiKeyHeaderName('X-NB-Test-Key');
      expect(await NextBillion.getApiKeyHeaderName(), 'X-NB-Test-Key');
      await NextBillion.setApiKeyHeaderName(null);
      expect(await NextBillion.getApiKeyHeaderName(), isNull);
    },
        evidence: 'Native set/get/reset; request header capture still required',
        complete: false);
    await check(['DATA-001', 'DATA-002'], () async {
      await state.refreshCatalog();
      expect(state.catalog, isNotEmpty);
      final filtered =
          await RegionalOffline.fetchRegionList(country: ' Australia ');
      expect(filtered, isNotEmpty);
      expect(filtered.every((r) => r.adminL0 == 'Australia'), isTrue);
    }, evidence: 'Default CDN full catalog and trimmed-country native query');

    final candidates = [7242, 3474, 6980];
    final regionId = candidates.firstWhere((id) => !initialIds.contains(id),
        orElse: () => 7242);
    final trackIndex = regionId == 7242
        ? 2
        : regionId == 3474
            ? 1
            : 0;
    binding.reportData!['primaryRegionId'] = regionId;
    binding.reportData!['preexistingRegionIds'] = initialIds.toList();
    if (trackIndex != 2) {
      state.selectTrack(PlaybackTrack.presets[trackIndex]);
      await waitFor(() => state.routeReady);
    }
    await check(['DATA-008'], () async {
      final detail = await RegionalOffline.fetchRegionDetail(regionId);
      expect(detail.detail?.regionId, regionId);
      expect(detail.detail!.packages, isNotEmpty);
    },
        complete: false,
        evidence:
            'Existing region with packages; empty/missing regions still need fixtures');
    await check(['DL-001', 'DL-004'], () async {
      await state.download(regionId);
      final deadline = DateTime.now().add(const Duration(minutes: 10));
      while (DateTime.now().isBefore(deadline)) {
        await state.refreshInstalled();
        if (state.installed.any((r) => r.regionId == regionId && r.allTarsOk))
          break;
        await tester.pump(const Duration(seconds: 1));
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      expect(state.installed.any((r) => r.regionId == regionId && r.allTarsOk),
          isTrue);
      await waitFor(() => state.preview?.previewBundleReady == true,
          seconds: 120);
    },
        evidence: initialIds.contains(regionId)
            ? 'Existing installed region; fresh download not established'
            : 'Native accepted download, observed installed allTarsOk, Preview readiness');
    await check(['DATA-009', 'DATA-011'], () async {
      expect(
          (await RegionalOffline.loadOfflineDetail(regionId)).detail?.regionId,
          regionId);
      expect(await RegionalOffline.hasInstalledRegions(), isTrue);
      final status = await RegionalOffline.offlinePreviewResourceStatus();
      expect(status.previewBundleReady, isTrue);
      expect(status.readinessIsBundleOnly, Platform.isIOS);
    },
        evidence:
            'Local reads and readiness fields online; repeated offline below',
        complete: false);
    await check(['TRIM-001', 'TRIM-002', 'TRIM-006'], () async {
      await waitFor(() => state.routeReady);
      for (var i = 0; i <= 100; i++) {
        await state.seek(i / 100);
      }
      await state.map!.setLineLayerProperties('offline-test-route-line',
          const LineLayerProperties(lineTrimOffset: [1.0, 1.0]));
      await state.seek(1);
      expect(state.fraction, 1);
      expect(state.error, isNull);
    },
        evidence:
            '101 real native trim/marker/camera updates; visual snapshot recorded separately',
        complete: false);
    await check(['BASE-001', 'BASE-002'], () async {
      final map = state.map!;
      final target = state.track.points.first;
      await map.moveCamera(CameraUpdate.newLatLngZoom(target, 15));
      expect(await map.getVisibleRegion(), isNotNull);
      expect(await map.toScreenLocationBatch([]), isEmpty);
      final point = await map.toScreenLocation(target);
      expect(point, isNotNull);
      final returned = await map.toLatLng(Point(point!.x, point.y));
      expect((returned!.latitude - target.latitude).abs(), lessThan(0.01));
    },
        evidence:
            'Normal camera/coordinate conversion and empty batch; malformed raw channel input separate',
        complete: false);
    await check(['SNAP-001'], () => saveSnapshot('online-map'),
        complete: false,
        evidence: 'Native base64 snapshot; file output tested separately');

    // Keep native map/SDK online until the host or tester actually disconnects
    // device radios. No mock or SDK-only offline flag is used here.
    if (const bool.fromEnvironment('TEST_SYSTEM_OFFLINE', defaultValue: true)) {
      state.record('system-offline-requested');
      // ignore: avoid_print
      print('NB_TEST_WAIT_OFFLINE ${Platform.operatingSystem}');
      final deadline = DateTime.now().add(const Duration(minutes: 8));
      while (!systemOfflineConfirmed && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      var failures = 0;
      if (systemOfflineConfirmed) {
        for (var i = 0; i < 3; i++) {
          if (!await reachable()) failures++;
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
      final disconnected = systemOfflineConfirmed && failures == 3;
      binding.reportData!['physicalOfflineConfirmed'] = systemOfflineConfirmed;
      binding.reportData!['offlineProbeFailures'] = failures;
      if (!disconnected) {
        await blocked(['NET-009', 'BOOT-008'],
            'System network was not disconnected; no SDK-only override used');
      } else {
        await check(['NET-009'], () async {
          expect(
              (await RegionalOffline.loadOfflineDetail(regionId))
                  .detail
                  ?.regionId,
              regionId);
          expect(
              (await RegionalOffline.listInstalledRegions())
                  .any((r) => r.regionId == regionId),
              isTrue);
          final loads = state.styleLoads;
          // Visit a high-zoom area not traversed during online playback, so an
          // earlier online tile cache alone cannot establish the offline result.
          final center = regionId == 7242
              ? const LatLng(-33.9135, 151.2055)
              : regionId == 3474
                  ? const LatLng(37.725, -122.433)
                  : const LatLng(17.348, 78.486);
          state.selectTrack(PlaybackTrack('Offline verification track', [
            center,
            LatLng(center.latitude + 0.001, center.longitude + 0.001),
            LatLng(center.latitude + 0.002, center.longitude + 0.002)
          ]));
          await waitFor(() => state.styleLoads > loads && state.routeReady,
              seconds: 90);
          await state.seek(0.4);
          expect(state.error, isNull);
          await saveSnapshot('system-offline-map');
        },
            evidence:
                'Physical radio-off confirmation, three failed network probes, fresh native MapView at an unvisited high-zoom area; local track and image captured',
            complete: false);
        // ignore: avoid_print
        print('NB_TEST_WAIT_ONLINE ${Platform.operatingSystem}');
        final onlineDeadline = DateTime.now().add(const Duration(minutes: 8));
        var restored = false;
        while (
            !systemOnlineConfirmed && DateTime.now().isBefore(onlineDeadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        while (
            systemOnlineConfirmed && DateTime.now().isBefore(onlineDeadline)) {
          if (await reachable()) {
            restored = true;
            break;
          }
          await Future<void>.delayed(const Duration(seconds: 2));
        }
        if (restored) {
          await check(['NET-007'], () async {
            await RegionalOffline.refreshEngine();
            await waitFor(() => state.routeReady);
          });
        } else {
          await blocked(['NET-007'], 'System network not restored');
        }
      }
    } else {
      await blocked(['NET-009', 'BOOT-008'],
          'Physical system-offline stage disabled for this run');
    }

    await check(['MAP-009', 'ANN-001', 'ANN-002'], () async {
      for (var i = 0; i < 25; i++) {
        final loads = state.styleLoads;
        await state.reloadStyle();
        await waitFor(() => state.styleLoads > loads && state.routeReady);
        expect(state.map!.onFeatureTapped.length, 4);
        expect(state.map!.onFeatureDrag.length, 4);
      }
    },
        evidence:
            '25 real native style reloads; Dart listener counts remain 4; no heap-leak conclusion',
        complete: false);
    await check(['MAP-004', 'MAP-014', 'ANN-012'], () async {
      for (var i = 0; i < 15; i++) {
        state.remountMap();
        await tester.pump(const Duration(milliseconds: 20));
      }
      await waitFor(() => state.routeReady, seconds: 90);
      expect(tester.takeException(), isNull);
    },
        evidence:
            '15 rapid native map replacements, including initialization; no Dart exception; heap/late callback instrumentation remains separate',
        complete: false);
    // Allow an actual VM heap/GC sample on each physical device after stress.
    heapCaptured = false;
    // ignore: avoid_print
    print('NB_TEST_WAIT_HEAP ${Platform.operatingSystem}');
    final heapDeadline = DateTime.now().add(const Duration(minutes: 3));
    while (!heapCaptured && DateTime.now().isBefore(heapDeadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    binding.reportData!['page'] = state.report;
    binding.reportData!['elapsedMs'] = clock.elapsedMilliseconds;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    final failed = results.where((r) => r['status'] == 'fail').toList();
    binding.reportData!['completed'] = true;
    expect(failed, isEmpty,
        reason: 'See device results JSON for individual checklist failures');
  }, timeout: const Timeout(Duration(minutes: 40)));
}
