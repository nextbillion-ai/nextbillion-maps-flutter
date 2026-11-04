import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/map_style_switch.dart';

class _ViewPlatform extends MethodChannelNbMapsGl {
  @override
  Widget buildView(
          Map<String, dynamic> creationParams,
          OnPlatformViewCreatedCallback onPlatformViewCreated,
          Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers) =>
      const SizedBox();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = NbMapsGlPlatform.createInstance;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('example-enum-switch-test');
  late NextbillionMapController controller;
  late List<MethodCall> calls;
  late Future<Object?> Function(MethodCall) respond;
  setUp(() {
    NbMapsGlPlatform.createInstance = _ViewPlatform.new;
    calls = [];
    respond = (_) async => null;
    messenger.setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return respond(call);
    });
    controller = NextbillionMapController(
        nbMapsGlPlatform: MethodChannelNbMapsGl()
          ..setTestingMethodChanenl(channel),
        initialCameraPosition: const CameraPosition(target: LatLng(0, 0)),
        annotationOrder: const [],
        annotationConsumeTapEvents: const []);
  });
  tearDown(() {
    controller.dispose();
    NbMapsGlPlatform.createInstance = original;
    messenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> createMap(WidgetTester tester,
      [WellKnownTileServer server = WellKnownTileServer.nbTomtomOrbis]) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: MapStyleSwitch(initialTileServer: server))));
    tester.widget<NBMap>(find.byType(NBMap)).onMapCreated!(controller);
    await tester.pump();
  }

  Future<void> selectNight(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('map-style')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('night').last);
    await tester.pumpAndSettle();
  }

  for (final server in WellKnownTileServer.values) {
    testWidgets('${server.name} keeps its service fixed while switching styles',
        (tester) async {
      await createMap(tester, server);
      final initial = tester.element(find.byType(NBMap));
      expect(find.byType(DropdownButton<WellKnownTileServer>), findsNothing);
      expect(find.byKey(const ValueKey('fixed-tile-server')), findsOneWidget);
      await selectNight(tester);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'style#setStyleType');
      expect(calls.single.arguments, {'styleType': 'night'});
      expect(tester.element(find.byType(NBMap)), same(initial));
      expect(tester.widget<NBMap>(find.byType(NBMap)).styleType,
          NBMapStyleType.bright);
      await tester.tap(find.byTooltip('Reapply selection'));
      await tester.pumpAndSettle();
      expect(calls, hasLength(2));
      expect(calls.last.method, 'style#setStyleType');
      expect(calls.last.arguments, {'styleType': 'night'});
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('native style failure retains the previous selection',
      (tester) async {
    respond = (_) async => throw PlatformException(code: 'MAP_ERROR');
    await createMap(tester);
    await selectNight(tester);
    expect(
        tester
            .widget<DropdownButton<NBMapStyleType>>(
                find.byKey(const ValueKey('map-style')))
            .value,
        NBMapStyleType.bright);
    expect(find.text('Style failed: MAP_ERROR'), findsOneWidget);
    expect(calls, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('leaving with a pending style request ignores its late UI result',
      (tester) async {
    final pending = Completer<Object?>();
    respond = (_) => pending.future;
    await createMap(tester);
    await selectNight(tester);
    await tester.pumpWidget(const SizedBox());
    pending.complete(null);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('style controls wait for map creation', (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: MapStyleSwitch())));
    expect(
        tester
            .widget<DropdownButton<NBMapStyleType>>(
                find.byKey(const ValueKey('map-style')))
            .onChanged,
        isNull);
    expect(calls, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
