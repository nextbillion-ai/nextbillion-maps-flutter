import 'dart:io';

/// Any HTTP response proves connectivity, including authentication/server errors.
/// Physical radio confirmation is still required before claiming offline mode.
Future<bool> canReachHttpServer(Uri uri,
    {Duration timeout = const Duration(seconds: 4)}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(uri).timeout(timeout);
    await request.close().timeout(timeout);
    // Headers already establish connectivity. Waiting for a response body could
    // hang a radio-state check or misclassify a truncated download as offline.
    return true;
  } on Exception {
    return false;
  } finally {
    client.close(force: true);
  }
}
