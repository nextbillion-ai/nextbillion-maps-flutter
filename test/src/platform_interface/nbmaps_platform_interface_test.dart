import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final payload in [null, <Object?>[], <String, Object?>{}]) {
    test('payload-free native callbacks accept ${payload.runtimeType}',
        () async {
      final platform = MethodChannelNbMapsGl();
      final calls = <String>[];
      platform.onMapIdlePlatform.add((_) => calls.add('idle'));
      platform.onCameraMoveStartedPlatform.add((_) => calls.add('move-start'));
      platform.onAttributionClickPlatform.add((_) => calls.add('attribution'));
      platform.onCameraTrackingDismissedPlatform
          .add((_) => calls.add('tracking-dismissed'));
      for (final method in [
        'map#onIdle',
        'camera#onMoveStarted',
        'map#onAttributionClick',
        'map#onCameraTrackingDismissed',
      ]) {
        await platform.handleMethodCall(MethodCall(method, payload));
      }
      expect(
          calls, ['idle', 'move-start', 'attribution', 'tracking-dismissed']);
      platform.dispose();
    });
  }

  test('verify dispose functionalities', () async {
    const channel = MethodChannel('plugins.flutter.io/nbmaps_maps_1');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final NbMapsGlPlatform platform = MethodChannelNbMapsGl();
    platform.onInfoWindowTappedPlatform.add((String str) {});
    expect(platform.onInfoWindowTappedPlatform.length, 1);
    await platform.initPlatform(1);
    platform.dispose();
    expect(platform.onInfoWindowTappedPlatform, isEmpty);
  });
}
