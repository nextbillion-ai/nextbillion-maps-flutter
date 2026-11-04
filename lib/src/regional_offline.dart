part of '../nb_maps_flutter.dart';

/// Downloads and manages the native SDK's catalog-based offline map regions.
///
/// Initialize [NextBillion] with [WellKnownTileServer.nbTomtom], then await
/// [configure] before using the manager or subscribing to its streams.
/// [supportStatus] can be queried before initialization.
///
/// Region IDs come from [fetchRegionList] or [listInstalledRegions]. Every
/// `regionId` parameter must be an integer from 0 through 2147483647, inclusive;
/// it is not a legacy [OfflineRegion.id]. Invalid IDs are rejected by the native
/// bridge with `PlatformException(code: 'INVALID_ARGUMENT')`.
///
/// Downloads and storage belong to the process-wide native SDK. Display maps
/// with the normal [NBMap] widget; map creation does not wait for this manager.
/// Operation failures are reported as [PlatformException]s; stream errors are
/// delivered to the subscription's `onError` callback. These APIs are separate
/// from the legacy bounds-based [downloadOfflineRegion] API.
// Matches the process-wide native SDK facade; subscriptions have explicit lifetimes.
// ignore: avoid_classes_with_only_static_members
abstract final class RegionalOffline {
  static const _channel =
      MethodChannel('plugins.flutter.io/nb_maps_flutter/regional_offline');
  static const _eventChannel = EventChannel(
      'plugins.flutter.io/nb_maps_flutter/regional_offline/events');
  static Stream<dynamic>? _nativeEvents;
  static int _pageSequence = 0;

  /// Configures the process-wide manager using SDK-owned default storage.
  ///
  /// [mapsBaseUrl] is an optional absolute HTTP(S) CDN URL, not a database path.
  /// When omitted, the SDK uses the current TomTom configuration's default CDN.
  /// Whitespace and trailing slashes are removed; an invalid URL throws
  /// [ArgumentError]. Repeating the same configuration is supported; changing
  /// the CDN after initialization requires an app restart and otherwise fails
  /// with `PlatformException(code: 'CONFIGURATION_FAILED')`.
  ///
  /// Configuration does not wait for preview preload/download completion and
  /// is not required to create or render an [NBMap]. A different CDN requires
  /// app restart. Wait for this Future before using other offline APIs.
  static Future<void> configure({String? mapsBaseUrl}) async {
    final baseUrl = mapsBaseUrl?.trim().replaceFirst(RegExp(r'/+$'), '');
    if (baseUrl != null) {
      final uri = Uri.tryParse(baseUrl);
      if (uri == null ||
          !uri.hasAuthority ||
          uri.host.isEmpty ||
          !{'http', 'https'}.contains(uri.scheme)) {
        throw ArgumentError.value(
            mapsBaseUrl, 'mapsBaseUrl', 'Expected an HTTP(S) URL');
      }
    }
    await _channel.invokeMethod<void>('configure', {'mapsBaseUrl': baseUrl});
  }

  /// Checks account initialization and whether the selected provider is TomTom.
  ///
  /// Does not require [configure]. A supported result describes API support,
  /// not internet connectivity, installed coverage, or offline resource readiness.
  static Future<RegionalOfflineSupportStatus> supportStatus() async {
    final value = await _channel.invokeMethod<String>('supportStatus');
    return switch (value) {
      'SUPPORTED' => RegionalOfflineSupportStatus.supported,
      'NEXTBILLION_NOT_INITIALIZED' =>
        RegionalOfflineSupportStatus.nextbillionNotInitialized,
      _ => RegionalOfflineSupportStatus.tomtomRequired,
    };
  }

  /// Fetches the online catalog, optionally filtered by [country].
  ///
  /// Use a full English country name, such as `Australia`, rather than an ISO
  /// code. Whitespace is trimmed and filtering is case-insensitive; null or
  /// blank fetches all rows. Returns an unmodifiable list, which can be empty.
  /// This may require network access; use [listInstalledRegions] while offline.
  static Future<List<RegionalOfflineCatalogItem>> fetchRegionList(
      {String? country}) async {
    final normalized = country?.trim();
    final items = _regionalObjects(
        await _channel
            .invokeMethod<dynamic>('fetchRegionList', {'country': normalized}),
        RegionalOfflineCatalogItem.fromMap);
    if (normalized == null || normalized.isEmpty) return items;
    // Static CDN files can ignore the query parameter. Preserve the API's
    // country contract regardless of server/native filtering differences.
    final expected = normalized.toLowerCase();
    return List<RegionalOfflineCatalogItem>.unmodifiable(
        items.where((item) => item.adminL0.toLowerCase() == expected));
  }

  /// Combines the online catalog, installed records, and resource readiness.
  ///
  /// This may require network access. Use [listInstalledRegions] and
  /// [loadOfflineDetail] for local-only queries. Readiness flags describe SDK
  /// preparation, not complete tile coverage at every camera position.
  static Future<RegionalOfflineRegionSnapshot> queryRegions() async =>
      RegionalOfflineRegionSnapshot.fromMap(
          _regionalMap(await _channel.invokeMethod<dynamic>('queryRegions')));

  /// Fetches online package metadata for the catalog's [regionId].
  ///
  /// Returns parsed detail and the original JSON when available. This may
  /// require network access; [loadOfflineDetail] reads only the saved metadata.
  static Future<RegionalOfflineRegionDetailResult> fetchRegionDetail(
          int regionId) async =>
      RegionalOfflineRegionDetailResult.fromMap(_regionalMap(await _channel
          .invokeMethod<dynamic>('fetchRegionDetail', {'regionId': regionId})));

  /// Reads saved metadata for [regionId] without making a network request.
  ///
  /// The result's detail and JSON can be null when no local metadata exists.
  /// Reading metadata does not download or install a region.
  static Future<RegionalOfflineRegionDetailResult> loadOfflineDetail(
          int regionId) async =>
      RegionalOfflineRegionDetailResult.fromMap(_regionalMap(await _channel
          .invokeMethod<dynamic>('loadOfflineDetail', {'regionId': regionId})));

  /// Reads the locally installed region records without a catalog request.
  ///
  /// Returns an unmodifiable list. Check each record's `allTarsOk` and the
  /// independent Preview status before reporting offline readiness. A record
  /// can be present while its package installation is incomplete.
  static Future<List<RegionalOfflineInstalledRegion>>
      listInstalledRegions() async => _regionalObjects(
          await _channel.invokeMethod<dynamic>('listInstalledRegions'),
          RegionalOfflineInstalledRegion.fromMap);

  /// Checks for locally installed region records without fetching the catalog.
  ///
  /// A true result does not guarantee complete packages or Preview readiness;
  /// inspect [listInstalledRegions] and [getPreviewBundleImportStatus].
  static Future<bool> hasInstalledRegions() async =>
      await _channel.invokeMethod<bool>('hasInstalledRegions') ?? false;

  /// Reads a snapshot of the SDK's cached Preview/display resource status.
  ///
  /// Does not wait for preparation to finish. On iOS, several flags derive
  /// from the same Bundle state; inspect `readinessIsBundleOnly`. These flags
  /// are not prerequisites for creating an [NBMap].
  static Future<RegionalOfflinePreviewResourceStatus>
      offlinePreviewResourceStatus() async =>
          RegionalOfflinePreviewResourceStatus.fromMap(_regionalMap(
              await _channel
                  .invokeMethod<dynamic>('offlinePreviewResourceStatus')));

  /// Reads the current Preview preparation state without waiting for readiness.
  ///
  /// Use [previewBundleImportStatus] to observe preparation, network waits,
  /// errors, and subsequent recovery.
  static Future<RegionalOfflinePreviewBundleImportStatus>
      getPreviewBundleImportStatus() async =>
          RegionalOfflinePreviewBundleImportStatus.fromMap(_regionalMap(
              await _channel
                  .invokeMethod<dynamic>('getPreviewBundleImportStatus')));

  /// Reads an unmodifiable snapshot of the current region download tasks.
  ///
  /// Completed or cancelled tasks may disappear. Use [listInstalledRegions]
  /// to restore installed data rather than treating this as download history.
  static Future<List<RegionalOfflineDownloadProgress>>
      getDownloadProgress() async => _regionalObjects(
          await _channel.invokeMethod<dynamic>('getDownloadProgress'),
          RegionalOfflineDownloadProgress.fromMap);

  /// Starts a download-page session. Pass its token to [endDownloadPage] when
  /// leaving the Flutter route, even if the Activity stays alive.
  ///
  /// Call after [configure] while the host Activity/view controller is available.
  /// Returns a unique page token. Starting a new session replaces the previous
  /// active session; this does not create a separate download manager.
  static Future<String> beginDownloadPage() async {
    final pageId =
        '${DateTime.now().microsecondsSinceEpoch}_${_pageSequence++}';
    await _channel.invokeMethod<void>('beginDownloadPage', {'pageId': pageId});
    return pageId;
  }

  /// Releases the page session identified by [pageId].
  ///
  /// Pass the exact token returned by [beginDownloadPage]. A stale token cannot
  /// close a newer session. Also cancel the page's stream subscriptions; ending
  /// a session does not delete installed regions or cancel process-wide tasks.
  static Future<void> endDownloadPage(String pageId) =>
      _channel.invokeMethod<void>('endDownloadPage', {'pageId': pageId});

  /// Starts or enqueues a download for the catalog's [regionId].
  ///
  /// [clearBefore] defaults to false so the SDK can reuse existing package data.
  /// True asks the SDK to clear that region's package files before a fresh
  /// download; keep it false for ordinary downloads and task resumption.
  ///
  /// Completes when the task is accepted, not when installation finishes.
  /// Observe [downloadProgress], then check [listInstalledRegions] and the
  /// independent [previewBundleImportStatus]. A transfer percentage of 100
  /// alone does not establish offline display readiness.
  static Future<void> downloadRegion(int regionId,
          {bool clearBefore = false}) =>
      _channel.invokeMethod<void>(
          'downloadRegion', {'regionId': regionId, 'clearBefore': clearBefore});

  /// Applies [action] to the task or installed data identified by [regionId].
  ///
  /// Supports pause, resume, cancel, and deletion via
  /// [RegionalOfflineDownloadAction]. Deletion removes the region's local
  /// packages. Completion acknowledges the command; native cleanup or resumed
  /// installation may still be running. Observe progress and reread installed
  /// records to update the UI.
  static Future<void> controlDownload(
          int regionId, RegionalOfflineDownloadAction action) =>
      _channel.invokeMethod<void>(
          'controlDownload', {'regionId': regionId, 'action': action.name});

  /// Asks the SDK to refresh installed resources and retry loading on map resume.
  ///
  /// Can be used when returning to a map after package installation or a network
  /// change. It does not select a region, rebuild the map, or download a package;
  /// completion does not imply that all visible map resources have rendered.
  static Future<void> refreshEngine() =>
      _channel.invokeMethod<void>('refreshEngine');

  /// Observes current region download tasks after [configure].
  ///
  /// Each subscription receives an initial snapshot and then live updates.
  /// Completed/cancelled tasks may disappear; use [listInstalledRegions] when
  /// restoring a page rather than waiting for a past completion event. Cancel
  /// subscriptions when their owner is disposed; this does not cancel downloads.
  static Stream<List<RegionalOfflineDownloadProgress>> get downloadProgress =>
      _snapshots(
          'downloadProgress',
          getDownloadProgress,
          (value) =>
              _regionalObjects(value, RegionalOfflineDownloadProgress.fromMap));

  /// Observes Preview preparation independently of individual region transfers.
  ///
  /// Subscribe after [configure]. Each subscriber receives an initial snapshot
  /// and live updates, including network waits and errors. Cancel on page
  /// disposal. This stream shares the native event channel with
  /// [downloadProgress], but subscriptions have independent lifetimes.
  static Stream<RegionalOfflinePreviewBundleImportStatus>
      get previewBundleImportStatus => _snapshots(
          'previewBundleImportStatus',
          getPreviewBundleImportStatus,
          (value) => RegionalOfflinePreviewBundleImportStatus.fromMap(
              _regionalMap(value)));

  static Stream<T> _snapshots<T>(
      String type, Future<T> Function() snapshot, T Function(dynamic) decode) {
    _nativeEvents ??= _eventChannel.receiveBroadcastStream();
    return Stream<T>.multi((controller) {
      var received = false;
      var cancelled = false;
      final subscription = _nativeEvents!.listen(
          (dynamic value) {
            try {
              final event = _regionalMap(value);
              if (event['type'] == type) {
                controller.add(decode(event['data']));
                received = true;
              }
            } catch (error, stack) {
              controller.addError(error, stack);
            }
          },
          onError: controller.addError,
          onDone: () {
            cancelled = true;
            controller.close();
          });
      snapshot().then((value) {
        if (!cancelled && !received) controller.add(value);
      }, onError: (Object error, StackTrace stack) {
        if (!cancelled && !received) controller.addError(error, stack);
      });
      controller.onCancel = () {
        cancelled = true;
        return subscription.cancel();
      };
    }, isBroadcast: true);
  }
}
