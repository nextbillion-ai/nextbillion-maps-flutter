import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/main.dart' show MapsDemo;
import 'package:nb_maps_flutter_example/offline_navigation.dart';

import 'support/network_probe.dart';

/// Exercise the published SPM artifact through Flutter's real snapshot bridge.
/// Requires installed Sydney data. Follow the physical-network wait markers and
/// acknowledge actual radio changes over the USB VM service. A confirmed offline
/// launch can also be selected with PHYSICAL_OFFLINE_CONFIRMED=true.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  var online = false;
  var offline = const bool.fromEnvironment('PHYSICAL_OFFLINE_CONFIRMED');
  var completed = false;
  var phase = 'starting';
  developer.registerExtension('ext.nbmapsTest.control', (_, args) async {
    if (args['action'] == 'online') online = true;
    if (args['action'] == 'offline') offline = true;
    return developer.ServiceExtensionResponse.result(jsonEncode({
      'ok': true,
      'phase': phase,
      'completed': completed,
    }));
  });
  testWidgets('iOS 2.3.3 physical offline snapshots and network recovery',
      (tester) async {
    expect(Platform.isIOS, isTrue);
    final results = <Map<String, Object?>>[];
    final images = <String, String>{};
    binding.reportData = {
      'sdk': {'ios': '2.3.3', 'android': '3.3.1'},
      'platform': Platform.operatingSystem,
      'requiresCompletion': true,
      'completed': false,
      'results': results,
      'snapshots': images,
    };
    final temporary = await Directory.systemTemp.createTemp('nbmaps-sdk233-');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var fixtureRequests = 0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(
          Rect.fromLTWH((i % 2) * 32, (i ~/ 2) * 32, 32, 32),
          Paint()
            ..color =
                [Colors.red, Colors.green, Colors.blue, Colors.yellow][i]);
    }
    final picture = recorder.endRecording();
    final fixtureImage = await picture.toImage(64, 64);
    final fixturePng =
        (await fixtureImage.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List();
    fixtureImage.dispose();
    picture.dispose();
    server.listen((request) async {
      fixtureRequests++;
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.headers.set('Cache-Control', 'max-age=3600');
      request.response.add(fixturePng);
      await request.response.close();
    });
    final key = GlobalKey<OfflineNavigationState>();
    Future<void> waitFor(bool Function() ready, {int seconds = 60}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (!ready() && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(ready(), isTrue, reason: 'Phase $phase timed out');
    }

    Future<void> check(
        String id, Future<Map<String, Object?>> Function() action,
        {bool observation = false}) async {
      phase = id;
      try {
        final data = await action().timeout(const Duration(seconds: 75));
        results.add({
          'id': id,
          'status': observation ? 'observation' : 'pass',
          ...data
        });
      } catch (error) {
        results.add({
          'id': id,
          'status': 'fail',
          'error': (error is PlatformException
                  ? '${error.code}: ${error.message}'
                  : error)
              .toString()
              .replaceAll(MapsDemo.accessKey, '<key>')
              .replaceAll(RegExp(r'https?://\S+'), '<url>'),
        });
      }
      // ignore: avoid_print
      print('NB_233_CASE ${jsonEncode(results.last)}');
    }

    Future<Map<String, Object?>> inspectImage(
        String name, Uint8List bytes) async {
      images[name] = base64Encode(bytes);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      final colors = <int>{};
      var opaque = 0;
      for (var y = image.height ~/ 8;
          y < image.height * 7 ~/ 8;
          y += math.max(1, image.height ~/ 32)) {
        for (var x = image.width ~/ 8;
            x < image.width * 7 ~/ 8;
            x += math.max(1, image.width ~/ 32)) {
          final p = (y * image.width + x) * 4;
          if (rgba[p + 3] != 0) opaque++;
          colors.add((rgba[p] ~/ 16) * 256 +
              (rgba[p + 1] ~/ 16) * 16 +
              rgba[p + 2] ~/ 16);
        }
      }
      final values = <String, Object?>{
        'decoded': true,
        'width': image.width,
        'height': image.height,
        'bytes': bytes.length,
        'centerColorBuckets': colors.length,
        'centerOpaqueSamples': opaque,
        'hasMapContent': colors.length > 8 && opaque > 0,
      };
      image.dispose();
      codec.dispose();
      return values;
    }

    Future<Map<String, Object?>> snapshot(String name,
        {bool disk = false,
        bool requireContent = true,
        int minColors = 9}) async {
      final value = await key.currentState!.map!
          .takeSnapshot(
              SnapshotOptions(width: 320, height: 240, writeToDisk: disk))
          .timeout(const Duration(seconds: 40));
      expect(value, isNotNull);
      final uri = Uri.tryParse(value!);
      final bytes = disk
          ? await (uri?.scheme == 'file' ? File.fromUri(uri!) : File(value))
              .readAsBytes()
          : base64Decode(value.contains(',') ? value.split(',').last : value);
      final evidence = await inspectImage(name, bytes);
      expect(evidence['width'], greaterThan(0));
      expect(evidence['height'], greaterThan(0));
      if (requireContent) {
        expect(evidence['centerColorBuckets'], greaterThanOrEqualTo(minColors));
        expect(evidence['centerOpaqueSamples'], greaterThan(0));
      }
      return {'returnType': disk ? 'disk' : 'base64', ...evidence};
    }

    Future<void> captureUi(String name) async {
      final bytes =
          await const MethodChannel('plugins.flutter.io/integration_test')
              .invokeMethod<List<dynamic>>('captureScreenshot', {'name': name});
      expect(bytes, isNotNull);
      images[name] = base64Encode(bytes!.cast<int>());
    }

    final probeUri = Uri.parse(
        'https://nb-oregon-cdn.nextbillion.io/navigation/us_telangana/maps/1/basic/regions/7242.gz');
    Future<Map<String, Object?>> verifyOnlineProvider() async {
      final state = key.currentState!;
      state.following = false;
      state.setPlaying(false);
      await RegionalOffline.refreshEngine();
      final before = state.styleLoads;
      await state.map!.setStyleType(NBMapStyleType.bright);
      await waitFor(() => state.styleLoads > before && state.routeReady);
      // Berlin is outside the installed Australia/US regions and the cameras
      // used by the earlier offline runs. Verify the native viewport explicitly.
      await state.map!.moveCamera(
          CameraUpdate.newLatLngZoom(const LatLng(52.5200, 13.4050), 14));
      final bounds = await state.map!.getVisibleRegion();
      expect(bounds, isNotNull);
      final longitude =
          (bounds!.southwest.longitude + bounds.northeast.longitude) / 2;
      expect(longitude, closeTo(13.4050, 0.1));
      // Let the visible map settle before starting a separate renderer. Save
      // the UI even if the server rejects the later snapshot request.
      final settleUntil = DateTime.now().add(const Duration(seconds: 12));
      while (DateTime.now().isBefore(settleUntil)) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await captureUi('233-online-provider-ui');
      final evidence = await snapshot('233-online-provider');
      return {
        ...evidence,
        'centerLongitude': longitude,
        // This CDN serves regional metadata, not the online map tiles. A
        // timeout here must not hide a successful online map/snapshot result.
        'regionalMetadataCdnReachable': await canReachHttpServer(probeUri),
      };
    }

    try {
      await NextBillion.initNextBillionWithTileServer(
          MapsDemo.accessKey, WellKnownTileServer.nbTomtom);
      await RegionalOffline.configure();
      final original = await RegionalOffline.listInstalledRegions();
      expect(original.any((r) => r.regionId == 7242 && r.allTarsOk), isTrue);
      binding.reportData!['preservedRegionIds'] =
          original.map((r) => r.regionId).toList();
      await tester.pumpWidget(MaterialApp(
          home: OfflineNavigationView(
              key: key, initialTrack: PlaybackTrack.presets[2])));
      await waitFor(() =>
          key.currentState?.configured == true &&
          key.currentState?.routeReady == true);
      if (const bool.fromEnvironment('ONLINE_PROVIDER_ONLY')) {
        await check('233-ONLINE-PROVIDER', verifyOnlineProvider);
        binding.reportData!['completed'] = true;
        completed = true;
        phase = 'completed';
        return;
      }
      if (!offline) {
        await check('233-ONLINE-BEFORE', () async {
          await captureUi('233-online-before-ui');
          return snapshot('233-online-before');
        });
        phase = 'waiting-offline';
        // ignore: avoid_print
        print('NB_233_WAIT_OFFLINE');
        await waitFor(() => offline, seconds: 1800);
      }
      await check('233-PHYSICAL-OFFLINE', () async {
        var failed = 0;
        for (var i = 0; i < 3; i++) {
          if (!await canReachHttpServer(probeUri)) failed++;
        }
        expect(failed, 3);
        return {'userConfirmedRadiosOff': true, 'failedHttpProbes': failed};
      });
      key.currentState!.remountMap();
      await tester.pump();
      await waitFor(() =>
          key.currentState?.configured == true &&
          key.currentState?.routeReady == true);
      await check('233-OFFLINE-BASE64', () async {
        await captureUi('233-offline-map-ui');
        return snapshot('233-offline-base64');
      });
      await check(
          '233-OFFLINE-DISK', () => snapshot('233-offline-disk', disk: true));
      await check('233-OFFLINE-CONCURRENT', () async {
        final both = await Future.wait([
          snapshot('233-offline-concurrent-base64'),
          snapshot('233-offline-concurrent-disk', disk: true),
        ]);
        return {'snapshots': both};
      });
      await check('233-OFFLINE-REMOUNT', () async {
        key.currentState!.remountMap();
        await tester.pump();
        await waitFor(() => key.currentState!.routeReady);
        return snapshot('233-offline-fresh-map');
      });
      await check('233-OFFLINE-NIGHT', () async {
        final state = key.currentState!;
        final loads = state.styleLoads;
        await state.map!.setStyleType(NBMapStyleType.night);
        await waitFor(() => state.styleLoads > loads && state.routeReady);
        await captureUi('233-offline-night-ui');
        return snapshot('233-offline-night');
      });
      final style = File('${temporary.path}/sparse.json');
      await style.writeAsString(jsonEncode({
        'version': 8,
        'sources': {
          'probe': {
            'type': 'raster',
            'tileSize': 256,
            'minzoom': 7,
            'maxzoom': 7,
            'tiles': [
              'http://127.0.0.1:${server.port}/uncached/{z}/{x}/{y}.png'
            ]
          }
        },
        'layers': [
          {
            'id': 'probe',
            'type': 'raster',
            'source': 'probe',
            'paint': {'raster-fade-duration': 0}
          }
        ],
      }));
      final state = key.currentState!;
      // Route installation calls seek(), which otherwise follows Sydney and
      // overwrites the camera chosen for this deliberately uncovered fixture.
      state.following = false;
      state.setPlaying(false);
      final beforeSparse = state.styleLoads;
      await tester.pumpWidget(MaterialApp(
          home: OfflineNavigationView(
              key: key,
              initialTrack: PlaybackTrack.presets[2],
              styleString: style.uri.toString())));
      await waitFor(() => state.styleLoads > beforeSparse && state.routeReady);
      await state.map!
          .moveCamera(CameraUpdate.newLatLngZoom(const LatLng(-10, -100), 7));
      final bounds = await state.map!.getVisibleRegion();
      expect(bounds, isNotNull);
      final centerLongitude =
          (bounds!.southwest.longitude + bounds.northeast.longitude) / 2;
      final longitudeSpan =
          bounds.northeast.longitude - bounds.southwest.longitude;
      expect(centerLongitude, closeTo(-100, 0.1));
      expect(longitudeSpan, inInclusiveRange(1, 10));
      binding.reportData!['uncoveredFixtureViewport'] = {
        'centerLongitude': centerLongitude,
        'longitudeSpan': longitudeSpan,
        'routeFollowingDisabled': !state.following,
      };
      await check('233-OFFLINE-MISSING-COVERAGE', () async {
        final evidence =
            await snapshot('233-offline-missing', requireContent: false);
        expect(fixtureRequests, 0);
        await captureUi('233-offline-missing-ui');
        return {
          ...evidence,
          'fixtureNetworkRequests': fixtureRequests,
          'scope':
              'Observe missing-coverage behavior separately from supported offline map content.'
        };
      }, observation: true);
      phase = 'waiting-online';
      final sparseController = state.map;
      // ignore: avoid_print
      print('NB_233_WAIT_ONLINE');
      await waitFor(() => online, seconds: 1800);
      await check('233-ONLINE-AUTOMATIC-RECOVERY', () async {
        // Preserve the same MapView and style; do not call refresh/reload first.
        await waitFor(() => fixtureRequests > 0, seconds: 30);
        final evidence = await snapshot('233-online-recovered', minColors: 4);
        await captureUi('233-online-recovered-ui');
        return {
          ...evidence,
          'fixtureNetworkRequests': fixtureRequests,
          'sameController': identical(sparseController, key.currentState!.map)
        };
      });
      await check('233-ONLINE-PROVIDER', verifyOnlineProvider);
      final after = await RegionalOffline.listInstalledRegions();
      expect(
          after
              .map((r) => r.regionId)
              .toSet()
              .containsAll(original.map((r) => r.regionId)),
          isTrue);
      binding.reportData!['completed'] = true;
      completed = true;
      phase = 'completed';
    } finally {
      await tester.pumpWidget(const SizedBox());
      await server.close(force: true);
      await temporary.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 40)));
}
