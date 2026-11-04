import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

class _PendingMapPlatform extends MethodChannelNbMapsGl {
  final ready = Completer<void>();
  late OnPlatformViewCreatedCallback created;
  int disposals = 0;

  @override
  Widget buildView(
      Map<String, dynamic> creationParams,
      OnPlatformViewCreatedCallback onPlatformViewCreated,
      Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers) {
    created = onPlatformViewCreated;
    return const SizedBox();
  }

  @override
  Future<void> initPlatform(int id) => ready.future;

  @override
  void dispose() {
    disposals++;
    super.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const camera = CameraPosition(target: LatLng(0, 0));

  test('native string and numeric drag events reach controller callbacks',
      () async {
    final platform = MethodChannelNbMapsGl();
    final controller = NextbillionMapController(
      nbMapsGlPlatform: platform,
      initialCameraPosition: camera,
      annotationOrder: const [],
      annotationConsumeTapEvents: const [],
    );
    final received = <DragEventType>[];
    controller.onFeatureDrag.add((id,
            {required point,
            required origin,
            required current,
            required delta,
            required eventType}) =>
        received.add(eventType));
    for (final type in ['start', 'drag', 'end', 0, 1, 2, 'unknown', 99]) {
      await platform.handleMethodCall(
          MethodCall('feature#onDrag', {'id': 'route', 'eventType': type}));
    }
    expect(received, [...DragEventType.values, ...DragEventType.values]);
    controller.dispose();
    controller.dispose();
  });

  testWidgets(
      'removing map while initialization waits releases controller once',
      (tester) async {
    final original = NbMapsGlPlatform.createInstance;
    final platform = _PendingMapPlatform();
    NbMapsGlPlatform.createInstance = () => platform;
    addTearDown(() => NbMapsGlPlatform.createInstance = original);
    var callbacks = 0;
    await tester.pumpWidget(MaterialApp(
        home: NBMap(
            initialCameraPosition: camera,
            onMapCreated: (_) => callbacks++,
            onStyleLoadedCallback: () => callbacks++)));
    platform.created(42);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(platform.disposals, 1);
    platform.ready.complete();
    await tester.pump();
    expect(callbacks, 0);
    expect(platform.disposals, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'failed map initialization releases controller without creation callback',
      (tester) async {
    final original = NbMapsGlPlatform.createInstance;
    final platform = _PendingMapPlatform();
    NbMapsGlPlatform.createInstance = () => platform;
    addTearDown(() => NbMapsGlPlatform.createInstance = original);
    var callbacks = 0;
    await tester.pumpWidget(MaterialApp(
        home: NBMap(
            initialCameraPosition: camera, onMapCreated: (_) => callbacks++)));
    platform.created(42);
    platform.ready.completeError(PlatformException(code: 'MAP_DISPOSED'));
    await tester.pump();
    expect(callbacks, 0);
    expect(platform.disposals, 1);
    await tester.pumpWidget(const SizedBox());
    expect(platform.disposals, 1);
    expect(tester.takeException(), isNull);
  });

  group('legacy offline observer lifetime', () {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const global = MethodChannel('legacy-review');
    late String channelName;
    late Map args;
    late List<String> commands;
    final definition = OfflineRegionDefinition(
        bounds: LatLngBounds(
            southwest: const LatLng(0, 0), northeast: const LatLng(1, 1)),
        mapStyleUrl: 'https://example.com/style.json',
        minZoom: 0,
        maxZoom: 1);
    setUp(() {
      setTestingGlobalChannel(global);
      commands = [];
      messenger.setMockMethodCallHandler(global, (call) async {
        args = call.arguments as Map;
        channelName = args['channelName'] as String;
        messenger.setMockMethodCallHandler(MethodChannel(channelName),
            (call) async {
          commands.add(call.method);
          return null;
        });
        return jsonEncode(
            {'id': 1, 'definition': definition.toMap(), 'metadata': {}});
      });
    });
    tearDown(() {
      messenger.setMockMethodCallHandler(global, null);
      messenger.setMockMethodCallHandler(MethodChannel(channelName), null);
      setTestingGlobalChannel(
          const MethodChannel('plugins.flutter.io/nb_maps_flutter'));
    });
    Future<void> send(Object value) async {
      await messenger.handlePlatformMessage(channelName,
          const StandardMethodCodec().encodeSuccessEnvelope(value), (_) {});
      await Future<void>.delayed(Duration.zero);
    }

    test('download without progress requests no native observer channel',
        () async {
      await downloadOfflineRegion(definition);
      expect(args['observe'], false);
      expect(commands, isEmpty);
    });
    test('malformed progress produces one error and cancels listener',
        () async {
      final events = <DownloadRegionStatus>[];
      await downloadOfflineRegion(definition, onEvent: events.add);
      await send('invalid JSON');
      expect(args['observe'], true);
      expect(events.single, isA<Error>());
      expect(commands, ['listen', 'cancel']);
    });
    test('terminal success cancels listener and drops later progress',
        () async {
      final events = <DownloadRegionStatus>[];
      await downloadOfflineRegion(definition, onEvent: events.add);
      await send('{"status":"success"}');
      expect(events.single, isA<Success>());
      expect(commands, ['listen', 'cancel']);
    });
  });
}
