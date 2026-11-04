import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => runDeviceDriver();

Future<void> runDeviceDriver(
        {Duration timeout = const Duration(minutes: 45)}) =>
    integrationDriver(
      timeout: timeout,
      writeResponseOnFailure: true,
      responseDataCallback: (data) async {
        final directory = Directory(
            Platform.environment['NB_TEST_OUTPUT'] ?? 'test_results/device');
        await directory.create(recursive: true);
        final images = data?['snapshots'] as Map?;
        if (images != null) {
          final filenames = <String>[];
          for (final entry in images.entries) {
            final bytes = base64Decode(entry.value as String);
            // Native snapshots are JPEG; physical UI captures are PNG.
            // Preserve the encoded format instead of labelling both as PNG.
            final extension =
                bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8
                    ? 'jpg'
                    : 'png';
            final filename = '${entry.key}.$extension';
            await File('${directory.path}/$filename').writeAsBytes(bytes);
            filenames.add(filename);
          }
          data!['snapshots'] = filenames;
        }
        await writeResponseData(data,
            destinationDirectory: directory.path,
            testOutputFilename: 'results');
        // A framework timeout can leave reportData unfinished. Saving that
        // report must never turn an incomplete fixed-provider run into a pass.
        if (data?['requiresCompletion'] == true && data?['completed'] != true) {
          throw StateError(
              'Device regression did not complete; inspect results.json and the device log');
        }
        final results = data?['results'] as List?;
        if (results != null &&
            results
                .any((result) => result is Map && result['status'] == 'fail')) {
          throw StateError('Device cases failed; inspect results.json');
        }
      },
    );
