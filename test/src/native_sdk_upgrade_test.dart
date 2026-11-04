import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods =
      MethodChannel('plugins.flutter.io/nb_maps_flutter/regional_offline');
  const events = MethodChannel(
      'plugins.flutter.io/nb_maps_flutter/regional_offline/events');
  const mapChannel = MethodChannel('native-sdk-upgrade-test-map');
  const codec = StandardMethodCodec();
  late List<MethodCall> calls;
  late List<String> eventCalls;
  late Future<dynamic> Function(MethodCall) respond;

  final idle = <String, dynamic>{
    'previewBundleReady': false,
    'ensuring': false,
    'waitingForNetwork': false,
    'recoverable': true,
  };
  Map<String, dynamic> progress(String state, {int bytes = 0}) => {
        'regionId': 12,
        'state': state,
        'downloadedBytes': bytes,
        'totalBytes': 9007199254740993,
        'percent': 99,
      };
  Future<void> send(String type, dynamic data) =>
      messenger.handlePlatformMessage(events.name,
          codec.encodeSuccessEnvelope({'type': type, 'data': data}), (_) {});
  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    calls = [];
    eventCalls = [];
    respond = (call) async => switch (call.method) {
          'getDownloadProgress' => <dynamic>[],
          'getPreviewBundleImportStatus' => idle,
          _ => null,
        };
    messenger.setMockMethodCallHandler(methods, (call) {
      calls.add(call);
      return respond(call);
    });
    messenger.setMockMethodCallHandler(events, (call) async {
      eventCalls.add(call.method);
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockMethodCallHandler(events, null);
    messenger.setMockMethodCallHandler(mapChannel, null);
  });

  test('Orbis uses native names in both directions', () {
    expect(WellKnownTileServer.nbTomtomOrbis.value, 'NGLTomTomOrbis');
    expect(WellKnownTileServerExt.fromString('NGLTomTomOrbis'),
        WellKnownTileServer.nbTomtomOrbis);
  });

  test('default configuration does not supply a database location', () async {
    await RegionalOffline.configure();
    expect(calls.single.method, 'configure');
    expect(calls.single.arguments, {'mapsBaseUrl': null});
  });

  test('configuration normalizes CDN root and rejects invalid URLs locally',
      () async {
    await RegionalOffline.configure(
        mapsBaseUrl: ' https://example.com/maps/// ');
    expect(calls.single.method, 'configure');
    expect(calls.single.arguments, {'mapsBaseUrl': 'https://example.com/maps'});
    await expectLater(
        RegionalOffline.configure(mapsBaseUrl: 'file:///tmp/maps'),
        throwsArgumentError);
    expect(calls, hasLength(1));
  });

  test(
      'configuration rejects an HTTP URL with an empty host before native invocation',
      () async {
    await expectLater(RegionalOffline.configure(mapsBaseUrl: 'https://?maps=1'),
        throwsArgumentError);
    expect(calls, isEmpty);
  });

  test('country is trimmed without replacing names or changing case', () async {
    respond = (_) async => <dynamic>[];
    await RegionalOffline.fetchRegionList(country: ' United States ');
    expect(calls.single.arguments, {'country': 'United States'});
  });

  test('country filtering survives a static CDN ignoring query parameters',
      () async {
    respond = (_) async => [
          {'regionId': 1, 'name': 'Sydney', 'adminL0': 'Australia'},
          {'regionId': 2, 'name': 'San Francisco', 'adminL0': 'United States'},
        ];
    final filtered =
        await RegionalOffline.fetchRegionList(country: ' australia ');
    expect(filtered.map((r) => r.regionId), [1]);
    expect(calls.single.arguments, {'country': 'australia'});
    expect(() => filtered.clear(), throwsUnsupportedError);
    expect(await RegionalOffline.fetchRegionList(country: 'No Such Country'),
        isEmpty);
    expect(await RegionalOffline.fetchRegionList(country: ' '), hasLength(2));
  });

  test('a successful submission returns without waiting for progress',
      () async {
    await RegionalOffline.downloadRegion(12, clearBefore: true);
    expect(calls.single.method, 'downloadRegion');
    expect(calls.single.arguments, {'regionId': 12, 'clearBefore': true});
    expect(eventCalls, isEmpty);
  });

  test('native operation errors preserve stable code and details', () async {
    respond = (_) async => throw PlatformException(
            code: 'UNSUPPORTED_TILE_SERVER',
            message: 'TomTom required',
            details: const {
              'domain': 'NGLRegionalOfflineErrorDomain',
              'nativeCode': 21
            });
    await expectLater(
        RegionalOffline.downloadRegion(12),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'UNSUPPORTED_TILE_SERVER')
            .having(
                (e) => (e.details as Map)['nativeCode'], 'nativeCode', 21)));
  });

  test('page tokens scope end calls independently of Activity lifetime',
      () async {
    final first = await RegionalOffline.beginDownloadPage();
    final second = await RegionalOffline.beginDownloadPage();
    expect(first, isNot(second));
    await RegionalOffline.endDownloadPage(first);
    expect(calls.last.method, 'endDownloadPage');
    expect(calls.last.arguments, {'pageId': first});
    await RegionalOffline.endDownloadPage(second);
  });

  test('Int64 bytes and timestamps survive catalog/detail decoding', () {
    const large = 9007199254740993;
    final catalog = RegionalOfflineCatalogItem.fromMap(const {
      'regionId': 12,
      'name': 'Region',
      'totalSize': large,
      'tileCount': 20,
      'timestamp': large,
    });
    expect(catalog.totalSize, large);
    expect(catalog.timestamp, large);
    final detail = RegionalOfflineRegionDetailResult.fromMap(const {
      'detailJson': '{}',
      'detail': {
        'regionId': 12,
        'totalSize': large,
        'packages': [
          {
            'tarName': 'part.tar.gz',
            'version': '10.2',
            'tarSize': large,
            'minZoom': 4,
            'maxZoom': 14
          }
        ]
      },
    });
    expect(detail.detail!.packages.single.tarSize, large);
    expect(detail.detail!.country, isNull);
    expect(() => detail.detail!.packages.clear(), throwsUnsupportedError);
    expect(RegionalOfflineRegionDetailResult.fromMap(const {}).detail, isNull);
  });

  test('state mapping handles platform differences without ordinal assumptions',
      () {
    expect(
        RegionalOfflineDownloadProgress.fromMap(progress('PREPARING_GLYPHS'))
            .state,
        RegionalOfflineDownloadState.preparingOfflineDisplay);
    expect(
        RegionalOfflineDownloadProgress.fromMap(
                progress('PREPARING_OFFLINE_DISPLAY'))
            .state,
        RegionalOfflineDownloadState.preparingOfflineDisplay);
    final unknown =
        RegionalOfflineDownloadProgress.fromMap(progress('FUTURE_STATE'));
    expect(unknown.state, RegionalOfflineDownloadState.unknown);
    expect(unknown.nativeState, 'FUTURE_STATE');
    final partial = RegionalOfflineDownloadProgress.fromMap(
        progress('DOWNLOADING_PACKAGE', bytes: 9007199254740993));
    expect(partial.downloadedBytes, 9007199254740993);
    expect(partial.error, isNull);
  });

  test('streams share native subscription, seed late listeners and cancel once',
      () async {
    var current = <dynamic>[];
    respond =
        (call) async => call.method == 'getDownloadProgress' ? current : idle;
    final progressEvents = <List<RegionalOfflineDownloadProgress>>[];
    final previewEvents = <RegionalOfflinePreviewBundleImportStatus>[];
    final first = RegionalOffline.downloadProgress.listen(progressEvents.add);
    final second =
        RegionalOffline.previewBundleImportStatus.listen(previewEvents.add);
    await settle();
    expect(progressEvents.single, isEmpty);
    expect(previewEvents.single.previewBundleReady, isFalse);
    expect(eventCalls.where((value) => value == 'listen'), hasLength(1));
    current = [progress('PAUSED_NETWORK')];
    await send('downloadProgress', current);
    await settle();
    expect(progressEvents.last.single.state,
        RegionalOfflineDownloadState.pausedNetwork);
    final lateEvents = <List<RegionalOfflineDownloadProgress>>[];
    final third = RegionalOffline.downloadProgress.listen(lateEvents.add);
    await settle();
    expect(lateEvents.single.single.state,
        RegionalOfflineDownloadState.pausedNetwork);
    await first.cancel();
    await third.cancel();
    expect(eventCalls.where((value) => value == 'cancel'), isEmpty);
    await second.cancel();
    await settle();
    expect(eventCalls.where((value) => value == 'cancel'), hasLength(1));
  });

  test('a delayed initial snapshot cannot overwrite a newer progress event',
      () async {
    final snapshot = Completer<dynamic>();
    respond = (_) => snapshot.future;
    final received = <List<RegionalOfflineDownloadProgress>>[];
    final subscription = RegionalOffline.downloadProgress.listen(received.add);
    await settle();
    await send('downloadProgress', [progress('COMPLETED')]);
    await settle();
    snapshot.complete(<dynamic>[]);
    await settle();
    expect(received, hasLength(1));
    expect(
        received.single.single.state, RegionalOfflineDownloadState.completed);
    await subscription.cancel();
    await settle();
  });

  test('line paint updates preserve expression encoding and use map channel',
      () async {
    final mapCalls = <MethodCall>[];
    messenger.setMockMethodCallHandler(mapChannel, (call) async {
      mapCalls.add(call);
      return call.method == 'regionalOffline#focusRegion' ? true : null;
    });
    final platform = MethodChannelNbMapsGl()
      ..setTestingMethodChanenl(mapChannel);
    const properties = LineLayerProperties(lineTrimOffset: [
      'literal',
      [0.0, 0.45]
    ], lineTrimColor: '#888888');
    await platform.setLineLayerProperties('route', properties.toJson());
    final args = mapCalls.single.arguments as Map;
    expect(mapCalls.single.method, 'lineLayer#setProperties');
    expect(args['layerId'], 'route');
    expect(
        jsonDecode((args['properties'] as Map)['line-trim-offset'] as String), [
      'literal',
      [0.0, 0.45]
    ]);
    expect(await platform.focusPreviewRegion(12), isTrue);
    expect(mapCalls.last.arguments, {'regionId': 12});
    final restored = LineLayerProperties.fromJson(properties.toJson());
    expect(
        restored
            .copyWith(const LineLayerProperties(lineTrimColor: '#ff0000'))
            .toJson(),
        {
          'line-trim-offset': [
            'literal',
            [0.0, 0.45]
          ],
          'line-trim-color': '#ff0000',
        });
  });
  test(
      'trim constants are normalized and invalid intervals fail before native calls',
      () {
    expect(
        const LineLayerProperties(lineTrimOffset: [0.0, 0.6])
            .toJson()['line-trim-offset'],
        [
          'literal',
          [0.0, 0.6]
        ]);
    for (final interval in [
      [0.8, 0.2],
      [-0.1, 0.5],
      [0.0, 1.1],
      [0.0],
      [0.0, double.nan]
    ]) {
      expect(() => LineLayerProperties(lineTrimOffset: interval).toJson(),
          throwsArgumentError);
    }
  });
  test('malformed stream payload reports an error and later updates still work',
      () async {
    final received = <List<RegionalOfflineDownloadProgress>>[];
    final errors = <Object>[];
    final subscription = RegionalOffline.downloadProgress
        .listen(received.add, onError: errors.add);
    await settle();
    await send('downloadProgress', {'invalid': 'not a task list'});
    await send('downloadProgress', [progress('PAUSED_USER')]);
    await settle();
    expect(errors, hasLength(1));
    expect(received.last.single.state, RegionalOfflineDownloadState.pausedUser);
    await subscription.cancel();
    await settle();
  });

  test('cancelling before snapshot completion does not emit or leak a listener',
      () async {
    final snapshot = Completer<dynamic>();
    respond = (_) => snapshot.future;
    final received = <List<RegionalOfflineDownloadProgress>>[];
    final subscription = RegionalOffline.downloadProgress.listen(received.add);
    await settle();
    await subscription.cancel();
    snapshot.complete([progress('COMPLETED')]);
    await settle();
    expect(received, isEmpty);
    expect(eventCalls.where((value) => value == 'cancel'), hasLength(1));
  });

  test('dynamic key header can be cleared using a null channel argument',
      () async {
    const nextBillion = MethodChannel('plugins.flutter.io/nextbillion_init');
    MethodCall? call;
    messenger.setMockMethodCallHandler(nextBillion, (value) async {
      call = value;
      return null;
    });
    try {
      await NextBillion.setApiKeyHeaderName(null);
      expect(call!.method, 'nextbillion/set_key_header_name');
      expect(call!.arguments, {'apiKeyHeaderName': null});
    } finally {
      messenger.setMockMethodCallHandler(nextBillion, null);
    }
  });
}
