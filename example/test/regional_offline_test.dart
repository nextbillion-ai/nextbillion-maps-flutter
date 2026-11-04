import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/regional_offline.dart';

class _MapPlatform extends MethodChannelNbMapsGl {
  late OnPlatformViewCreatedCallback created;
  var initializations = 0;

  @override
  Widget buildView(
      Map<String, dynamic> creationParams,
      OnPlatformViewCreatedCallback onPlatformViewCreated,
      Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers) {
    created = onPlatformViewCreated;
    return const SizedBox();
  }

  @override
  Future<void> initPlatform(int id) async {
    initializations++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods =
      MethodChannel('plugins.flutter.io/nb_maps_flutter/regional_offline');
  const events = MethodChannel(
      'plugins.flutter.io/nb_maps_flutter/regional_offline/events');
  const mapMethods = MethodChannel('nonblocking-offline-example-map');
  final original = NbMapsGlPlatform.createInstance;
  late _MapPlatform platform;
  late List<MethodCall> calls;
  late Future<dynamic> Function(MethodCall) respond;

  setUp(() {
    calls = [];
    platform = _MapPlatform()..setTestingMethodChanenl(mapMethods);
    NbMapsGlPlatform.createInstance = () => platform;
    respond = (call) async => switch (call.method) {
          'getDownloadProgress' ||
          'listInstalledRegions' ||
          'fetchRegionList' =>
            <dynamic>[],
          'getPreviewBundleImportStatus' => <String, dynamic>{
              'previewBundleReady': false,
              'ensuring': true,
              'waitingForNetwork': true,
              'recoverable': true,
            },
          _ => null,
        };
    messenger.setMockMethodCallHandler(methods, (call) {
      calls.add(call);
      return respond(call);
    });
    messenger.setMockMethodCallHandler(events, (_) async => null);
    messenger.setMockMethodCallHandler(mapMethods, (_) async => null);
  });

  tearDown(() {
    NbMapsGlPlatform.createInstance = original;
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockMethodCallHandler(events, null);
    messenger.setMockMethodCallHandler(mapMethods, null);
  });

  Future<void> createAndLoadMap(WidgetTester tester) async {
    var styleCallbacks = 0;
    platform.onMapStyleLoadedPlatform.add((_) => styleCallbacks++);
    platform.created(1);
    await tester.pump();
    await platform.handleMethodCall(const MethodCall('map#onStyleLoaded'));
    await tester.pump();
    expect(platform.initializations, 1);
    expect(styleCallbacks, 1);
    expect(find.byType(NBMap), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  testWidgets('offline initialization can remain pending while map loads',
      (tester) async {
    final configured = Completer<dynamic>();
    final fallback = respond;
    respond = (call) =>
        call.method == 'configure' ? configured.future : fallback(call);
    await tester.pumpWidget(const MaterialApp(home: RegionalOfflinePage()));
    expect(calls.any((call) => call.method == 'configure'), isTrue);
    await createAndLoadMap(tester);
    expect(configured.isCompleted, isFalse);
    expect(calls.any((call) => call.method == 'beginDownloadPage'), isFalse);
    configured.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('offline initialization failure leaves the map available',
      (tester) async {
    final fallback = respond;
    respond = (call) async {
      if (call.method == 'configure') {
        throw PlatformException(
            code: 'CONFIGURATION_FAILED', message: 'Offline unavailable');
      }
      return fallback(call);
    };
    await tester.pumpWidget(const MaterialApp(home: RegionalOfflinePage()));
    await tester.pump();
    expect(find.text('Offline unavailable'), findsOneWidget);
    await createAndLoadMap(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('preview preparation and a slow catalog do not gate map loading',
      (tester) async {
    final catalog = Completer<dynamic>();
    final fallback = respond;
    respond = (call) =>
        call.method == 'fetchRegionList' ? catalog.future : fallback(call);
    await tester.pumpWidget(const MaterialApp(home: RegionalOfflinePage()));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    expect(calls.any((call) => call.method == 'fetchRegionList'), isTrue);
    expect(find.text('Preparing preview resources'), findsOneWidget);
    await createAndLoadMap(tester);
    expect(catalog.isCompleted, isFalse);
    catalog.complete(<dynamic>[]);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
