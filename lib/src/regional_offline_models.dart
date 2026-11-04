part of '../nb_maps_flutter.dart';

Map<String, dynamic> _regionalMap(dynamic value) =>
    Map<String, dynamic>.from(value as Map);
int _regionalInt(Map<String, dynamic> map, String key) =>
    (map[key] as num?)?.toInt() ?? 0;
List<T> _regionalObjects<T>(
        dynamic value, T Function(Map<String, dynamic>) decode) =>
    List<T>.unmodifiable((value as List? ?? const [])
        .map((dynamic item) => decode(_regionalMap(item))));

/// Whether the account/provider configuration supports regional offline APIs.
enum RegionalOfflineSupportStatus {
  /// The initialized account uses a supported tile server.
  supported,

  /// Initialize [NextBillion] before configuring regional offline management.
  nextbillionNotInitialized,

  /// Select [WellKnownTileServer.nbTomtom] before creating maps.
  tomtomRequired
}

/// Commands accepted by [RegionalOffline.controlDownload].
enum RegionalOfflineDownloadAction {
  /// Pauses the region's download task.
  pause,

  /// Resumes the region's paused task.
  resume,

  /// Cancels the region's download task.
  cancel,

  /// Deletes the region's downloaded package data.
  delete
}

/// Current native task phase; [RegionalOfflineDownloadProgress.nativeState]
/// preserves the original name when the SDK introduces an unknown phase.
enum RegionalOfflineDownloadState {
  /// Accepted and waiting to run.
  queued,

  /// Preparing the resources needed to display offline maps.
  preparingOfflineDisplay,

  /// Transferring or installing the region's packages.
  downloadingPackage,

  /// Paused by the user.
  pausedUser,

  /// Paused because the required network is unavailable.
  pausedNetwork,

  /// Failed due to a storage-related error.
  failedStorage,

  /// Failed; inspect the task's error fields.
  failed,

  /// The SDK reports completion; also inspect installed and Preview readiness.
  completed,

  /// The SDK reports cancellation; the task may subsequently disappear.
  cancelled,

  /// An unrecognized SDK phase; inspect the original native state name.
  unknown,
}

/// A downloadable region returned by the online catalog.
///
/// Sizes are bytes. Source timestamps are preserved without unit conversion.
@immutable
class RegionalOfflineCatalogItem {
  /// CDN region ID passed to [RegionalOffline] methods, not a legacy pack ID.
  final int regionId;

  /// Region name supplied by the catalog.
  final String name;

  /// Full English country name used by the catalog's country filter.
  final String adminL0;

  /// First administrative subdivision, or an empty string if absent.
  final String adminL1;

  /// Third administrative subdivision, or an empty string if absent.
  final String adminL3;

  /// Catalog version identifier, when supplied.
  final String? version;

  /// Aggregate package size reported by the catalog, in bytes.
  final int totalSize;

  /// Tile count reported by the catalog.
  final int tileCount;

  /// Source timestamp as supplied by the CDN; no unit conversion is performed.
  final int? timestamp;

  const RegionalOfflineCatalogItem(
      {required this.regionId,
      required this.name,
      required this.adminL0,
      required this.adminL1,
      required this.adminL3,
      this.version,
      required this.totalSize,
      required this.tileCount,
      this.timestamp});

  factory RegionalOfflineCatalogItem.fromMap(Map<String, dynamic> map) =>
      RegionalOfflineCatalogItem(
          regionId: _regionalInt(map, 'regionId'),
          name: map['name'] as String,
          adminL0: map['adminL0'] as String? ?? '',
          adminL1: map['adminL1'] as String? ?? '',
          adminL3: map['adminL3'] as String? ?? '',
          version: map['version'] as String?,
          totalSize: _regionalInt(map, 'totalSize'),
          tileCount: _regionalInt(map, 'tileCount'),
          timestamp: (map['timestamp'] as num?)?.toInt());
}

/// Local region installation metadata, including incomplete package records.
@immutable
class RegionalOfflineInstalledRegion {
  /// CDN region ID; use this for focus, local detail, and download controls.
  final int regionId;

  /// Human-readable local region name.
  final String displayName;

  /// Number of packages reported by the installation metadata.
  final int packageCount;

  /// Aggregate package size reported by the SDK, in bytes.
  final int totalBytes;

  /// Installed region version, when known.
  final String? regionVersion;

  /// Whether the SDK considers all expected packages installed and valid.
  ///
  /// Check Preview readiness separately. This does not promise every font,
  /// custom style, or camera position is covered by the installed data.
  final bool allTarsOk;

  /// Native data-source identifier; this is not the region ID.
  final int dataSourceId;

  /// Native display label for the data source.
  final String dataSourceLabel;

  const RegionalOfflineInstalledRegion(
      {required this.regionId,
      required this.displayName,
      required this.packageCount,
      required this.totalBytes,
      this.regionVersion,
      required this.allTarsOk,
      required this.dataSourceId,
      required this.dataSourceLabel});

  factory RegionalOfflineInstalledRegion.fromMap(Map<String, dynamic> map) =>
      RegionalOfflineInstalledRegion(
          regionId: _regionalInt(map, 'regionId'),
          displayName: map['displayName'] as String,
          packageCount: _regionalInt(map, 'packageCount'),
          totalBytes: _regionalInt(map, 'totalBytes'),
          regionVersion: map['regionVersion'] as String?,
          allTarsOk: map['allTarsOk'] == true,
          dataSourceId: _regionalInt(map, 'dataSourceId'),
          dataSourceLabel: map['dataSourceLabel'] as String);
}

/// One archive described by a region's package metadata.
@immutable
class RegionalOfflinePackageInfo {
  /// Archive name supplied by the CDN.
  final String tarName;

  /// Package version identifier.
  final String version;

  /// Advertised archive size in bytes.
  final int tarSize;

  /// Source timestamp without unit conversion, when supplied.
  final int? timestamp;

  /// Minimum zoom level advertised for this package.
  final int minZoom;

  /// Maximum zoom level advertised for this package.
  final int maxZoom;

  const RegionalOfflinePackageInfo(
      {required this.tarName,
      required this.version,
      required this.tarSize,
      this.timestamp,
      required this.minZoom,
      required this.maxZoom});

  factory RegionalOfflinePackageInfo.fromMap(Map<String, dynamic> map) =>
      RegionalOfflinePackageInfo(
          tarName: map['tarName'] as String,
          version: map['version'] as String,
          tarSize: _regionalInt(map, 'tarSize'),
          timestamp: (map['timestamp'] as num?)?.toInt(),
          minZoom: _regionalInt(map, 'minZoom'),
          maxZoom: _regionalInt(map, 'maxZoom'));
}

/// Parsed metadata for a catalog region and its downloadable packages.
@immutable
class RegionalOfflineRegionDetail {
  /// CDN region ID associated with this metadata.
  final int regionId;

  /// Region version identifier, when supplied.
  final String? version;

  /// Country name, when present in the metadata.
  final String? country;

  /// First administrative subdivision, when supplied.
  final String? adminL1;

  /// Second administrative subdivision, when supplied.
  final String? adminL2;

  /// Third administrative subdivision, when supplied.
  final String? adminL3;

  /// Source timestamp without unit conversion, when supplied.
  final int? timestamp;

  /// Aggregate package size in bytes, as reported by the SDK.
  final int totalSize;

  /// Package metadata; lists decoded from the native bridge are unmodifiable.
  final List<RegionalOfflinePackageInfo> packages;

  const RegionalOfflineRegionDetail(
      {required this.regionId,
      this.version,
      this.country,
      this.adminL1,
      this.adminL2,
      this.adminL3,
      this.timestamp,
      required this.totalSize,
      required this.packages});

  factory RegionalOfflineRegionDetail.fromMap(Map<String, dynamic> map) =>
      RegionalOfflineRegionDetail(
          regionId: _regionalInt(map, 'regionId'),
          version: map['version'] as String?,
          country: map['country'] as String?,
          adminL1: map['adminL1'] as String?,
          adminL2: map['adminL2'] as String?,
          adminL3: map['adminL3'] as String?,
          timestamp: (map['timestamp'] as num?)?.toInt(),
          totalSize: _regionalInt(map, 'totalSize'),
          packages: _regionalObjects(
              map['packages'], RegionalOfflinePackageInfo.fromMap));
}

/// Parsed and original metadata returned by online or local detail queries.
@immutable
class RegionalOfflineRegionDetailResult {
  /// Parsed detail, or null when the query has no saved/available detail.
  final RegionalOfflineRegionDetail? detail;

  /// Original metadata JSON, or null when unavailable.
  final String? detailJson;
  const RegionalOfflineRegionDetailResult({this.detail, this.detailJson});
  factory RegionalOfflineRegionDetailResult.fromMap(Map<String, dynamic> map) =>
      RegionalOfflineRegionDetailResult(
          detail: map['detail'] == null
              ? null
              : RegionalOfflineRegionDetail.fromMap(
                  _regionalMap(map['detail'])),
          detailJson: map['detailJson'] as String?);
}

/// Combined catalog, installed-region, and Preview-readiness snapshot.
@immutable
class RegionalOfflineRegionSnapshot {
  /// Online catalog returned by the query.
  final List<RegionalOfflineCatalogItem> catalog;

  /// Local installation records, which may include incomplete regions.
  final List<RegionalOfflineInstalledRegion> installed;

  /// SDK-reported readiness of the Preview styles.
  final bool previewStylesReady;

  /// SDK-reported readiness of the offline display resources.
  final bool displayReady;

  /// Download-page readiness hint, not a prerequisite for creating [NBMap].
  final bool canBindOfflineMap;

  /// Whether readiness flags derive from one shared Preview Bundle state.
  ///
  /// True on iOS: the flags are not independent per-resource checks and do not
  /// guarantee tile coverage. Android reports its separate native checks.
  final bool readinessIsBundleOnly;
  const RegionalOfflineRegionSnapshot(
      {required this.catalog,
      required this.installed,
      required this.previewStylesReady,
      required this.displayReady,
      required this.canBindOfflineMap,
      required this.readinessIsBundleOnly});
  factory RegionalOfflineRegionSnapshot.fromMap(Map<String, dynamic> map) =>
      RegionalOfflineRegionSnapshot(
          catalog: _regionalObjects(
              map['catalog'], RegionalOfflineCatalogItem.fromMap),
          installed: _regionalObjects(
              map['installed'], RegionalOfflineInstalledRegion.fromMap),
          previewStylesReady: map['previewStylesReady'] == true,
          displayReady: map['displayReady'] == true,
          canBindOfflineMap: map['canBindOfflineMap'] == true,
          readinessIsBundleOnly: map['readinessIsBundleOnly'] == true);
}

/// One task in a current download snapshot, not persistent download history.
@immutable
class RegionalOfflineDownloadProgress {
  /// CDN region ID identifying this task.
  final int regionId;

  /// Normalized task phase; inspect [nativeState] for unknown native phases.
  final RegionalOfflineDownloadState state;

  /// Original state name, retained for forward compatibility.
  final String nativeState;

  /// Aggregate transferred bytes reported by the native task.
  final int downloadedBytes;

  /// Aggregate expected transfer size in bytes, as reported by the SDK.
  final int totalBytes;

  /// Archive currently being processed, when supplied.
  final String? currentPackageName;

  /// Native diagnostic message, when available.
  final String? errorMessage;

  /// Structured native error when available; Android task progress may only
  /// contain [errorMessage]. Operation errors use PlatformException instead.
  final Map<String, dynamic>? error;

  /// SDK-reported percentage. A value of 100 alone does not imply that the
  /// Preview Bundle is ready or that every requested map resource is installed.
  final int percent;
  const RegionalOfflineDownloadProgress(
      {required this.regionId,
      required this.state,
      required this.nativeState,
      required this.downloadedBytes,
      required this.totalBytes,
      this.currentPackageName,
      this.errorMessage,
      this.error,
      required this.percent});

  factory RegionalOfflineDownloadProgress.fromMap(Map<String, dynamic> map) {
    final nativeState = map['state'] as String;
    final state = switch (nativeState) {
      'QUEUED' => RegionalOfflineDownloadState.queued,
      'PREPARING_GLYPHS' ||
      'PREPARING_OFFLINE_DISPLAY' =>
        RegionalOfflineDownloadState.preparingOfflineDisplay,
      'DOWNLOADING_PACKAGE' => RegionalOfflineDownloadState.downloadingPackage,
      'PAUSED_USER' => RegionalOfflineDownloadState.pausedUser,
      'PAUSED_NETWORK' => RegionalOfflineDownloadState.pausedNetwork,
      'FAILED_STORAGE' => RegionalOfflineDownloadState.failedStorage,
      'FAILED' => RegionalOfflineDownloadState.failed,
      'COMPLETED' => RegionalOfflineDownloadState.completed,
      'CANCELLED' => RegionalOfflineDownloadState.cancelled,
      _ => RegionalOfflineDownloadState.unknown,
    };
    return RegionalOfflineDownloadProgress(
        regionId: _regionalInt(map, 'regionId'),
        state: state,
        nativeState: nativeState,
        downloadedBytes: _regionalInt(map, 'downloadedBytes'),
        totalBytes: _regionalInt(map, 'totalBytes'),
        currentPackageName: map['currentPackageName'] as String?,
        errorMessage: map['errorMessage'] as String?,
        error: map['error'] == null
            ? null
            : Map<String, dynamic>.unmodifiable(_regionalMap(map['error'])),
        percent: _regionalInt(map, 'percent'));
  }
}

/// Process-wide state of the Preview Bundle's preparation and activation.
@immutable
class RegionalOfflinePreviewBundleImportStatus {
  /// Whether the SDK reports that the Preview Bundle is ready for display.
  ///
  /// Region packages and camera coverage must still be checked independently.
  final bool previewBundleReady;

  /// Whether the SDK is currently ensuring/importing the Preview resources.
  final bool ensuring;

  /// Whether preparation is waiting for a network connection.
  final bool waitingForNetwork;

  /// Last native error code, when supplied.
  final String? lastErrorCode;

  /// Last native diagnostic message, when supplied.
  final String? lastErrorMessage;

  /// Whether the SDK classifies the preparation state/error as recoverable.
  /// This is not a guarantee that a retry will succeed.
  final bool recoverable;
  const RegionalOfflinePreviewBundleImportStatus(
      {required this.previewBundleReady,
      required this.ensuring,
      required this.waitingForNetwork,
      this.lastErrorCode,
      this.lastErrorMessage,
      required this.recoverable});
  factory RegionalOfflinePreviewBundleImportStatus.fromMap(
          Map<String, dynamic> map) =>
      RegionalOfflinePreviewBundleImportStatus(
          previewBundleReady: map['previewBundleReady'] == true,
          ensuring: map['ensuring'] == true,
          waitingForNetwork: map['waitingForNetwork'] == true,
          lastErrorCode: map['lastErrorCode'] as String?,
          lastErrorMessage: map['lastErrorMessage'] as String?,
          recoverable: map['recoverable'] == true);
}

/// Snapshot of the SDK's Preview/display resource checks.
///
/// Inspect [readinessIsBundleOnly] before interpreting flags as independent
/// probes. These flags describe preparation, not complete geographic coverage.
@immutable
class RegionalOfflinePreviewResourceStatus {
  /// Whether the SDK reports a ready Preview Bundle.
  final bool previewBundleReady;

  /// Whether the SDK reports its Preview styles ready.
  final bool previewStylesReady;

  /// Whether the native resource check reports cached style JSON.
  final bool styleJsonCached;

  /// Whether the native resource check reports ready sprites.
  final bool spritesReady;

  /// Whether the native resource check reports ready TileJSON metadata.
  final bool tileJsonReady;

  /// SDK-reported offline display readiness.
  final bool displayReady;

  /// Whether the SDK's preparation state allows a region download to enqueue.
  final bool canEnqueueRegionDownload;

  /// A download-page compatibility flag, not a prerequisite to create a map.
  final bool canBindOfflineMap;

  /// Preview style names reported as cached by the native SDK.
  final List<String> cachedPreviewStyleNames;

  /// Whether readiness flags derive from the shared Bundle state (true on iOS)
  /// rather than independent resource checks.
  final bool readinessIsBundleOnly;
  const RegionalOfflinePreviewResourceStatus(
      {required this.previewBundleReady,
      required this.previewStylesReady,
      required this.styleJsonCached,
      required this.spritesReady,
      required this.tileJsonReady,
      required this.displayReady,
      required this.canEnqueueRegionDownload,
      required this.canBindOfflineMap,
      required this.cachedPreviewStyleNames,
      required this.readinessIsBundleOnly});
  factory RegionalOfflinePreviewResourceStatus.fromMap(
          Map<String, dynamic> map) =>
      RegionalOfflinePreviewResourceStatus(
          previewBundleReady: map['previewBundleReady'] == true,
          previewStylesReady: map['previewStylesReady'] == true,
          styleJsonCached: map['styleJsonCached'] == true,
          spritesReady: map['spritesReady'] == true,
          tileJsonReady: map['tileJsonReady'] == true,
          displayReady: map['displayReady'] == true,
          canEnqueueRegionDownload: map['canEnqueueRegionDownload'] == true,
          canBindOfflineMap: map['canBindOfflineMap'] == true,
          cachedPreviewStyleNames: List<String>.unmodifiable(
              (map['cachedPreviewStyleNames'] as List).cast<String>()),
          readinessIsBundleOnly: map['readinessIsBundleOnly'] == true);
}
