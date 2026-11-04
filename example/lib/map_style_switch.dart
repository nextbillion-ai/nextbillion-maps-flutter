import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

import 'page.dart';

String _serverName(WellKnownTileServer server) => switch (server) {
      WellKnownTileServer.nbTomtom => 'TomTom',
      WellKnownTileServer.nbMapTiler => 'MapTiler',
      WellKnownTileServer.nbTomtomOrbis => 'TomTom Orbis',
    };

class MapStyleSwitchPage extends ExamplePage {
  MapStyleSwitchPage({
    this.initialTileServer = WellKnownTileServer.nbTomtom,
  }) : super(const Icon(Icons.map), 'Map Style Switch');

  final WellKnownTileServer initialTileServer;

  @override
  Widget build(BuildContext context) => MapStyleSwitch(
        initialTileServer: initialTileServer,
      );
}

class MapStyleSwitch extends StatefulWidget {
  const MapStyleSwitch({
    super.key,
    this.initialTileServer = WellKnownTileServer.nbTomtom,
  });

  final WellKnownTileServer initialTileServer;

  @override
  State<MapStyleSwitch> createState() => MapStyleSwitchState();
}

class MapStyleSwitchState extends State<MapStyleSwitch> {
  NextbillionMapController? mapController;
  NBMapStyleType currentStyleType = NBMapStyleType.bright;
  bool _busy = false;
  bool _styleLoaded = false;
  String _status = 'Waiting for map';

  Future<void> _applyStyle(NBMapStyleType style) async {
    final controller = mapController;
    if (controller == null || controller.disposed || _busy) return;
    setState(() {
      _busy = true;
      _styleLoaded = false;
      _status = 'Applying ${style.name}';
    });
    try {
      // The provider was selected before map creation. Cross-provider changes
      // on an existing MapView are outside this release's supported scope.
      await controller.setStyleType(style);
      if (!mounted) return;
      setState(() {
        currentStyleType = style;
        _status = _styleLoaded
            ? 'Style loaded'
            : 'Request accepted; waiting for style';
      });
    } on PlatformException catch (error) {
      if (mounted) setState(() => _status = 'Style failed: ${error.code}');
    } catch (_) {
      if (mounted) setState(() => _status = 'Style failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text('Service: ${_serverName(widget.initialTileServer)}',
                    key: const ValueKey('fixed-tile-server')),
                Row(
                  children: [
                    const Text('Style: '),
                    Expanded(
                      child: DropdownButton<NBMapStyleType>(
                        key: const ValueKey('map-style'),
                        isExpanded: true,
                        value: currentStyleType,
                        items: NBMapStyleType.values
                            .map((style) => DropdownMenuItem(
                                  value: style,
                                  child: Text(style.name),
                                ))
                            .toList(),
                        onChanged: mapController == null || _busy
                            ? null
                            : (style) {
                                if (style != null) {
                                  _applyStyle(style);
                                }
                              },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Reapply selection',
                      onPressed: mapController == null || _busy
                          ? null
                          : () => _applyStyle(currentStyleType),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                Text(_status, key: const ValueKey('switch-status')),
                const Text(
                  'Select the service on the home screen before opening a map. '
                  'This page changes styles within that service.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: NBMap(
              // Keep creation options stable: changes above use the controller.
              styleType: NBMapStyleType.bright,
              initialCameraPosition: const CameraPosition(
                  target: LatLng(1.351267, 103.843178), zoom: 14),
              onMapCreated: (controller) {
                if (!mounted) return;
                setState(() {
                  mapController = controller;
                  if (!_styleLoaded) _status = 'Waiting for style';
                });
              },
              onStyleLoadedCallback: () {
                if (!mounted) return;
                setState(() {
                  _styleLoaded = true;
                  _status = 'Style loaded';
                });
              },
            ),
          ),
        ],
      );
}
