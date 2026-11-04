import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/main.dart' show MapsDemo;

/// Credential-free loopback faults. No valid region/package is advertised or
/// installed, and no existing region is deleted. Run in a fresh process because
/// RegionalOffline.configure fixes the CDN for that runtime.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('offline metadata faults do not block map rendering',
      (tester) async {
    const style = '{"version":8,"sources":{},"layers":[{"id":"background",'
        '"type":"background","paint":{"background-color":"#556677"}}]}';
    final results = <Map<String, Object?>>[];
    final images = <String, String>{};
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'requiresCompletion': true,
      'completed': false,
      'results': results,
      'snapshots': images,
    };
    var mode = 'http-404';
    final requests = <String>[];
    final stalled = <HttpRequest>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(request.uri.path);
      request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      if (request.uri.path == '/valid-style.json') {
        request.response.write(style);
      } else if (mode == 'stall') {
        stalled.add(request);
        return;
      } else if (mode.startsWith('http-')) {
        request.response.statusCode = int.parse(mode.substring(5));
        request.response.write('deliberate fixture failure');
      } else if (mode == 'bad-gzip') {
        request.response.add([0x1f, 0x8b, 0xff, 0x00, 0x01]);
      } else if (mode == 'wrong-root') {
        request.response.write('null');
      } else {
        request.response.write('{deliberately invalid JSON');
      }
      await request.response.close();
    });
    NextbillionMapController? map;
    var styles = 0;
    var idles = 0;
    Future<void> waitFor(bool Function() ready) async {
      final deadline = DateTime.now().add(const Duration(seconds: 15));
      while (!ready() && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(ready(), isTrue, reason: 'Map did not remain responsive');
    }

    final base = 'http://127.0.0.1:${server.port}';
    final temporary = await Directory.systemTemp.createTemp('nbmaps_fault_');
    Future<String> localStyle(int generation, String content) async {
      final file = File('${temporary.path}/style-$generation.json');
      await file.writeAsString(content);
      return file.uri.toString();
    }

    try {
      await NextBillion.initNextBillionWithTileServer(
          MapsDemo.accessKey, WellKnownTileServer.nbTomtom);
      await tester.pumpWidget(MaterialApp(
          home: NBMap(
              initialCameraPosition:
                  const CameraPosition(target: LatLng(0, 0), zoom: 0),
              styleString: await localStyle(0, style),
              annotationOrder: const [],
              onMapCreated: (value) => map = value,
              onStyleLoadedCallback: () => styles++,
              onMapIdle: () => idles++)));
      await waitFor(() => map != null && styles > 0 && idles > 0);
      await RegionalOffline.configure(mapsBaseUrl: base);
      final installedBefore = (await RegionalOffline.listInstalledRegions())
          .map((r) => r.regionId)
          .toSet();
      for (final fault in [
        'http-401',
        'http-403',
        'http-404',
        'http-429',
        'http-500',
        'bad-gzip',
        'bad-json',
        'wrong-root',
      ]) {
        mode = fault;
        final before = styles;
        final idleBefore = idles;
        final stopwatch = Stopwatch()..start();
        final pending = RegionalOffline.fetchRegionList()
            .timeout(const Duration(seconds: 20))
            .then<Object>((value) => value, onError: (Object error) => error);
        await map!.setStyleString(await localStyle(
            before,
            style.replaceFirst(
                '#556677', before.isEven ? '#445566' : '#667788')));
        await waitFor(() => styles > before && idles > idleBefore);
        final outcome = await pending;
        final ok = outcome is PlatformException;
        results.add({
          'id': 'FAULT-CATALOG-$fault',
          'status': ok ? 'pass' : 'fail',
          'errorCode': outcome is PlatformException
              ? outcome.code
              : outcome.runtimeType.toString(),
          if (outcome is PlatformException)
            'message': (outcome.message ?? '')
                .replaceAll(MapsDemo.accessKey, '<key>')
                .replaceAll(RegExp(r'https?://\S+'), '<url>'),
          'elapsedMs': stopwatch.elapsedMilliseconds,
          // Fast failures may finish before idle; the explicit stall below
          // separately proves overlap with a genuinely pending request.
          'mapStyleAndIdleDuringFaultCase': true,
        });
        final snapshot = await map!
            .takeSnapshot(SnapshotOptions(
                width: 160,
                height: 120,
                writeToDisk: false,
                styleUri: '$base/valid-style.json'))
            .timeout(const Duration(seconds: 20));
        expect(snapshot, isNotNull);
      }
      final installedAfter = (await RegionalOffline.listInstalledRegions())
          .map((r) => r.regionId)
          .toSet();
      expect(installedAfter, installedBefore);
      mode = 'stall';
      var metadataFinished = false;
      final pendingMetadata = RegionalOffline.fetchRegionList()
          .timeout(const Duration(seconds: 30))
          .then<Object>((value) {
        metadataFinished = true;
        return value;
      }, onError: (Object error) {
        metadataFinished = true;
        return error;
      });
      await waitFor(() => stalled.isNotEmpty);
      final styleBeforeStall = styles;
      final idleBeforeStall = idles;
      await map!.setStyleString(await localStyle(styles, style));
      await waitFor(() => styles > styleBeforeStall && idles > idleBeforeStall);
      expect(metadataFinished, isFalse);
      for (final request in stalled) {
        request.response.statusCode = 503;
        await request.response.close();
      }
      expect(await pendingMetadata, isA<PlatformException>());
      results.add({
        'id': 'FAULT-METADATA-STALL',
        'status': 'pass',
        'evidence': 'Server accepted request but sent no headers; style reload '
            'and idle completed while fetch remained pending. Releasing with '
            '503 returned a native error without blocking the map.',
      });
      mode = 'http-404';
      final styleBeforeRecovery = styles;
      final idleBeforeRecovery = idles;
      await map!.moveCamera(
          CameraUpdate.newLatLngZoom(const LatLng(-33.8685, 151.2070), 14));
      await map!.setStyleType(NBMapStyleType.bright);
      await waitFor(
          () => styles > styleBeforeRecovery && idles > idleBeforeRecovery);
      await Future<void>.delayed(const Duration(seconds: 3));
      if (Platform.isIOS) {
        final bytes =
            await const MethodChannel('plugins.flutter.io/integration_test')
                .invokeMethod<List<dynamic>>('captureScreenshot',
                    {'name': 'provider-after-offline-faults'});
        if (bytes != null) {
          images['provider-after-offline-faults'] =
              base64Encode(bytes.cast<int>());
        }
      }
      // ignore: avoid_print
      print('NB_FAULT_PROVIDER_SCREENSHOT_READY');
      await Future<void>.delayed(const Duration(seconds: 5));
      results.add({
        'id': 'BOOT-004',
        'status': 'partial',
        'evidence': 'Local map reloaded during each failed metadata request; '
            'TomTom enum style and idle also recovered with the broken offline '
            'CDN still configured. Physical screenshot review required; '
            'package-install faults and request stalls are separate cases.',
      });
      expect(
          requests.any((path) => path.endsWith('/basic/regions.gz')), isTrue);
      binding.reportData!['installedIdsPreserved'] = installedAfter.toList();
      binding.reportData!['localRequestCount'] = requests.length;
      binding.reportData!['completed'] = true;
      for (final result in results) {
        // ignore: avoid_print
        print('NB_DEVICE_CASE ${jsonEncode(result)}');
      }
      expect(results.where((r) => r['status'] == 'fail'), isEmpty);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await server.close(force: true);
      await temporary.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}
