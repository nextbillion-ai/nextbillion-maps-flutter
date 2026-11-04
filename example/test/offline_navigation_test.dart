import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:nb_maps_flutter_example/offline_navigation.dart';

class _MapPlatform extends MethodChannelNbMapsGl {
  @override
  Widget buildView(
          Map<String, dynamic> creationParams,
          OnPlatformViewCreatedCallback onPlatformViewCreated,
          Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers) =>
      const SizedBox();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods =
      MethodChannel('plugins.flutter.io/nb_maps_flutter/regional_offline');
  const events = MethodChannel(
      'plugins.flutter.io/nb_maps_flutter/regional_offline/events');
  final original = NbMapsGlPlatform.createInstance;
  late Future<dynamic> Function(MethodCall) respond;
  setUp(() {
    NbMapsGlPlatform.createInstance = _MapPlatform.new;
    respond = (call) async => switch (call.method) {
          'getDownloadProgress' || 'listInstalledRegions' => <dynamic>[],
          'fetchRegionList' => [
              {'regionId': 1, 'name': 'Larger', 'totalSize': 900},
              {'regionId': 2, 'name': 'Smaller', 'totalSize': 100},
            ],
          'getPreviewBundleImportStatus' => {
              'previewBundleReady': false,
              'ensuring': true,
              'waitingForNetwork': true,
              'recoverable': true
            },
          _ => null,
        };
    messenger.setMockMethodCallHandler(methods, (call) => respond(call));
    messenger.setMockMethodCallHandler(events, (_) async => null);
  });
  tearDown(() {
    NbMapsGlPlatform.createInstance = original;
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockMethodCallHandler(events, null);
  });

  test('local playback interpolates and clamps track positions', () {
    const track = PlaybackTrack('fixture', [LatLng(0, 0), LatLng(10, 20)]);
    expect(track.position(-1), const LatLng(0, 0));
    expect(track.position(0.5), const LatLng(5, 10));
    expect(track.position(2), const LatLng(10, 20));
  });

  testWidgets('new test page keeps map mounted while setup is pending',
      (tester) async {
    final pending = Completer<dynamic>();
    final fallback = respond;
    respond =
        (call) => call.method == 'configure' ? pending.future : fallback(call);
    await tester.pumpWidget(const MaterialApp(home: OfflineNavigationView()));
    expect(find.byType(NBMap), findsOneWidget);
    expect(pending.isCompleted, isFalse);
    await tester.pumpWidget(const SizedBox());
    pending.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('immutable SDK catalog is copied before sorting', (tester) async {
    final key = GlobalKey<OfflineNavigationState>();
    await tester.pumpWidget(MaterialApp(home: OfflineNavigationView(key: key)));
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    expect(key.currentState!.configured, isTrue);
    await key.currentState!.refreshCatalog();
    await tester.pump();
    expect(key.currentState!.catalog.map((p) => p.regionId), [2, 1]);
    expect(key.currentState!.error, isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('closing playback page releases its periodic timer',
      (tester) async {
    final key = GlobalKey<OfflineNavigationState>();
    await tester.pumpWidget(MaterialApp(
        home: OfflineNavigationView(key: key, autoInitialize: false)));
    key.currentState!.setPlaying(true);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
