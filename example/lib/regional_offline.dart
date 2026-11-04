import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

import 'page.dart';

class RegionalOfflinePage extends ExamplePage {
  const RegionalOfflinePage()
      : super(const Icon(Icons.download), 'Regional Offline');

  @override
  Widget build(BuildContext context) => const _RegionalOfflineDemo();
}

class _RegionalOfflineDemo extends StatefulWidget {
  const _RegionalOfflineDemo();
  @override
  State<_RegionalOfflineDemo> createState() => _RegionalOfflineDemoState();
}

class _RegionalOfflineDemoState extends State<_RegionalOfflineDemo> {
  final _country = TextEditingController();
  final _progress = <int, RegionalOfflineDownloadProgress>{};
  List<RegionalOfflineCatalogItem> _catalog = [];
  List<RegionalOfflineInstalledRegion> _installed = [];
  StreamSubscription<List<RegionalOfflineDownloadProgress>>?
      _progressSubscription;
  StreamSubscription<RegionalOfflinePreviewBundleImportStatus>?
      _previewSubscription;
  NextbillionMapController? _map;
  String? _pageId;
  String? _error;
  bool _ready = false;
  bool _loading = true;
  bool _previewReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initialize());
    });
  }

  Future<void> _initialize() async {
    try {
      await RegionalOffline.configure();
      if (!mounted) return;
      final pageId = await RegionalOffline.beginDownloadPage();
      if (!mounted) {
        await RegionalOffline.endDownloadPage(pageId);
        return;
      }
      _pageId = pageId;
      _progressSubscription = RegionalOffline.downloadProgress.listen((values) {
        if (!mounted) return;
        final ids = values.map((value) => value.regionId).toSet();
        final refreshInstalled =
            _progress.keys.any((id) => !ids.contains(id)) ||
                values.any((value) =>
                    value.state == RegionalOfflineDownloadState.completed);
        setState(() {
          _progress
            ..clear()
            ..addEntries(
                values.map((value) => MapEntry(value.regionId, value)));
        });
        // Completion can be transient, so installed rows remain authoritative.
        if (refreshInstalled) unawaited(_refreshInstalled());
      }, onError: _showError);
      _previewSubscription =
          RegionalOffline.previewBundleImportStatus.listen((value) {
        if (mounted) setState(() => _previewReady = value.previewBundleReady);
      }, onError: _showError);
      setState(() => _ready = true);
      await _reload();
    } catch (error) {
      _showError(error);
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    setState(() => _error = error is PlatformException
        ? error.message ?? error.code
        : error.toString());
  }

  Future<void> _refreshInstalled() async {
    try {
      final installed = await RegionalOffline.listInstalledRegions();
      if (mounted) setState(() => _installed = installed);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _refreshInstalled();
    try {
      final catalog =
          await RegionalOffline.fetchRegionList(country: _country.text);
      if (mounted) setState(() => _catalog = catalog);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download(int regionId) async {
    try {
      await RegionalOffline.downloadRegion(regionId);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _control(
      int regionId, RegionalOfflineDownloadAction action) async {
    try {
      await RegionalOffline.controlDownload(regionId, action);
      await _refreshInstalled();
    } catch (error) {
      _showError(error);
    }
  }

  @override
  void dispose() {
    unawaited(_progressSubscription?.cancel());
    unawaited(_previewSubscription?.cancel());
    final pageId = _pageId;
    if (pageId != null) {
      unawaited(RegionalOffline.endDownloadPage(pageId)
          .catchError((Object error) {}));
    }
    _country.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Regional Offline')),
        body: Column(children: [
          if (!_ready && !_loading)
            const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                    'Select TomTom on the home screen before opening this example.')),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.all(8),
                child:
                    Text(_error!, style: const TextStyle(color: Colors.red))),
          Expanded(
              child: NBMap(
            initialCameraPosition:
                const CameraPosition(target: LatLng(39, -98), zoom: 3),
            styleType: NBMapStyleType.bright,
            onMapCreated: (controller) => _map = controller,
          )),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: _country,
                        decoration: const InputDecoration(
                            labelText:
                                'Country (full English name, blank for all)'),
                        onSubmitted: (_) {
                          if (_ready && !_loading) unawaited(_reload());
                        })),
                IconButton(
                    onPressed: _ready && !_loading ? _reload : null,
                    icon: const Icon(Icons.refresh)),
              ])),
          Text(_previewReady
              ? 'Preview resources ready'
              : 'Preparing preview resources'),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
              child: ListView(children: [
            for (final region in _installed)
              ListTile(
                  leading: const Icon(Icons.offline_pin),
                  title: Text(region.displayName),
                  subtitle: Text('${region.packageCount} packages installed'),
                  onTap: () async {
                    try {
                      await _map?.focusPreviewRegion(region.regionId);
                    } catch (error) {
                      _showError(error);
                    }
                  }),
            for (final region in _catalog)
              ListTile(
                  title: Text(region.name),
                  subtitle: Text(_progress[region.regionId] == null
                      ? '${(region.totalSize / 1024 / 1024).toStringAsFixed(1)} MB'
                      : '${_progress[region.regionId]!.state.name} · ${_progress[region.regionId]!.percent}%'),
                  leading: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _download(region.regionId)),
                  trailing: PopupMenuButton<RegionalOfflineDownloadAction>(
                      onSelected: (action) => _control(region.regionId, action),
                      itemBuilder: (_) => RegionalOfflineDownloadAction.values
                          .map((action) => PopupMenuItem(
                              value: action, child: Text(action.name)))
                          .toList())),
          ])),
        ]),
      );
}
