import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('enum-server-switch-test');
  const initChannel = MethodChannel('fixed-provider-init-test');
  final originalInitChannel = NextBillion().channel;
  late List<MethodCall> initCalls;
  late MethodChannelNbMapsGl platform;
  late NextbillionMapController controller;
  late List<MethodCall> calls;
  late Future<Object?> Function(MethodCall) respond;
  setUp(() {
    calls = [];
    initCalls = [];
    NextBillion.setMockMethodChannel(initChannel);
    messenger.setMockMethodCallHandler(initChannel, (call) async {
      initCalls.add(call);
      return null;
    });
    respond = (_) async => true;
    messenger.setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return respond(call);
    });
    platform = MethodChannelNbMapsGl()..setTestingMethodChanenl(channel);
    controller = NextbillionMapController(
        nbMapsGlPlatform: platform,
        initialCameraPosition: const CameraPosition(target: LatLng(0, 0)),
        annotationOrder: const [],
        annotationConsumeTapEvents: const []);
  });
  tearDown(() {
    controller.dispose();
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(initChannel, null);
    NextBillion.setMockMethodChannel(originalInitChannel);
  });

  // Compatibility bridge transport checks only. These do not validate or
  // promise same-MapView provider switching, which is outside release scope.
  for (final entry in {
    WellKnownTileServer.nbTomtom: 'NGLTomTom',
    WellKnownTileServer.nbMapTiler: 'NGLMapTiler',
    WellKnownTileServer.nbTomtomOrbis: 'NGLTomTomOrbis',
  }.entries) {
    for (final style in NBMapStyleType.values) {
      test('legacy bridge payload ${entry.key.name}/${style.name}', () async {
        expect(await controller.switchTileServer(entry.key, styleType: style),
            isTrue);
        expect(calls, hasLength(1));
        expect(calls.single.method, 'map#switchTileServer');
        expect(calls.single.arguments,
            {'server': entry.value, 'styleType': style.name});
      });
    }
  }

  for (final server in WellKnownTileServer.values) {
    for (final style in NBMapStyleType.values) {
      test('fixed ${server.name}: initialize before applying ${style.name}',
          () async {
        await NextBillion.initNextBillionWithTileServer(
            'unit-test-key', server);
        await controller.setStyleType(style);
        expect(initCalls, hasLength(1));
        expect(initCalls.single.method,
            'nextbillion/init_nextbillion_tile_server');
        expect(initCalls.single.arguments,
            {'accessKey': 'unit-test-key', 'server': server.value});
        expect(calls, hasLength(1));
        expect(calls.single.method, 'style#setStyleType');
        expect(calls.single.arguments, {'styleType': style.value});
      });
    }
  }

  test('default is bright and acceptance does not synthesize a style callback',
      () async {
    var styleLoads = 0;
    platform.onMapStyleLoadedPlatform.add((_) => styleLoads++);
    expect(await controller.switchTileServer(WellKnownTileServer.nbMapTiler),
        isTrue);
    expect((calls.single.arguments as Map)['styleType'], 'bright');
    expect(styleLoads, 0);
    await platform.handleMethodCall(const MethodCall('map#onStyleLoaded', {}));
    expect(styleLoads, 1);
  });

  test('native rejection is propagated without a fallback URL request',
      () async {
    respond = (_) async => throw PlatformException(code: 'SDK_UPDATE_REQUIRED');
    await expectLater(
        controller.switchTileServer(WellKnownTileServer.nbTomtomOrbis),
        throwsA(isA<PlatformException>()
            .having((error) => error.code, 'code', 'SDK_UPDATE_REQUIRED')));
    expect(calls, hasLength(1));
    expect(calls.single.method, 'map#switchTileServer');
  });

  test('false or null native responses are not reported as accepted', () async {
    respond = (_) async => false;
    expect(await controller.switchTileServer(WellKnownTileServer.nbTomtom),
        isFalse);
    respond = (_) async => null;
    expect(await controller.switchTileServer(WellKnownTileServer.nbTomtom),
        isFalse);
  });

  test('disposed controller cannot change the global server', () async {
    controller.dispose();
    calls.clear();
    expect(await controller.switchTileServer(WellKnownTileServer.nbMapTiler),
        isFalse);
    expect(calls, isEmpty);
  });
}
