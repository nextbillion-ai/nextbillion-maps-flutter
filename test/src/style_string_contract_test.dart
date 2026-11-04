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
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  for (final json in ['{"version":8}', ' \n {"version":8}', '\t[]']) {
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
      await platform.updateMapOptions({'styleString': style});
      expect(calls.single.method, 'map#update');
      expect(calls.single.arguments, {
        'options': {'styleString': style}
      });
      expect(widgetOptions(style).toMap()['styleString'], style);
    });
  }

  test('Android continues to accept inline JSON', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const style = '{"version":8,"sources":{},"layers":[]}';
    await platform.updateMapOptions({'styleString': style});
    expect(calls.single.arguments, {
      'options': {'styleString': style}
    });
    expect(widgetOptions(style).toMap()['styleString'], style);
  });
}
