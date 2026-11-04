# Flutter plugin 4.0.0 integration

This plugin release uses iOS Maps 2.3.3 through Swift Package Manager (SPM) and
Android Maps 3.3.1. From Flutter plugin **4.0.0 onward, iOS supports only SPM**;
CocoaPods support and both Podspec files have been removed. Flutter 3.41+ is
required because the package depends on the generated FlutterFramework SPM package
(full builds are validated with Flutter 3.44). The Flutter iOS host must target
iOS 13 or later; the native SDK/package deployment target remains 12.0. Android requires
compileSdk 34 or later and minSdk 23; the plugin includes a Kotlin adapter for
the native regional-offline coroutine APIs.

## iOS dependency installation

Use a Flutter SDK with SPM support (validated with Flutter 3.44.0) and enable it
in the host application's `pubspec.yaml`:

```yaml
flutter:
  config:
    enable-swift-package-manager: true
```

```sh
flutter pub get
flutter build ios --simulator --debug
```

Flutter registers the plugin's Swift package and the official native distribution,
which is pinned to **2.3.3**. Run `flutter pub get` after changing dependencies so
Flutter regenerates its plugin package metadata before building.

For existing apps, remove any explicit `NextBillionMap` Pod override and migrate
the map plugin to SPM. Other dependencies can continue using CocoaPods if needed.
The example uses SPM for all its iOS plugins and has no Podfile, Pods build phases,
Pods workspace references or Pods xcconfig includes. See the
[changelog](../CHANGELOG.md) for the SDK upgrade notes.

## Tile servers

```dart
await NextBillion.initNextBillionWithTileServer(
  accessKey,
  WellKnownTileServer.nbTomtomOrbis,
);
```

TomTom, MapTiler and TomTom Orbis support online maps. Predefined style URIs
(`tomtom://`, `maptiler://`, `orbis://`) can be passed to `styleString`. Use
`NextBillion.predefinedStyles()` to obtain URLs for the active server.

On iOS, `styleString` accepts style URLs and local file/asset paths, but not
inline JSON. Unsupported JSON is rejected with `UNSUPPORTED_STYLE_JSON`; write
it to a local file and pass its `file://` URL instead. Android also accepts inline
JSON styles.

Regional Offline currently requires **TomTom**. MapTiler's reserved data-source
ID does not imply offline support. Country coverage comes from the returned
catalog rather than a fixed list in Dart.

**Android 3.3.1 limitation:** once Regional Offline has been initialized, selecting
Orbis throws `PlatformException(code: 'SDK_UPDATE_REQUIRED')` before changing the
active server. The published native SDK throws internally on this transition
and skips its refresh work. Orbis works when selected before Regional Offline
initialization. Updating the native SDK with the refresh fix is required to
remove this restriction; the Flutter adapter does not substitute TomTom offline
data for Orbis.

## Regional package API

This API is independent of the legacy `downloadOfflineRegion` API, which takes
bounds, zoom limits and a style URL. Its local pack IDs are not CDN region IDs.

### Default storage and independent map loading

Database locations are owned by the native SDK. The plugin does not set or expose
a destination database path; applications do not need to create directories or
configure a cache root. `mapsBaseUrl` only selects a network CDN. The `tilesDb`
argument to legacy `installOfflineMapTiles` identifies the source to import, not
where the SDK stores its database.

Build `NBMap` immediately. Regional Offline configuration, catalog requests and
Preview preparation are separate asynchronous work: do not wrap the map in a
FutureBuilder waiting for them, wait for `previewBundleReady` before showing the
map, or await offline preloading before `runApp`. Only the normal NextBillion
account initialization is required before creating a map.

The example mounts its map in the first Flutter frame, then starts offline setup. Android
configuration runs on IO; iOS configuration and local storage queries use a
background serial queue. Same-CDN iOS configuration requests share the in-flight
initialization, while a conflicting CDN is rejected. Flutter replies, listeners
and UI/lifecycle operations stay on the main thread. Preview status reads use the
SDK's published snapshot. Map creation and style loading do not wait for offline
configuration, metadata reads, imports or Preview readiness. Offline failures are
shown separately and do not remove the map.

Native SDK downloads/imports can still consume CPU, disk and network bandwidth.
Verify frame timing and map resource loading on devices during initialization
and downloads; background dispatch and widget tests alone do not establish
absence of resource contention inside the SDK.

```dart
await NextBillion.initNextBillionWithTileServer(
  accessKey,
  WellKnownTileServer.nbTomtom,
);
await RegionalOffline.configure();
// Optional: configure(mapsBaseUrl: 'https://your-cdn.example/maps').
// A different CDN after initialization requires restarting the app.

final regions = await RegionalOffline.fetchRegionList(country: 'United States');
final installed = await RegionalOffline.listInstalledRegions();
final detail = await RegionalOffline.fetchRegionDetail(regions.first.regionId);

await RegionalOffline.downloadRegion(regions.first.regionId);
// Success here means accepted/enqueued, not fully downloaded.
```

Countries use full English names, preserving case. Whitespace is trimmed; blank
or omitted country fetches the full catalog. Byte counts and source timestamps
are integers; timestamps are not converted to another unit by the plugin.

`queryRegions()` combines the online catalog, installed records and readiness.
`loadOfflineDetail(regionId)` only reads local detail and can return null fields.
`hasInstalledRegions()` and `offlinePreviewResourceStatus()` are available for
local checks. `controller.focusPreviewRegion(regionId)` focuses a particular map
on installed tile coverage, returning false when usable coverage is unavailable.

### Page sessions and events

Configure before subscribing. Each subscription receives a current snapshot and
then live updates. Concurrent progress and Preview subscriptions share a native
event channel; cancelling one does not stop the others or cancel SDK downloads.

```dart
final pageId = await RegionalOffline.beginDownloadPage();
final progressSubscription = RegionalOffline.downloadProgress.listen((tasks) {
  for (final task in tasks) {
    // Update UI with regionId, state, bytes, percent and optional error details.
  }
});
final previewSubscription = RegionalOffline.previewBundleImportStatus.listen(
  (status) { /* Show preparing / waitingForNetwork / previewBundleReady. */ },
);

// In the Flutter route's cleanup, also when the Activity remains alive:
await progressSubscription.cancel();
await previewSubscription.cancel();
await RegionalOffline.endDownloadPage(pageId);
```

A token from an older page cannot close the current page session. Android
adapts the host lifecycle to a page-specific LifecycleOwner; iOS scopes its
download-page session to the Flutter route token.

Use `controlDownload(regionId, RegionalOfflineDownloadAction.pause)` to pause;
`resume`, `cancel`, and `delete` are also supported. Control method completion
acknowledges the action; deletion/installation can continue asynchronously.

Do not infer completion from `percent == 100` alone. On iOS, package installation
may be followed by `preparingOfflineDisplay` until Preview activation succeeds.
Android normally waits for Preview before transfer; completed tasks and normal
cancellations can disappear from the task map. Refresh installed records when
restoring a page, and handle the independent Preview status. iOS resource probes
currently derive their flags from Bundle readiness, indicated by
`readinessIsBundleOnly`.

Operation failures use `PlatformException` with stable codes such as
`NOT_INITIALIZED`, `UNSUPPORTED_TILE_SERVER`, `NETWORK`, or native-specific storage
and package errors. Native details are preserved. Android task progress may only
provide diagnostic `errorMessage`, without a structured error code.

SDK downloads are process-wide. Leaving a page releases its session/listeners
but does not delete installed data. Persistent Android background downloading
requires a host foreground service and the SDK's `DownloadForegroundHook`; the
plugin does not install such a service or request notification permission.

The example app includes **Regional Offline** with country filtering, preview
status, catalog downloads, task controls, installed rows, and map focusing.

## Route trimming

Create a GeoJSON source with `GeojsonSourceProperties(lineMetrics: true)`, then
use a line gradient and trim interval:

```dart
await controller.addLineLayer('route-source', 'route-layer',
  const LineLayerProperties(
    lineWidth: 6,
    lineGradient: ['interpolate', ['linear'], ['line-progress'], 0, '#0088ff', 1, '#0088ff'],
    lineTrimOffset: [0.0, 0.0],
    lineTrimColor: '#888888',
  ),
);

await controller.setLineLayerProperties('route-layer',
  const LineLayerProperties(lineTrimOffset: [0.0, 0.45]),
);
```

The interval is normalized to `[0, 1]`, with start <= end. A raw numeric interval
is converted to a literal expression; explicit `['literal', [start, end]]` and
supported style expressions can also be used. The trimmed portion uses trimColor
or becomes transparent. Updates preserve the existing source and layer.

## Legacy compatibility and authentication

Android Maps 3.3.1 keeps Google Play Services Location optional. The Flutter
plugin includes consumer R8 rules for its three optional task callback types;
hosts without Google location continue to use the SDK's Android location fallback.

iOS 2.3.3 restricts legacy offline-pack downloads to TomTom. Unsupported services
now surface `UNSUPPORTED_TILE_SERVER`; switching away during a download reports
the pause without deleting installed data. The old downloader replies to its
method call once and sends subsequent updates on the event channel.

`installOfflineMapTiles` imports a compatible SDK offline-pack database from a
Flutter asset or absolute file path. It copies the input to a private writable
temporary directory, then uses the native SDK's import/merge API. The SDK chooses
the active database path and validates the input schema. Maps iOS 2.3.3 / Android
3.3.1 merge APIs accept schema v6 matching the active library; they reject v5 and
future versions rather than migrate the supplied library. Existing storage is not
replaced and the supplied file is left intact. The Future completes after the SDK
reports import success or failure. Temporary files are removed on completion or
failure. Import already submitted to the SDK may finish after engine detachment,
but its callback will not reply to the detached engine.

Supply a closed, consistent database containing offline packs and their resources.
This API does not restore a database containing only ambient cache entries, import
arbitrary MBTiles, or install Regional Offline CDN tar packages. Imported metadata
must follow the Flutter plugin's format to appear in its legacy region list.

Clear the dynamic API key header using
`await NextBillion.setApiKeyHeaderName(null)` to restore query authentication.
This setting is independent of general custom HTTP headers.
