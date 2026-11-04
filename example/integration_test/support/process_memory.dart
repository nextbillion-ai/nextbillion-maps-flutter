import 'dart:ffi';
import 'dart:io';

/// Process counters for test evidence only; these are not retain graphs.
/// TASK_VM_INFO's rev1 phys_footprint ends at byte 152 in Apple's arm64 ABI.
Map<String, Object?> processMemorySample() {
  if (Platform.isAndroid) {
    final status = File('/proc/self/status').readAsStringSync();
    final match =
        RegExp(r'^VmRSS:\s+(\d+)\s+kB', multiLine: true).firstMatch(status);
    return {'residentBytes': int.parse(match!.group(1)!) * 1024};
  }
  if (!Platform.isIOS) return {'unsupported': Platform.operatingSystem};
  final library = DynamicLibrary.process();
  final allocate = library.lookupFunction<
      Pointer<Void> Function(IntPtr, IntPtr),
      Pointer<Void> Function(int, int)>('calloc');
  final release = library.lookupFunction<Void Function(Pointer<Void>),
      void Function(Pointer<Void>)>('free');
  final taskInfo = library.lookupFunction<
      Int32 Function(Uint32, Uint32, Pointer<Int32>, Pointer<Uint32>),
      int Function(int, int, Pointer<Int32>, Pointer<Uint32>)>('task_info');
  final task = library.lookup<Uint32>('mach_task_self_').value;
  final allocation = allocate(1, 520);
  if (allocation == nullptr) return {'error': 'calloc failed'};
  try {
    final count = Pointer<Uint32>.fromAddress(allocation.address + 512)
      ..value = 128;
    final status = taskInfo(task, 22, allocation.cast<Int32>(), count);
    if (status != 0 || count.value < 38) {
      return {'taskInfoStatus': status, 'returnedNaturalCount': count.value};
    }
    final words = allocation.cast<Uint64>();
    return {
      'residentBytes': words[2],
      'residentPeakBytes': words[3],
      'internalBytes': words[6],
      'compressedBytes': words[15],
      'physicalFootprintBytes': words[18],
      'returnedNaturalCount': count.value,
    };
  } finally {
    release(allocation);
  }
}
