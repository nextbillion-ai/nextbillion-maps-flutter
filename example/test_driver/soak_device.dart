import 'offline_device.dart' as device;

/// A one-hour run plus builds/checkpoints must fit the host driver deadline.
Future<void> main() =>
    device.runDeviceDriver(timeout: const Duration(minutes: 90));
