import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('style-input-contract');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late MethodChannelNbMapsGl platform;
  late NextbillionMapController controller;
  late List<MethodCall> calls;
  final unsupported = isA<PlatformException>()
      .having((e) => e.code, 'code', 'UNSUPPORTED_STYLE_JSON');
  NextBillionMapOptions widgetOptions(String style) =>
      NextBillionMapOptions.fromWidget(NBMap(
        initialCameraPosition: const CameraPosition(target: LatLng(0, 0)),
        styleString: style,
      ));

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
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
    debugDefaultTargetPlatformOverride = null;
  });

  for (final json in ['{"version":8}', ' \n {"version":8}', '\t[]']) {
    test('iOS controller rejects inline JSON before native mutation: $json',
        () async {
      await expectLater(controller.setStyleString(json), throwsA(unsupported));
      expect(calls, isEmpty);
    });
    test('iOS initial widget options reject inline JSON: $json', () {
      expect(() => widgetOptions(json).toMap(), throwsA(unsupported));
    });
  }

  test('iOS updates reject JSON before sending other option changes', () async {
    await expectLater(
        platform.updateMapOptions(
            {'styleString': '{"version":8}', 'compassEnabled': false}),
        throwsA(unsupported));
    expect(calls, isEmpty);
  });

  for (final style in [
    'file:///tmp/custom-style.json',
    '/tmp/custom-style.json',
    'assets/style.json',
    'https://example.com/style.json',
    'tomtom://styles/basic',
  ]) {
    test('iOS preserves supported style location: $style', () async {
      await controller.setStyleString(style);
      expect(calls.single.method, 'style#setStyleString');
      expect(calls.single.arguments, {'styleString': style});
      expect(widgetOptions(style).toMap()['styleString'], style);
    });
  }

  test('Android continues to accept inline JSON', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const style = '{"version":8,"sources":{},"layers":[]}';
    await controller.setStyleString(style);
    expect(calls.single.arguments, {'styleString': style});
    expect(widgetOptions(style).toMap()['styleString'], style);
  });

  test('disposed controller remains a no-op even for unsupported input',
      () async {
    controller.dispose();
    calls.clear();
    await controller.setStyleString('{"version":8}');
    expect(calls, isEmpty);
  });
}
