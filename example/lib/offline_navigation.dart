import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

import 'page.dart';

class OfflineNavigationPage extends ExamplePage {
  const OfflineNavigationPage()
      : super(const Icon(Icons.navigation), 'Offline Maps & Route Playback');

  @override
  Widget build(BuildContext context) =>
      const OfflineNavigationView(showAppBar: false);
}

/// A deterministic local track. This does not call a routing service.
class PlaybackTrack {
  final String name;
  final List<LatLng> points;
  const PlaybackTrack(this.name, this.points);

  LatLng position(double fraction) {
    final offset = fraction.clamp(0.0, 1.0) * (points.length - 1);
    final index = math.min(offset.floor(), points.length - 2);
    final weight = offset - index;
    final a = points[index];
    final b = points[index + 1];
    return LatLng(a.latitude + (b.latitude - a.latitude) * weight,
        a.longitude + (b.longitude - a.longitude) * weight);
  }

  static const presets = [
    PlaybackTrack('Hyderabad', [
      LatLng(17.4401, 78.4860),
      LatLng(17.4416, 78.4880),
      LatLng(17.4438, 78.4900),
      LatLng(17.4456, 78.4920),
      LatLng(17.4475, 78.4940),
      LatLng(17.4494, 78.4960),
    ]),
    PlaybackTrack('San Francisco', [
      LatLng(37.7749, -122.4194),
      LatLng(37.7761, -122.4177),
      LatLng(37.7774, -122.4160),
      LatLng(37.7788, -122.4144),
      LatLng(37.7801, -122.4127),
      LatLng(37.7814, -122.4110),
    ]),
    PlaybackTrack('Sydney', [
      LatLng(-33.8685, 151.2070),
      LatLng(-33.8670, 151.2080),
      LatLng(-33.8655, 151.2090),
      LatLng(-33.8640, 151.2100),
      LatLng(-33.8625, 151.2110),
      LatLng(-33.8610, 151.2120),
    ]),
  ];
}

class OfflineNavigationView extends StatefulWidget {
  final bool autoInitialize;
  final bool showAppBar;
  final PlaybackTrack? initialTrack;
  final String? styleString;
  const OfflineNavigationView(
      {super.key,
      this.autoInitialize = true,
      this.showAppBar = true,
      this.initialTrack,
      this.styleString});

  @override
  State<OfflineNavigationView> createState() => OfflineNavigationState();
}

class OfflineNavigationState extends State<OfflineNavigationView> {
  final _clock = Stopwatch()..start();
  final _country = TextEditingController();
  final List<Map<String, Object?>> events = [];
  final Map<int, RegionalOfflineDownloadProgress> progress = {};
  List<RegionalOfflineCatalogItem> catalog = [];
  List<RegionalOfflineInstalledRegion> installed = [];
  RegionalOfflinePreviewBundleImportStatus? preview;
  NextbillionMapController? map;
  PlaybackTrack track = PlaybackTrack.presets.first;
  RegionalOfflineCatalogItem? selected;
  bool configured = false;
  bool configuring = false;
  bool loadingCatalog = false;
  bool routeReady = false;
  bool following = true;
  bool playing = false;
  String? error;
  String? pageId;
  int styleLoads = 0;
  // Device tests distinguish style JSON readiness from completed tile drawing.
  int mapIdleEvents = 0;
  int mapMount = 0;
  double fraction = 0;
  Circle? _vehicle;
  int _styleEpoch = 0;
  bool _writingPlayback = false;
  Timer? _timer;
  StreamSubscription<List<RegionalOfflineDownloadProgress>>? _progressSub;
  StreamSubscription<RegionalOfflinePreviewBundleImportStatus>? _previewSub;

  void record(String event, [Object? detail]) {
    if (!mounted) return;
    var message = detail?.toString() ?? '';
    message = message.replaceAll(RegExp(r'https?://\S+'), '<url>');
    if (message.length > 500) message = message.substring(0, 500);
    setState(() {
      events.add({
        'ms': _clock.elapsedMilliseconds,
        'event': event,
        'detail': message
      });
      if (events.length > 300) events.removeAt(0);
    });
  }

  void _failure(Object value) {
    if (!mounted) return;
    final code =
        value is PlatformException ? value.code : value.runtimeType.toString();
    setState(() => error = code);
    record('error', code);
  }

  @override
  void initState() {
    super.initState();
    track = widget.initialTrack ?? PlaybackTrack.presets.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.autoInitialize) unawaited(configureOffline());
    });
  }

  Future<void> configureOffline() async {
    if (configured || configuring) return;
    setState(() {
      configuring = true;
      error = null;
    });
    record('configure-start');
    try {
      await RegionalOffline.configure();
      if (!mounted) return;
      final token = await RegionalOffline.beginDownloadPage();
      if (!mounted) {
        await RegionalOffline.endDownloadPage(token);
        return;
      }
      pageId = token;
      _progressSub = RegionalOffline.downloadProgress.listen((values) {
        if (!mounted) return;
        final changed =
            values.any((p) => progress[p.regionId]?.state != p.state);
        final disappeared =
            progress.keys.any((id) => !values.any((p) => p.regionId == id));
        setState(() {
          progress
            ..clear()
            ..addEntries(values.map((p) => MapEntry(p.regionId, p)));
        });
        if (changed)
          record('download-state',
              values.map((p) => '${p.regionId}:${p.state.name}').join(','));
        if (disappeared ||
            values.any(
                (p) => p.state == RegionalOfflineDownloadState.completed)) {
          unawaited(refreshInstalled());
        }
      }, onError: _failure);
      _previewSub = RegionalOffline.previewBundleImportStatus.listen((value) {
        if (!mounted) return;
        final changed =
            preview?.previewBundleReady != value.previewBundleReady ||
                preview?.lastErrorCode != value.lastErrorCode;
        setState(() => preview = value);
        if (changed)
          record(
              'preview',
              value.previewBundleReady
                  ? 'ready'
                  : value.lastErrorCode ?? 'preparing');
      }, onError: _failure);
      setState(() => configured = true);
      record('configure-complete');
      await refreshInstalled();
    } catch (value) {
      _failure(value);
    } finally {
      if (mounted) setState(() => configuring = false);
    }
  }

  Future<void> refreshInstalled() async {
    try {
      final values = await RegionalOffline.listInstalledRegions();
      if (mounted) setState(() => installed = values);
    } catch (value) {
      _failure(value);
    }
  }

  Future<void> refreshCatalog() async {
    if (loadingCatalog || !configured) return;
    setState(() {
      loadingCatalog = true;
      error = null;
    });
    record('catalog-start');
    try {
      final values =
          (await RegionalOffline.fetchRegionList(country: _country.text))
              .toList();
      values.sort((a, b) => a.totalSize.compareTo(b.totalSize));
      if (!mounted) return;
      setState(() {
        catalog = values;
        if (!values.any((p) => p.regionId == selected?.regionId)) {
          selected = values.isEmpty ? null : values.first;
        }
      });
      record('catalog-complete', values.length);
    } catch (value) {
      _failure(value);
    } finally {
      if (mounted) setState(() => loadingCatalog = false);
    }
  }

  Future<void> download(int id) async {
    try {
      await RegionalOffline.downloadRegion(id);
      record('download-accepted', id);
    } catch (value) {
      _failure(value);
    }
  }

  Future<void> control(int id, RegionalOfflineDownloadAction action) async {
    try {
      await RegionalOffline.controlDownload(id, action);
      record('download-${action.name}', id);
      await refreshInstalled();
    } catch (value) {
      _failure(value);
    }
  }

  Future<void> focus(int id) async {
    try {
      record('focus', await map?.focusPreviewRegion(id));
    } catch (value) {
      _failure(value);
    }
  }

  Future<void> _installTrack(int epoch) async {
    final controller = map;
    if (controller == null) return;
    bool active() =>
        mounted &&
        epoch == _styleEpoch &&
        controller == map &&
        !controller.disposed;
    try {
      await controller.addSource(
          'offline-test-route',
          GeojsonSourceProperties(lineMetrics: true, data: {
            'type': 'FeatureCollection',
            'features': [
              {
                'type': 'Feature',
                'properties': <String, dynamic>{},
                'geometry': {
                  'type': 'LineString',
                  'coordinates': track.points
                      .map((p) => [p.longitude, p.latitude])
                      .toList()
                },
              }
            ],
          }));
      if (!active()) return;
      await controller.addLineLayer(
          'offline-test-route',
          'offline-test-route-line',
          const LineLayerProperties(
            lineWidth: 7,
            lineGradient: [
              'interpolate',
              ['linear'],
              ['line-progress'],
              0,
              '#1778ee',
              1,
              '#1778ee'
            ],
            lineTrimOffset: [0.0, 0.0],
            lineTrimColor: '#9fa8b5',
          ));
      if (!active()) return;
      _vehicle = await controller.addCircle(CircleOptions(
        geometry: track.position(fraction),
        circleRadius: 8,
        circleColor: '#ff7f00',
        circleStrokeColor: '#ffffff',
        circleStrokeWidth: 2,
      ));
      if (!active()) return;
      setState(() => routeReady = true);
      record('route-ready', track.name);
      await seek(fraction);
    } catch (value) {
      if (active()) _failure(value);
    }
  }

  Future<void> seek(double value) async {
    if (!mounted) return;
    setState(() => fraction = value.clamp(0.0, 1.0));
    if (_writingPlayback || !routeReady || map == null) return;
    _writingPlayback = true;
    final epoch = _styleEpoch;
    double? applied;
    try {
      while (mounted &&
          routeReady &&
          epoch == _styleEpoch &&
          applied != fraction) {
        applied = fraction;
        final position = track.position(applied);
        await map!.setLineLayerProperties('offline-test-route-line',
            LineLayerProperties(lineTrimOffset: [0.0, applied]));
        if (!mounted || epoch != _styleEpoch) return;
        final vehicle = _vehicle;
        if (vehicle != null)
          await map!.updateCircle(vehicle, CircleOptions(geometry: position));
        if (!mounted || epoch != _styleEpoch) return;
        if (following)
          await map!.moveCamera(CameraUpdate.newLatLngZoom(position, 15));
      }
    } catch (value) {
      if (mounted && epoch == _styleEpoch) _failure(value);
    } finally {
      _writingPlayback = false;
      if (mounted && routeReady && epoch != _styleEpoch) {
        unawaited(seek(fraction));
      }
    }
  }

  void setPlaying(bool enabled) {
    _timer?.cancel();
    if (!mounted) return;
    setState(() => playing = enabled);
    if (enabled) {
      if (fraction >= 1) unawaited(seek(0));
      _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted || !routeReady) return;
        if (fraction >= 1) {
          setPlaying(false);
          return;
        }
        unawaited(seek(fraction + 0.005));
      });
    }
  }

  Future<void> reloadStyle() async {
    if (map == null) return;
    setState(() => routeReady = false);
    try {
      await map!.setStyleType(
          styleLoads.isEven ? NBMapStyleType.bright : NBMapStyleType.night);
    } catch (value) {
      _failure(value);
    }
  }

  void remountMap() {
    setPlaying(false);
    _styleEpoch++;
    setState(() {
      map = null;
      routeReady = false;
      _vehicle = null;
      mapMount++;
    });
    record('map-remount', mapMount);
  }

  void selectTrack(PlaybackTrack value) {
    setPlaying(false);
    setState(() {
      track = value;
      fraction = 0;
    });
    remountMap();
  }

  Future<String?> snapshot() async {
    try {
      final path =
          await map?.takeSnapshot(SnapshotOptions(width: 320, height: 240));
      record('snapshot', path == null ? 'empty' : 'created');
      return path;
    } catch (value) {
      _failure(value);
      return null;
    }
  }

  Map<String, Object?> get report => {
        'sdk': {'ios': '2.3.3', 'android': '3.3.1'},
        'configured': configured,
        'styleLoads': styleLoads,
        'routeReady': routeReady,
        'installed': installed
            .map((p) => {'regionId': p.regionId, 'allTarsOk': p.allTarsOk})
            .toList(),
        'events': List.of(events),
      };

  @override
  void dispose() {
    _styleEpoch++;
    _timer?.cancel();
    unawaited(_progressSub?.cancel());
    unawaited(_previewSub?.cancel());
    final token = pageId;
    if (token != null)
      unawaited(
          RegionalOffline.endDownloadPage(token).catchError((Object _) {}));
    _country.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: widget.showAppBar
            ? AppBar(title: const Text('Offline Maps & Route Playback'))
            : null,
        body: Column(children: [
          SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.36,
              child: _mapView()),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                'Map: ${map == null ? "creating" : "created"} · Styles: $styleLoads · Offline: ${configured ? "configured" : configuring ? "configuring" : "not configured"} · Preview: ${preview?.previewBundleReady == true ? "ready" : "preparing"}',
                key: const ValueKey('offline-test-status'),
                style: const TextStyle(fontSize: 12),
              )),
          if (error != null)
            Text('Offline/operation error: $error',
                style: const TextStyle(color: Colors.red)),
          const TabBar(tabs: [
            Tab(text: 'Downloads'),
            Tab(text: 'Playback'),
            Tab(text: 'Checks')
          ]),
          Expanded(
              child:
                  TabBarView(children: [_downloads(), _playback(), _checks()])),
        ]),
      ));

  Widget _mapView() {
    final generation = mapMount;
    return NBMap(
      key: ValueKey(mapMount),
      initialCameraPosition:
          CameraPosition(target: track.points.first, zoom: 13),
      styleType: NBMapStyleType.bright,
      styleString: widget.styleString,
      trackCameraPosition: true,
      onMapCreated: (value) {
        if (!mounted || generation != mapMount) return;
        map = value;
        record('map-created');
      },
      onStyleLoadedCallback: () {
        if (!mounted || generation != mapMount) return;
        styleLoads++;
        routeReady = false;
        _vehicle = null;
        final epoch = ++_styleEpoch;
        record('style-loaded', styleLoads);
        unawaited(_installTrack(epoch));
      },
      onMapIdle: () {
        if (!mounted || generation != mapMount) return;
        mapIdleEvents++;
      },
    );
  }

  Widget _downloads() => Column(children: [
        Wrap(children: [
          for (var i = 0; i < PlaybackTrack.presets.length; i++)
            TextButton(
                onPressed: configured
                    ? () {
                        selectTrack(PlaybackTrack.presets[i]);
                        unawaited(download([6980, 3474, 7242][i]));
                      }
                    : null,
                child: Text('Download ${PlaybackTrack.presets[i].name}')),
        ]),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _country,
                  decoration: const InputDecoration(
                      labelText: 'Country (English; blank for all)'))),
          TextButton(
              onPressed: configured && !loadingCatalog ? refreshCatalog : null,
              child: Text(loadingCatalog ? 'Loading' : 'Load catalog')),
        ]),
        Expanded(
            child: ListView.builder(
                itemCount: installed.length + catalog.length,
                itemBuilder: (context, index) {
                  if (index < installed.length) {
                    final item = installed[index];
                    return ListTile(
                        title: Text('Installed: ${item.displayName}'),
                        subtitle: Text(
                            '${item.regionId} · Complete: ${item.allTarsOk}'),
                        trailing:
                            PopupMenuButton<RegionalOfflineDownloadAction>(
                                onSelected: (action) =>
                                    control(item.regionId, action),
                                itemBuilder: (_) =>
                                    RegionalOfflineDownloadAction.values
                                        .map((action) => PopupMenuItem(
                                            value: action,
                                            child: Text(action.name)))
                                        .toList()),
                        onTap: () => focus(item.regionId));
                  }
                  final item = catalog[index - installed.length];
                  final task = progress[item.regionId];
                  return ListTile(
                      selected: selected?.regionId == item.regionId,
                      title: Text(item.name),
                      subtitle: Text(
                          '${item.regionId} · ${(item.totalSize / 1048576).toStringAsFixed(1)} MB${task == null ? "" : " · ${task.state.name} ${task.percent}%"}'),
                      onTap: () => setState(() => selected = item),
                      trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => download(item.regionId)));
                })),
        if (selected != null)
          Wrap(
              children: RegionalOfflineDownloadAction.values
                  .map((action) => TextButton(
                      onPressed: () => control(selected!.regionId, action),
                      child: Text(action.name)))
                  .toList()),
      ]);

  Widget _playback() => ListView(padding: const EdgeInsets.all(12), children: [
        const Text('Replays a preset track without calculating offline routes. '
            'Download a region covering the track, then disable Wi-Fi and '
            'mobile data to verify offline playback.'),
        DropdownButton<PlaybackTrack>(
            value: track,
            isExpanded: true,
            items: [
              ...PlaybackTrack.presets,
              if (!PlaybackTrack.presets.contains(track)) track,
            ]
                .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                .toList(),
            onChanged: (value) {
              if (value != null) selectTrack(value);
            }),
        Slider(
            value: fraction,
            onChanged: routeReady ? (value) => unawaited(seek(value)) : null),
        Text('Playback progress: ${(fraction * 100).toStringAsFixed(1)}%'),
        SwitchListTile(
            title: const Text('Follow camera'),
            value: following,
            onChanged: (value) => setState(() => following = value)),
        Wrap(children: [
          ElevatedButton(
              onPressed: routeReady ? () => setPlaying(!playing) : null,
              child: Text(playing ? 'Pause playback' : 'Start playback')),
          TextButton(
              onPressed: routeReady ? () => seek(0) : null,
              child: const Text('Reset playback')),
        ]),
      ]);

  Widget _checks() => ListView(padding: const EdgeInsets.all(12), children: [
        const Text('The SDK manages database storage. Map creation does not '
            'wait for offline initialization or resource preloading.'),
        Wrap(children: [
          TextButton(
              onPressed: configuring ? null : configureOffline,
              child: const Text('Configure offline')),
          TextButton(
              onPressed: configured ? refreshInstalled : null,
              child: const Text('Installed regions')),
          TextButton(
              onPressed: map == null ? null : reloadStyle,
              child: const Text('Reload style')),
          TextButton(onPressed: remountMap, child: const Text('Recreate map')),
          TextButton(
              onPressed: map == null ? null : snapshot,
              child: const Text('Map snapshot')),
          TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(
                    text: const JsonEncoder.withIndent('  ').convert(report)));
                if (mounted) record('report-copied');
              },
              child: const Text('Copy test report')),
        ]),
        for (final item in events.reversed.take(40))
          Text('${item["ms"]}ms ${item["event"]} ${item["detail"]}',
              style: const TextStyle(fontSize: 11)),
      ]);
}
