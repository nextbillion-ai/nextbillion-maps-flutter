import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

enum MarkerType {
  origin,
  destination,
}

class RouteMarker extends StatefulWidget {
  final Point<double> _initialPosition;
  final LatLng _coordinate;
  final void Function(RouteMarkerState) _addMarkerState;
  final MarkerType _markerType;

  RouteMarker(
    String key, 
    this._coordinate, 
    this._initialPosition, 
    this._addMarkerState,
    this._markerType,
  ) : super(key: Key(key));

  @override
  State<StatefulWidget> createState() {
    final state = RouteMarkerState(_initialPosition, _markerType);
    _addMarkerState(state);
    return state;
  }
}

class RouteMarkerState extends State<RouteMarker> with TickerProviderStateMixin {
  static const double _iconSize = 40.0;
  
  Point<double> _position;
  final MarkerType _markerType;

  RouteMarkerState(this._position, this._markerType);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var ratio = 1.0;

    // web does not support Platform._operatingSystem
    if (!kIsWeb) {
      // iOS returns logical pixel while Android returns screen pixel
      ratio = Platform.isIOS ? 1.0 : MediaQuery.of(context).devicePixelRatio;
    }

    return Positioned(
      left: _position.x / ratio - _iconSize / 2,
      top: _position.y / ratio - _iconSize / 2,
      child: Container(
        width: _iconSize,
        height: _iconSize,
        decoration: BoxDecoration(
          color: _markerType == MarkerType.origin ? Colors.green : Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _markerType == MarkerType.origin ? Icons.play_arrow : Icons.flag,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void updatePosition(Point<num> point) {
    setState(() {
      _position = Point<double>(point.x.toDouble(), point.y.toDouble());
    });
  }

  LatLng getCoordinate() {
    return widget._coordinate;
  }
}