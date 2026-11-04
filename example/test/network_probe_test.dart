import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../integration_test/support/network_probe.dart';

void main() {
  for (final status in [200, 401, 404, 500]) {
    test('HTTP $status proves connectivity even with an unfinished body',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.statusCode = status;
        request.response.contentLength = 1000;
        request.response.write('partial body');
        await request.response.flush();
      });
      try {
        expect(
            await canReachHttpServer(
                Uri.parse('http://127.0.0.1:${server.port}/probe'),
                timeout: const Duration(seconds: 1)),
            isTrue);
      } finally {
        await server.close(force: true);
      }
    });
  }

  test('a server which sends no response times out as unreachable', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((_) {});
    try {
      expect(
          await canReachHttpServer(
              Uri.parse('http://127.0.0.1:${server.port}/probe'),
              timeout: const Duration(milliseconds: 100)),
          isFalse);
    } finally {
      await server.close(force: true);
    }
  });
}
