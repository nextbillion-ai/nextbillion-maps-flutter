import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/main.dart' show MapsDemo;
import 'package:nb_maps_flutter_example/offline_navigation.dart';

/// API integration coverage with local, credential-free fixtures. The SQLite
/// fixtures derive from the SDK's v5 test database plus its v6 schema DDL and
/// contain one metadata-only region, no tiles. Merge accepts v6, rejects v5;
/// the fixtures do not establish offline map coverage.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('upgrade native APIs, legacy merge and cancellation',
      (tester) async {
    const fixtureOwner = 'nbmaps-upgrade-fixture-20261103';
    final results = <Map<String, Object?>>[];
    final images = <String, String>{};
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'requiresCompletion': true,
      'completed': false,
      'results': results,
      'snapshots': images,
    };
    Future<void> check(List<String> ids, Future<void> Function() action,
        {String? evidence, bool complete = false}) async {
      try {
        await action().timeout(const Duration(seconds: 60));
        for (final id in ids) {
          results.add({
            'id': id,
            'status': complete ? 'pass' : 'partial',
            'evidence': evidence ??
                'Real SDK API assertions; full scenario coverage reviewed separately'
          });
        }
      } catch (error) {
        for (final id in ids) {
          results.add({
            'id': id,
            'status': 'fail',
            'error': (error is PlatformException
                    ? '${error.code}: ${error.message ?? ''}'
                    : error)
                .toString()
                .replaceAll(MapsDemo.accessKey, '<key>')
                .replaceAll(RegExp(r'https?://\S+'), '<url>')
          });
        }
      }
      // ignore: avoid_print
      print('NB_DEVICE_CASE ${jsonEncode(results.last)}');
    }

    Future<void> waitFor(bool Function() ready) async {
      final deadline = DateTime.now().add(const Duration(seconds: 45));
      while (!ready() && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(ready(), isTrue);
    }

    Future<void> reject(Future<dynamic> operation, [String? code]) =>
        expectLater(
            operation,
            throwsA(isA<PlatformException>().having((e) => e.code, 'code',
                code == null ? isNotEmpty : equals(code))));
    final temporary =
        await Directory.systemTemp.createTemp('nbmaps_upgrade_test_');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final slowRequests = <HttpRequest>[];
    const localStyle =
        '{"version":8,"sources":{},"layers":[{"id":"background","type":"background","paint":{"background-color":"#556677"}}]}';
    server.listen((request) async {
      if (request.uri.path.contains('slow')) {
        slowRequests.add(request);
        return;
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(localStyle);
      await request.response.close();
    });
    final localUrl = 'http://127.0.0.1:${server.port}/style.json';
    final ownedLegacyIds = <int>{};
    try {
      await NextBillion.initNextBillionWithTileServer(
          MapsDemo.accessKey, WellKnownTileServer.nbTomtom);
      await RegionalOffline.configure();
      await Future<void>.delayed(const Duration(seconds: 1));
      final originalLegacy = await getListOfRegions();
      final originalRegional = await RegionalOffline.listInstalledRegions();
      binding.reportData!['preservedLegacyIds'] =
          originalLegacy.map((r) => r.id).toList();
      binding.reportData!['preservedRegionalIds'] =
          originalRegional.map((r) => r.regionId).toList();
      final asset =
          'integration_test/fixtures/offline-import-${Platform.isIOS ? 'ios' : 'android'}.db';
      final bytes = (await rootBundle.load(asset)).buffer.asUint8List();
      final input = File('${temporary.path}/input.db');
      await input.writeAsBytes(bytes);
      await check(['LEG-015', 'LEG-017', 'LEG-021', 'LEG-022'], () async {
        await installOfflineMapTiles(asset);
        await installOfflineMapTiles(input.path);
        expect(listEquals(await input.readAsBytes(), bytes), isTrue);
        final listed = await getListOfRegions();
        final imported = listed
            .where((r) => r.metadata['testOwner'] == fixtureOwner)
            .toList();
        expect(imported, isNotEmpty);
        ownedLegacyIds.addAll(imported.map((r) => r.id));
        expect(
            listed
                .map((r) => r.id)
                .toSet()
                .containsAll(originalLegacy.map((r) => r.id)),
            isTrue);
        expect(
            (await RegionalOffline.listInstalledRegions())
                .map((r) => r.regionId)
                .toSet()
                .containsAll(originalRegional.map((r) => r.regionId)),
            isTrue);
      },
          evidence:
              'SDK v6 fixture merged from read-only bundled asset and absolute-path writable copy; one Flutter-metadata pack listed; input bytes and pre-existing legacy/regional IDs preserved; repeated serial merge. No offline tile coverage in fixture.');
      await check(['LEG-012', 'LEG-016', 'LEG-020'], () async {
        await reject(installOfflineMapTiles('${temporary.path}/missing.db'));
        final invalid = File('${temporary.path}/invalid.db');
        await invalid.writeAsString('not an SQLite database');
        await reject(installOfflineMapTiles(invalid.path));
        expect(await invalid.readAsString(), 'not an SQLite database');
        await reject(installOfflineMapTiles(
            'integration_test/fixtures/offline-import-v5.db'));
        final futureSchema = File('${temporary.path}/future-schema.db');
        final futureBytes = List<int>.of(bytes);
        // SQLite header user_version, big endian; unsupported schema 999.
        futureBytes.setRange(60, 64, [0, 0, 3, 231]);
        await futureSchema.writeAsBytes(futureBytes);
        await reject(installOfflineMapTiles(futureSchema.path));
        expect(
            listEquals(await futureSchema.readAsBytes(), futureBytes), isTrue);
        expect(
            (await getListOfRegions())
                .map((r) => r.id)
                .toSet()
                .containsAll(ownedLegacyIds),
            isTrue);
        expect(
            await Directory.systemTemp
                .list()
                .where(
                    (f) => f.path.split('/').last.startsWith('nbmap_import_'))
                .toList(),
            isEmpty);
      },
          evidence:
              'Missing source, non-SQLite, SDK v5 and future schema 999 return errors; original source and imported packs remain; no bridge import directories left. Disk exhaustion and MBTiles remain separate.');
      if (Platform.isIOS) {
        await check(['LEG-014'], () async {
          for (final operation in [
            () => setOffline(true),
            () => mergeOfflineRegions(input.path),
            () => updateOfflineRegionMetadata(350000003, const {})
          ]) {
            await expectLater(
                operation(), throwsA(isA<MissingPluginException>()));
          }
        }, complete: true);
      }
      final downloadEvents = <DownloadRegionStatus>[];
      final terminal = Completer<void>();
      Object? downloadError;
      await check(['LEG-001', 'LEG-003'], () async {
        final region = await downloadOfflineRegion(
            OfflineRegionDefinition(
                bounds: LatLngBounds(
                    southwest: const LatLng(-33.92, 151.20),
                    northeast: const LatLng(-33.91, 151.21)),
                mapStyleUrl: localUrl,
                minZoom: 0,
                maxZoom: 0),
            metadata: const {'testOwner': 'nbmaps-legacy-download-20261103'},
            onEvent: (event) {
          downloadEvents.add(event);
          if (event is Success && !terminal.isCompleted) terminal.complete();
          if (event is! Success &&
              event is! InProgress &&
              !terminal.isCompleted) {
            downloadError = event;
            terminal.complete();
          }
        });
        ownedLegacyIds.add(region.id);
        await terminal.future;
        expect(downloadError, isNull);
        expect(downloadEvents.whereType<Success>(), hasLength(1));
        expect(downloadEvents.whereType<InProgress>(), isNotEmpty);
        expect(
            (await getListOfRegions()).any((r) => r.id == region.id), isTrue);
      },
          evidence:
              'Local HTTP background-only style creates and completes a real legacy pack; buffered start/progress and exactly one success received; pack listed. No injected duplicate notifications.');
      await check(['LEG-002'], () async {
        final region = await downloadOfflineRegion(
            OfflineRegionDefinition(
                bounds: LatLngBounds(
                    southwest: const LatLng(-33.92, 151.20),
                    northeast: const LatLng(-33.91, 151.21)),
                mapStyleUrl: localUrl,
                minZoom: 0,
                maxZoom: 0),
            metadata: const {'testOwner': 'nbmaps-no-observer-20261103'});
        ownedLegacyIds.add(region.id);
        expect(
            (await getListOfRegions()).any((r) => r.id == region.id), isTrue);
      },
          evidence:
              'No onEvent: real pack creation future completes and pack is listed; native completion status not exposed by legacy list API.');
      final key = GlobalKey<OfflineNavigationState>();
      await tester.pumpWidget(MaterialApp(
          home: OfflineNavigationView(
              key: key,
              autoInitialize: false,
              initialTrack: PlaybackTrack.presets[2])));
      await waitFor(() => key.currentState?.routeReady == true);
      final map = key.currentState!.map!;
      await check(['TRIM-007'], () async {
        await reject(
            map.setLineLayerProperties(
                'missing-layer', const LineLayerProperties(lineWidth: 2)),
            'INVALID_LAYER');
        await reject(
            map.setLineLayerProperties('circle-nbmap-annotation-0',
                const LineLayerProperties(lineWidth: 2)),
            'INVALID_LAYER');
      }, complete: true);
      await check(['DATA-012'], () async {
        final installed = await RegionalOffline.listInstalledRegions();
        final id = installed.firstWhere((r) => r.allTarsOk).regionId;
        expect(await map.focusPreviewRegion(id), isTrue);
        await reject(map.focusPreviewRegion(-1), 'INVALID_ARGUMENT');
        final snapshot = await RegionalOffline.queryRegions();
        expect(snapshot.installed.any((r) => r.regionId == id), isTrue);
        expect(await RegionalOffline.downloadProgress.first,
            isA<List<RegionalOfflineDownloadProgress>>());
        expect(await RegionalOffline.previewBundleImportStatus.first,
            isA<RegionalOfflinePreviewBundleImportStatus>());
      },
          evidence:
              'Installed-region focus, negative ID rejection, native catalog snapshot and first values of both event streams.');
      await check([
        'SNAP-001',
        if (Platform.isIOS) 'SNAP-003' else 'SNAP-002',
        if (Platform.isAndroid) 'SNAP-010'
      ], () async {
        final snapshots = await Future.wait([
          map.takeSnapshot(SnapshotOptions(
              width: 160,
              height: 120,
              styleUri: localUrl,
              writeToDisk: false,
              centerCoordinate: const LatLng(-33.91, 151.20),
              zoomLevel: 12)),
          map.takeSnapshot(SnapshotOptions(
              width: 160,
              height: 120,
              styleUri: localUrl,
              writeToDisk: true,
              bounds: LatLngBounds(
                  southwest: const LatLng(-33.92, 151.20),
                  northeast: const LatLng(-33.91, 151.21))))
        ]);
        expect(snapshots.every((s) => s != null), isTrue);
        final encoded = snapshots[0]!.split(',').last;
        expect(base64Decode(encoded).length, greaterThan(100));
        images['concurrent-base64'] = encoded;
        final path = snapshots[1]!;
        final file = path.startsWith('file:')
            ? File.fromUri(Uri.parse(path))
            : File(path);
        final fileBytes = await file.readAsBytes();
        expect(fileBytes.length, greaterThan(100));
        images['concurrent-disk'] = base64Encode(fileBytes);
        await file.delete();
      },
          evidence:
              'Two concurrent real native snapshots of local background-only style; center+zoom/base64 and bounds/disk modes; both encoded images saved. Native FileSource counters not instrumented.');
      await check(['SNAP-008', 'TRIM-008'], () async {
        final pending = map
            .takeSnapshot(SnapshotOptions(
                width: 160,
                height: 120,
                styleUri: 'http://127.0.0.1:${server.port}/slow.json',
                writeToDisk: false))
            .then<Object?>((value) => value, onError: (Object error) => error);
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        final outcome = await pending.timeout(const Duration(seconds: 10));
        expect(
            outcome,
            isA<PlatformException>()
                .having((e) => e.code, 'code', 'MAP_DISPOSED'));
        expect(map.disposed, isTrue);
        await map.setLineLayerProperties(
            'unused', const LineLayerProperties(lineWidth: 2));
        expect(await map.focusPreviewRegion(7242), isFalse);
      },
          evidence:
              'Snapshot waiting for local server headers cancelled by native view disposal; MAP_DISPOSED returned; later controller operations obey disposed contract.');
    } finally {
      await tester.pumpWidget(const SizedBox());
      for (final id in ownedLegacyIds) {
        try {
          await deleteOfflineRegion(id);
        } on PlatformException catch (error) {
          results.add({
            'id': 'LEG-011',
            'status': 'fail',
            'error': 'Test-owned pack cleanup: ${error.code}'
          });
        }
      }
      await server.close(force: true);
      for (final request in slowRequests) {
        try {
          await request.response.close().timeout(const Duration(seconds: 2));
        } on Exception {/* Cancelled request. */}
      }
      await temporary.delete(recursive: true);
    }
    binding.reportData!['completed'] = true;
    expect(results.where((r) => r['status'] == 'fail'), isEmpty,
        reason: 'See per-case results for native API failures');
  }, timeout: const Timeout(Duration(minutes: 12)));
}
