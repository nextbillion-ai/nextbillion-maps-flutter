import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

import 'package:nb_maps_flutter_example/page.dart';

final LatLngBounds sydneyBounds = LatLngBounds(
  southwest: const LatLng(-34.022631, 150.620685),
  northeast: const LatLng(-33.571835, 151.325952),
);

class MapUiPage extends ExamplePage {
  const MapUiPage() : super(const Icon(Icons.map), 'User interface');

  @override
  Widget build(BuildContext context) {
    return const MapUiBody();
  }
}

class MapUiBody extends StatefulWidget {
  const MapUiBody();

  @override
  State<StatefulWidget> createState() => MapUiBodyState();
}

class MapUiBodyState extends State<MapUiBody> {
  MapUiBodyState();

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(-33.852, 151.211),
    zoom: 11.0,
  );

  NextbillionMapController? mapController;
  CameraPosition _position = _kInitialPosition;
  bool _isMoving = false;
  bool _compassEnabled = true;
  bool _mapExpanded = true;
  CameraTargetBounds _cameraTargetBounds = CameraTargetBounds.unbounded;
  MinMaxZoomPreference _minMaxZoomPreference = MinMaxZoomPreference.unbounded;

  // Style string can a reference to a local or remote resources.
  // On Android the raw JSON can also be passed via a styleString, on iOS this is not supported.
  bool _rotateGesturesEnabled = true;
  bool _scrollGesturesEnabled = true;
  bool? _doubleClickToZoomEnabled;
  bool _tiltGesturesEnabled = true;
  bool _zoomGesturesEnabled = true;
  bool _myLocationEnabled = true;
  bool _telemetryEnabled = true;
  MyLocationTrackingMode _myLocationTrackingMode = MyLocationTrackingMode.none;
  List<Object>? _featureQueryFilter;
  Fill? _selectedFill;

  @override
  void initState() {
    super.initState();
  }

  void _onMapChanged() {
    setState(() {
      _extractMapInfo();
    });
  }

  void _extractMapInfo() {
    final position = mapController!.cameraPosition;
    if (position != null) _position = position;
    _isMoving = mapController!.isCameraMoving;
  }

  @override
  void dispose() {
    mapController?.removeListener(_onMapChanged);
    super.dispose();
  }

  Widget _myLocationTrackingModeCycler() {
    final MyLocationTrackingMode nextType = MyLocationTrackingMode.values[
        (_myLocationTrackingMode.index + 1) %
            MyLocationTrackingMode.values.length];
    return TextButton(
      child: Text('change to $nextType'),
      onPressed: () {
        setState(() {
          _myLocationTrackingMode = nextType;
        });
      },
    );
  }

  Widget _queryFilterToggler() {
    return TextButton(
      child: Text(
          'filter zoo on click ${_featureQueryFilter == null ? 'disabled' : 'enabled'}'),
      onPressed: () {
        setState(() {
          if (_featureQueryFilter == null) {
            _featureQueryFilter = [
              "==",
              ["get", "type"],
              "zoo"
            ];
          } else {
            _featureQueryFilter = null;
          }
        });
      },
    );
  }

  Widget _mapSizeToggler() {
    return TextButton(
      child: Text('${_mapExpanded ? 'shrink' : 'expand'} map'),
      onPressed: () {
        setState(() {
          _mapExpanded = !_mapExpanded;
        });
      },
    );
  }

  Widget _compassToggler() {
    return TextButton(
      child: Text('${_compassEnabled ? 'disable' : 'enable'} compasss'),
      onPressed: () {
        setState(() {
          _compassEnabled = !_compassEnabled;
        });
      },
    );
  }

  Widget _latLngBoundsToggler() {
    return TextButton(
      child: Text(
        _cameraTargetBounds.bounds == null
            ? 'bound camera target'
            : 'release camera target',
      ),
      onPressed: () {
        setState(() {
          _cameraTargetBounds = _cameraTargetBounds.bounds == null
              ? CameraTargetBounds(sydneyBounds)
              : CameraTargetBounds.unbounded;
        });
      },
    );
  }

  Widget _zoomBoundsToggler() {
    return TextButton(
      child: Text(_minMaxZoomPreference.minZoom == null
          ? 'bound zoom'
          : 'release zoom'),
      onPressed: () {
        setState(() {
          _minMaxZoomPreference = _minMaxZoomPreference.minZoom == null
              ? const MinMaxZoomPreference(12.0, 16.0)
              : MinMaxZoomPreference.unbounded;
        });
      },
    );
  }

  Widget _rotateToggler() {
    return TextButton(
      child: Text('${_rotateGesturesEnabled ? 'disable' : 'enable'} rotate'),
      onPressed: () {
        setState(() {
          _rotateGesturesEnabled = !_rotateGesturesEnabled;
        });
      },
    );
  }

  Widget _scrollToggler() {
    return TextButton(
      child: Text('${_scrollGesturesEnabled ? 'disable' : 'enable'} scroll'),
      onPressed: () {
        setState(() {
          _scrollGesturesEnabled = !_scrollGesturesEnabled;
        });
      },
    );
  }

  Widget _doubleClickToZoomToggler() {
    final stateInfo = _doubleClickToZoomEnabled == null
        ? "disable"
        : _doubleClickToZoomEnabled!
            ? 'unset'
            : 'enable';
    return TextButton(
      child: Text('$stateInfo double click to zoom'),
      onPressed: () {
        setState(() {
          if (_doubleClickToZoomEnabled == null) {
            _doubleClickToZoomEnabled = false;
          } else if (!_doubleClickToZoomEnabled!) {
            _doubleClickToZoomEnabled = true;
          } else {
            _doubleClickToZoomEnabled = null;
          }
        });
      },
    );
  }

  Widget _tiltToggler() {
    return TextButton(
      child: Text('${_tiltGesturesEnabled ? 'disable' : 'enable'} tilt'),
      onPressed: () {
        setState(() {
          _tiltGesturesEnabled = !_tiltGesturesEnabled;
        });
      },
    );
  }

  Widget _zoomToggler() {
    return TextButton(
      child: Text('${_zoomGesturesEnabled ? 'disable' : 'enable'} zoom'),
      onPressed: () {
        setState(() {
          _zoomGesturesEnabled = !_zoomGesturesEnabled;
        });
      },
    );
  }

  Widget _myLocationToggler() {
    return TextButton(
      child: Text('${_myLocationEnabled ? 'disable' : 'enable'} my location'),
      onPressed: () {
        setState(() {
          _myLocationEnabled = !_myLocationEnabled;
        });
      },
    );
  }

  Widget _telemetryToggler() {
    return TextButton(
      child: Text('${_telemetryEnabled ? 'disable' : 'enable'} telemetry'),
      onPressed: () {
        setState(() {
          _telemetryEnabled = !_telemetryEnabled;
        });
        mapController?.setTelemetryEnabled(_telemetryEnabled);
      },
    );
  }

  Widget _visibleRegionGetter() {
    return Builder(
      builder: (context) {
        return TextButton(
          child: const Text('Get currently visible region'),
          onPressed: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(
                context); // capture context-dependent object early

            final result = await mapController!.getVisibleRegion();
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content:
                    Text("SW: ${result?.southwest} NE: ${result?.northeast}"),
              ),
            );
          },
        );
      },
    );
  }

  void _clearFill() {
    if (_selectedFill != null) {
      mapController!.removeFill(_selectedFill!);
      setState(() {
        _selectedFill = null;
      });
    }
  }

  Future<void> _drawFill(List<dynamic> features) async {
    final feature = features.cast<Map<String, dynamic>>().firstWhereOrNull((f) {
      final geometry = f['geometry'];
      if (geometry is Map<String, dynamic>) {
        return geometry['type'] == 'Polygon';
      }
      return false;
    });

    if (feature != null) {
      final geometryMap = feature['geometry'] as Map<String, dynamic>;
      final coordinates = geometryMap['coordinates'] as List<dynamic>;

      final List<List<LatLng>> geometry = coordinates
          .map((ll) => (ll as List)
              .map((l) => LatLng(
                    ((l as List)[1] as num).toDouble(),
                    (l[0] as num).toDouble(),
                  ))
              .toList())
          .toList();

      final Fill? fill = await mapController!.addFill(FillOptions(
        geometry: geometry,
        fillColor: "#FF0000",
        fillOutlineColor: "#FF0000",
        fillOpacity: 0.6,
      ));

      if (mounted) {
        setState(() {
          _selectedFill = fill;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final NBMap nbMap = NBMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: _kInitialPosition,
      trackCameraPosition: true,
      compassEnabled: _compassEnabled,
      cameraTargetBounds: _cameraTargetBounds,
      minMaxZoomPreference: _minMaxZoomPreference,
      rotateGesturesEnabled: _rotateGesturesEnabled,
      scrollGesturesEnabled: _scrollGesturesEnabled,
      tiltGesturesEnabled: _tiltGesturesEnabled,
      zoomGesturesEnabled: _zoomGesturesEnabled,
      doubleClickZoomEnabled: _doubleClickToZoomEnabled,
      myLocationEnabled: _myLocationEnabled,
      myLocationTrackingMode: _myLocationTrackingMode,
      myLocationRenderMode: MyLocationRenderMode.gps,
      onMapClick: (point, latLng) async {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final List features = await mapController!
            .queryRenderedFeatures(point, ["landuse"], _featureQueryFilter);
        _clearFill();
        if (features.isEmpty && _featureQueryFilter != null) {
          scaffoldMessenger.showSnackBar(const SnackBar(
              content: Text('QueryRenderedFeatures: No features found!')));
        } else if (features.isNotEmpty) {
          _drawFill(features);
        }
      },
      onMapLongClick: (point, latLng) async {
        if (kDebugMode) {
          print(
              "Map long press: ${point.x},${point.y}   ${latLng.latitude}/${latLng.longitude}");
        }

        final double? metersPerPixel =
            await mapController!.getMetersPerPixelAtLatitude(latLng.latitude);

        if (kDebugMode) {
          print(
              "Map long press The distance measured in meters at latitude ${latLng.latitude} is $metersPerPixel m");
        }

        final List features =
            await mapController!.queryRenderedFeatures(point, [], null);
        if (features.isNotEmpty) {
          if (kDebugMode) {
            print(features[0]);
          }
        }
      },
      onCameraTrackingDismissed: () {
        setState(() {
          _myLocationTrackingMode = MyLocationTrackingMode.none;
        });
      },
      onUserLocationUpdated: (location) {
        if (kDebugMode) {
          print(
              "new location: ${location.position}, alt.: ${location.altitude}, bearing: ${location.bearing}, speed: ${location.speed}, horiz. accuracy: ${location.horizontalAccuracy}, vert. accuracy: ${location.verticalAccuracy}");
        }
      },
    );

    final List<Widget> listViewChildren = <Widget>[];

    if (mapController != null) {
      listViewChildren.addAll(
        <Widget>[
          Text('camera bearing: ${_position.bearing}'),
          Text('camera target: ${_position.target.latitude.toStringAsFixed(4)},'
              '${_position.target.longitude.toStringAsFixed(4)}'),
          Text('camera zoom: ${_position.zoom}'),
          Text('camera tilt: ${_position.tilt}'),
          Text(_isMoving ? '(Camera moving)' : '(Camera idle)'),
          _mapSizeToggler(),
          _queryFilterToggler(),
          _compassToggler(),
          _myLocationTrackingModeCycler(),
          _latLngBoundsToggler(),
          _zoomBoundsToggler(),
          _rotateToggler(),
          _scrollToggler(),
          _doubleClickToZoomToggler(),
          _tiltToggler(),
          _zoomToggler(),
          _myLocationToggler(),
          _telemetryToggler(),
          _visibleRegionGetter(),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: SizedBox(
            width: _mapExpanded ? null : 300.0,
            height: 200.0,
            child: nbMap,
          ),
        ),
        Expanded(
          child: ListView(
            children: listViewChildren,
          ),
        )
      ],
    );
  }

  void onMapCreated(NextbillionMapController controller) {
    mapController = controller;
    mapController!.addListener(_onMapChanged);
    _extractMapInfo();

    mapController!.getTelemetryEnabled().then((isEnabled) => setState(() {
          _telemetryEnabled = isEnabled;
        }));
  }
}
