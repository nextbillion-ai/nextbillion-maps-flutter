import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/main.dart' show MapsDemo;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Orbis guards preserve the active Android offline runtime',
      (tester) async {
    final results = <Map<String, Object?>>[];
    binding.reportData = {
      'platform': Platform.operatingSystem,
      'requiresCompletion': true,
      'completed': false,
      'results': results,
    };

    Future<void> expectGuard(String id, Future<dynamic> operation) async {
      await expectLater(
          operation,
          throwsA(isA<PlatformException>()
              .having((error) => error.code, 'code', 'SDK_UPDATE_REQUIRED')));
      expect(await RegionalOffline.supportStatus(),
          RegionalOfflineSupportStatus.supported);
      results.add({'id': id, 'status': 'pass'});
      // ignore: avoid_print
      print('NB_DEVICE_CASE ${jsonEncode(results.last)}');
    }

    await NextBillion.initNextBillionWithTileServer(
        MapsDemo.accessKey, WellKnownTileServer.nbTomtom);
    final configuring = RegionalOffline.configure();
    await expectGuard(
        'ORBIS-PENDING-CONFIGURATION',
        NextBillion.switchWellKnownTileServer(
            WellKnownTileServer.nbTomtomOrbis));
    await configuring;

    await expectGuard(
        'ORBIS-GLOBAL-SWITCH',
        NextBillion.switchWellKnownTileServer(
            WellKnownTileServer.nbTomtomOrbis));
    await expectGuard(
        'ORBIS-REINITIALIZATION',
        NextBillion.initNextBillionWithTileServer(
            MapsDemo.accessKey, WellKnownTileServer.nbTomtomOrbis));

    NextbillionMapController? map;
    var styleLoaded = false;
    try {
      await tester.pumpWidget(MaterialApp(
          home: NBMap(
              initialCameraPosition:
                  const CameraPosition(target: LatLng(0, 0), zoom: 0),
              styleString: '{"version":8,"sources":{},"layers":'
                  '[{"id":"background","type":"background","paint":'
                  '{"background-color":"#556677"}}]}',
              onMapCreated: (controller) => map = controller,
              onStyleLoadedCallback: () => styleLoaded = true)));
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (
          (map == null || !styleLoaded) && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(map, isNotNull);
      expect(styleLoaded, isTrue);
      await expectGuard('ORBIS-CONTROLLER-SWITCH',
          map!.switchTileServer(WellKnownTileServer.nbTomtomOrbis));
      await Future<void>.delayed(const Duration(seconds: 1));
      expect(await RegionalOffline.supportStatus(),
          RegionalOfflineSupportStatus.supported);
      binding.reportData!['completed'] = true;
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  }, skip: !Platform.isAndroid, timeout: const Timeout(Duration(minutes: 3)));
}
