import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service.dart' show Instance, InstanceRef;
import 'package:vm_service/vm_service_io.dart';

/// USB-forwarded VM-service control for the example integration tests only.
/// Network acknowledgements must follow actual device radio changes.
Future<void> main(List<String> args) async {
  if (args.length < 2)
    throw ArgumentError(
        'Usage: <drive log> offline|online|heap|heap-no-ack|ack-heap|lifecycle [output.json]');
  final text = await File(args[0]).readAsString();
  final matches = RegExp(r'http://127\.0\.0\.1:\d+/[^\s]+').allMatches(text);
  final match = matches.lastWhere((m) => !m.group(0)!.contains('devtools'));
  final http = Uri.parse(match.group(0)!);
  final uri = http.replace(
      scheme: 'ws',
      path: '${http.path.endsWith('/') ? http.path : '${http.path}/'}ws');
  final service = await vmServiceConnectUri(uri.toString());
  try {
    final vm = await service.getVM();
    final ref = vm.isolates!
        .firstWhere((i) => i.name == 'main', orElse: () => vm.isolates!.first);

    if (args[1] == 'lifecycle') {
      // iOS debug AOT has no source-expression compiler. Read the binding's
      // existing enum field rather than evaluating code inside the application.
      final classes = await service.getClassList(ref.id!);
      final binding = classes.classes!.firstWhere(
          (type) => type.name == 'IntegrationTestWidgetsFlutterBinding');
      final instances = await service.getInstances(ref.id!, binding.id!, 1);
      final instance = await service.getObject(
          ref.id!, instances.instances!.single.id!) as Instance;
      final state = instance.fields!
          .firstWhere((field) => field.decl?.name == '_lifecycleState')
          .value as InstanceRef;
      final enumeration =
          await service.getObject(ref.id!, state.id!) as Instance;
      final name = enumeration.fields!
          .firstWhere((field) => field.decl?.name == '_name')
          .value as InstanceRef;
      // ignore: avoid_print
      print(jsonEncode({'lifecycleState': name.valueAsString}));
    } else if (args[1] == 'heap' || args[1] == 'heap-no-ack') {
      final profile = await service.getAllocationProfile(ref.id!, gc: true);
      final names = {
        'NextbillionMapController',
        'LineManager',
        'CircleManager',
        'FillManager',
        'SymbolManager',
        'OfflineNavigationState'
      };
      final counts = {
        for (final member in profile.members ?? [])
          if (names.contains(member.classRef?.name))
            member.classRef!.name!: member.instancesCurrent
      };
      final result = {
        'at': DateTime.now().toUtc().toIso8601String(),
        'classes': counts,
        'heapUsage': profile.memoryUsage?.heapUsage,
        'externalUsage': profile.memoryUsage?.externalUsage
      };
      if (args.length > 2)
        await File(args[2])
            .writeAsString(const JsonEncoder.withIndent('  ').convert(result));
      // ignore: avoid_print
      print(jsonEncode(result));
      if (args[1] == 'heap') {
        await service.callServiceExtension('ext.nbmapsTest.control',
            isolateId: ref.id, args: {'action': 'heap'});
      }
    } else {
      if (!['offline', 'online', 'ack-heap'].contains(args[1]))
        throw ArgumentError('Unknown action');
      await service.callServiceExtension('ext.nbmapsTest.control',
          isolateId: ref.id,
          args: {'action': args[1] == 'ack-heap' ? 'heap' : args[1]});
      // ignore: avoid_print
      print('Acknowledged physical-device ${args[1]} state');
    }
  } finally {
    await service.dispose();
  }
}
