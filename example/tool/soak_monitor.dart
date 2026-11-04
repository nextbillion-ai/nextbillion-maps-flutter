import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service.dart' show VmService;
import 'package:vm_service/vm_service_io.dart';

/// Reads checkpoints over the VM service, independently of iOS console output.
/// Usage: <drive log> <output directory> [Android adb path] [Android serial]
Future<void> main(List<String> args) async {
  if (args.length != 2 && args.length != 4) {
    throw ArgumentError('Expected log, output directory, optional adb/serial');
  }
  final output = Directory(args[1])..createSync(recursive: true);
  final seen = <String>{};
  final deadline = DateTime.now().add(const Duration(minutes: 85));
  const names = {
    'NextbillionMapController',
    'LineManager',
    'CircleManager',
    'FillManager',
    'SymbolManager',
    'OfflineNavigationState',
  };
  while (DateTime.now().isBefore(deadline)) {
    if (!await File(args[0]).exists()) {
      await Future<void>.delayed(const Duration(seconds: 2));
      continue;
    }
    final log = await File(args[0]).readAsString();
    final matches = RegExp(r'http://127\.0\.0\.1:\d+/[^\s]+')
        .allMatches(log)
        .where((m) => !m.group(0)!.contains('devtools'));
    if (matches.isEmpty) {
      await Future<void>.delayed(const Duration(seconds: 2));
      continue;
    }
    final http = Uri.parse(matches.last.group(0)!);
    final uri = http.replace(
        scheme: 'ws',
        path: '${http.path.endsWith('/') ? http.path : '${http.path}/'}ws');
    VmService? service;
    try {
      service = await vmServiceConnectUri(uri.toString())
          .timeout(const Duration(seconds: 10));
      final vm = await service.getVM();
      final isolate = vm.isolates!.firstWhere((i) => i.name == 'main');
      while (DateTime.now().isBefore(deadline)) {
        final response = await service.callServiceExtension(
            'ext.nbmapsTest.control',
            isolateId: isolate.id,
            args: {'action': 'status'}).timeout(const Duration(seconds: 10));
        final state = response.json!;
        if (state['completed'] == true) return;
        if ((await File(args[0]).readAsString())
            .contains('Leaving the application running.')) {
          throw StateError('Device test ended without completing the soak');
        }
        final phase = state['waitingHeapPhase'];
        if (phase is String && !seen.contains(phase)) {
          if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(phase)) {
            throw StateError('Invalid checkpoint name');
          }
          try {
            final profile =
                await service.getAllocationProfile(isolate.id!, gc: true);
            final sample = {
              'at': DateTime.now().toUtc().toIso8601String(),
              'classes': {
                for (final c in profile.members ?? [])
                  if (names.contains(c.classRef?.name))
                    c.classRef!.name!: c.instancesCurrent
              },
              'heapUsage': profile.memoryUsage?.heapUsage,
              'externalUsage': profile.memoryUsage?.externalUsage,
            };
            await File('${output.path}/$phase-dart.json').writeAsString(
                const JsonEncoder.withIndent('  ').convert(sample));
            // Class counters contain no application field values. Keep the
            // full profile to distinguish SDK objects from test/engine growth.
            await File('${output.path}/$phase-allocation.json')
                .writeAsString(jsonEncode(profile.toJson()));
            if (args.length == 4) {
              final native = await Process.run(args[2], [
                '-s',
                args[3],
                'shell',
                'dumpsys',
                'meminfo',
                'ai.nextbillion.example.maps_flutter'
              ]);
              await File('${output.path}/$phase-native.txt')
                  .writeAsString(native.stdout as String);
            }
            // ignore: avoid_print
            print('GC checkpoint $phase ${jsonEncode(sample['classes'])}');
          } finally {
            await service.callServiceExtension('ext.nbmapsTest.control',
                isolateId: isolate.id, args: {'action': 'heap'});
            seen.add(phase);
          }
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    } catch (error) {
      // Console disconnects must not stop checkpoint discovery; reconnect.
      // ignore: avoid_print
      print('VM monitor reconnect: ${error.runtimeType}');
      if ((await File(args[0]).readAsString())
          .contains('Leaving the application running.')) rethrow;
      await Future<void>.delayed(const Duration(seconds: 2));
    } finally {
      await service?.dispose();
    }
  }
  throw StateError('Soak monitor deadline exceeded');
}
