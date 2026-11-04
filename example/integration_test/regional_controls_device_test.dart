import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/main.dart' show MapsDemo;

/// Downloads/deletes only a region absent at test start. Always use
/// --keep-app-running: Flutter drive otherwise uninstalls the whole test app.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('regional controls and raw channel validation', (tester) async {
    final results = <Map<String, Object?>>[];
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'requiresCompletion': true,
      'completed': false,
      'results': results
    };
    const channel =
        MethodChannel('plugins.flutter.io/nb_maps_flutter/regional_offline');
    Future<void> check(String id, Future<void> Function() action,
        {bool complete = true, String? evidence}) async {
      try {
        await action().timeout(const Duration(seconds: 60));
        results.add({
          'id': id,
          'status': complete ? 'pass' : 'partial',
          'evidence': evidence
        });
      } catch (error) {
        results.add({
          'id': id,
          'status': 'fail',
          'error': error is PlatformException
              ? error.code
              : error.toString().replaceAll(RegExp(r'https?://\S+'), '<url>')
        });
      }
      // ignore: avoid_print
      print('NB_DEVICE_CASE ${jsonEncode(results.last)}');
    }

    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Text('Regional offline device controls'))));
    await NextBillion.initNextBillionWithTileServer(
        MapsDemo.accessKey, WellKnownTileServer.nbTomtom);
    await RegionalOffline.configure();
    await check('CFG-009', () async {
      for (final value in [-1, 2147483648, 1.5, 'bad', true, false, null]) {
        await expectLater(
            channel.invokeMethod<dynamic>(
                'loadOfflineDetail', {'regionId': value}),
            throwsA(isA<PlatformException>()
                .having((e) => e.code, 'code', 'INVALID_ARGUMENT')));
      }
    },
        evidence:
            'Raw method channel rejects negative, overflow, fractional, string, boolean and null region IDs with INVALID_ARGUMENT without crash');
    await check('CFG-010', () async {
      await expectLater(
          channel.invokeMethod<dynamic>(
              'controlDownload', {'regionId': 1, 'action': 'invalid'}),
          throwsA(isA<PlatformException>()
              .having((e) => e.code, 'code', 'INVALID_ARGUMENT')));
    });
    await check('CFG-012', () async {
      await expectLater(channel.invokeMethod<dynamic>('missing-method'),
          throwsA(isA<MissingPluginException>()));
      await expectLater(channel.invokeMethod<dynamic>('beginDownloadPage'),
          throwsA(isA<PlatformException>()));
    },
        complete: false,
        evidence:
            'Unknown method and missing pageId return; no injected duplicate native completion');
    final initial = (await RegionalOffline.listInstalledRegions())
        .map((r) => r.regionId)
        .toSet();
    final catalog = await RegionalOffline.fetchRegionList();
    final choices = catalog
        .where((r) =>
            !initial.contains(r.regionId) &&
            r.totalSize > 80 * 1048576 &&
            r.totalSize < 120 * 1048576)
        .toList();
    expect(choices, isNotEmpty);
    final id = choices.first.regionId;
    binding.reportData!['testOwnedRegionId'] = id;
    binding.reportData!['preservedRegionIds'] = initial.toList();
    final page = await RegionalOffline.beginDownloadPage();
    final observed = <Map<String, Object?>>[];
    final subscription = RegionalOffline.downloadProgress.listen((values) {
      for (final p in values.where((p) => p.regionId == id)) {
        if (observed.isEmpty || observed.last['state'] != p.nativeState)
          observed.add({'state': p.nativeState, 'bytes': p.downloadedBytes});
      }
    });
    Future<RegionalOfflineDownloadProgress?> progress() async {
      for (final p in await RegionalOffline.getDownloadProgress()) {
        if (p.regionId == id) return p;
      }
      return null;
    }

    Future<RegionalOfflineDownloadProgress> waitState(
        Set<RegionalOfflineDownloadState> states) async {
      final deadline = DateTime.now().add(const Duration(seconds: 45));
      while (DateTime.now().isBefore(deadline)) {
        final p = await progress();
        if (p != null && states.contains(p.state)) return p;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      throw TimeoutException('Native task did not enter requested state');
    }

    try {
      await RegionalOffline.downloadRegion(id);
      await check('DL-005', () async {
        await waitState({RegionalOfflineDownloadState.downloadingPackage});
        await RegionalOffline.controlDownload(
            id, RegionalOfflineDownloadAction.pause);
        final paused =
            await waitState({RegionalOfflineDownloadState.pausedUser});
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(
            (await progress())?.state, RegionalOfflineDownloadState.pausedUser);
        binding.reportData!['pauseBytes'] = {
          'before': paused.downloadedBytes,
          'after': (await progress())?.downloadedBytes
        };
      },
          complete: false,
          evidence:
              'Real download paused for 2 seconds with native PAUSED_USER; independent network/file growth sampling remains');
      await check('DL-006', () async {
        await RegionalOffline.controlDownload(
            id, RegionalOfflineDownloadAction.resume);
        await waitState({
          RegionalOfflineDownloadState.downloadingPackage,
          RegionalOfflineDownloadState.completed
        });
      },
          complete: false,
          evidence:
              'Native resume reaches downloading/completed; task is then cancelled intentionally');
      await check('DL-008', () async {
        await RegionalOffline.controlDownload(
            id, RegionalOfflineDownloadAction.cancel);
        final until = DateTime.now().add(const Duration(seconds: 20));
        RegionalOfflineDownloadProgress? p;
        do {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          p = await progress();
          if (p == null || p.state == RegionalOfflineDownloadState.cancelled)
            break;
        } while (DateTime.now().isBefore(until));
        binding.reportData!['afterCancel'] = {
          'state': p?.nativeState,
          'bytes': p?.downloadedBytes
        };
        expect(p == null || p.state == RegionalOfflineDownloadState.cancelled,
            isTrue);
      },
          complete: false,
          evidence:
              'Native cancel converges to cancelled/absent task; partial-file cleanup not inspected');
      await check('DL-011', () async {
        await RegionalOffline.controlDownload(
            id, RegionalOfflineDownloadAction.delete);
        for (final action in RegionalOfflineDownloadAction.values) {
          await RegionalOffline.controlDownload(id, action);
        }
        expect(
            (await RegionalOffline.listInstalledRegions())
                .any((r) => r.regionId == id),
            isFalse);
        expect(
            (await RegionalOffline.listInstalledRegions())
                .map((r) => r.regionId)
                .toSet()
                .containsAll(initial),
            isTrue);
      },
          complete: false,
          evidence:
              'Paused/resumed/cancelled/missing task controls and delete do not crash; existing region IDs preserved');
    } finally {
      await RegionalOffline.controlDownload(
          id, RegionalOfflineDownloadAction.cancel);
      await RegionalOffline.controlDownload(
          id, RegionalOfflineDownloadAction.delete);
      await subscription.cancel();
      await RegionalOffline.endDownloadPage(page);
      binding.reportData!['observedTaskStates'] = observed;
    }
    binding.reportData!['completed'] = true;
    expect(results.where((r) => r['status'] == 'fail'), isEmpty,
        reason: 'See individual native result records');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
