import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'route_marker.dart';
import 'page.dart';

class EncodedGeometryPage extends ExamplePage {
  EncodedGeometryPage() : super(const Icon(Icons.timeline), 'Encoded Geometry');

  @override
  Widget build(BuildContext context) {
    return const EncodedGeometryExample();
  }
}

class EncodedGeometryExample extends StatefulWidget {
  const EncodedGeometryExample({Key? key}) : super(key: key);

  @override
  State createState() => EncodedGeometryExampleState();
}

class EncodedGeometryExampleState extends State<EncodedGeometryExample> {
  NextbillionMapController? controller;
  bool _hasLine = false;
  Line? _currentLine;
  List<RouteMarker> _markers = [];
  List<RouteMarkerState> _markerStates = [];

  void _onMapCreated(NextbillionMapController controller) {
    this.controller = controller;
    controller.addListener(() {
      if (controller.isCameraMoving) {
        _updateMarkerPosition();
      }
    });
  }

  void _addMarkerState(RouteMarkerState markerState) {
    _markerStates.add(markerState);
  }

  void _updateMarkerPosition() {
    if (_markerStates.isEmpty) return;
    
    final coordinates = <LatLng>[];
    for (final markerState in _markerStates) {
      coordinates.add(markerState.getCoordinate());
    }

    controller?.toScreenLocationBatch(coordinates).then((points) {
      if (points == null) {
        return;
      }
      _markerStates.asMap().forEach((i, value) {
        _markerStates[i].updatePosition(points[i]);
      });
    });
  }

  void _onCameraIdleCallback() {
    _updateMarkerPosition();
  }

  void _onStyleLoadedCallback() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Style loaded"),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 1),
    ));
  }

  static final LatLng center = const LatLng(12.974335, 77.597575);

  static final LatLng origin = const LatLng(12.96206481, 77.56687669);

  static final LatLng destination = const LatLng(12.99150562, 77.61940507);

  /// Example encoded polyline string (represents a simple route)
  /// This is much more efficient than sending hundreds of LatLng points
  /// This example represents a simple line with a few points
  /// Encoded from coordinates: (37.7749, -122.4194) to (37.7849, -122.4094)

  static final String _encodedPolylineExample =
      "itbnAgwlxM]@C?_@DU?eAHNn@XvAE@E@KDG@EBMo@AGQ}@G[Ow@Oo@CGOa@EMGSm@gBEIGOKa@AEUu@Ik@AMUcA??AGEOCMMk@G[Kc@?W?EAKAG?SAa@Am@GmAEa@?AAUC[?EEmBE{A?CAKAKEwAC[EgAGiA?IEk@Ca@C[E]E_@Ca@?C?E@W?KF[BI@KDMDSBIL[^cA@CDOFUFYJk@BOECECGCAACCEEGKASCUBc@@]Bq@DuAHmB@U@MD{@Dq@?KH_BBc@HsADs@@WDgA?E@W@WB{@@U@Y@QB}@@M?OD{@@w@Bk@?KBm@?SBcA@Y?G?C@WAM?GAQAOCSCGCIGMOWGGMK_@]q@m@OKkBcBEC_@_@GCCCUAWGI?UEKCKEMGKG]WGGq@k@CEGEYQMEICEAQCEAUBaBTG?GAGCKEGEAAACEI?WD{B?I?IAEC]CQCSEOCKCKIWEKCIEICGCIGKEGEGEECEKMOQqAuAuF}GsBiCCEY]kByB]a@WYOQa@c@II[]W]GGIOGKGC]SEEIIGEi@_@_@[ECKIi@a@SOQQSQIKOSGGMQQU]e@QWUWKMSYw@aACCu@eACCGKKMa@s@EGCEOUKOEGy@oAKOGKGIIMa@m@ACOUW[c@q@S]CGCGCGCICM?M@}@@mB@gA@}@?sA@m@@]?IBI@K?G@EDOFg@Fc@T_BHi@N}@b@{CBOBKVoBn@cEHi@~@wFZoBGC[G[IqA[GASGWIy@UuA]ICICKEUIUIEAKCuAc@ICaA[e@KwA_@e@MiBe@YGwA[yA]}@WICOGBSP}@BOBO@MBM@M?CEOCIIMMQCCGGCA{@u@ECc@c@_@]_Au@CCy@u@CAAAACAAMKs@q@GGQOCCAAMMBEFIDMFQTkA@KRkAFa@?CBO@[?Y?IAa@CSGw@?s@IQEMCCCCAE?KBI[YEGMWYq@KQQc@CGWe@]o@KOMQUWOOGI_@[AC]YQQq@m@gA_A}@w@][MIGGa@YoAu@i@Wm@Yc@KWGGAMA@D@B@JCHEH[^KNGJICIEGCG?EAI@IAk@Ia@Ea@Ew@Iw@IUAWCw@C[?g@@e@D{BA}@@K@_@@y@Fa@DWB]DK@M@SDIB]JIB_@Nk@Va@N[Lg@R[NQFo@XeCdAw@^IDGBEIFEJCdBu@zAo@JGp@[ZMb@Ql@Ux@_@RGRIFAf@Oj@IB?";

  void _addEncodedLine() async {
    if (controller == null || _hasLine) return;

    print(
        "Flutter: Attempting to add encoded line with string: $_encodedPolylineExample");

    try {
      // Using encoded geometry - much more efficient for large datasets
      final line = await controller!.addLine(
        LineOptions(
          encodedGeometry: _encodedPolylineExample,
          encodedGeometryPrecision: 5,
          // Standard precision
          lineColor: "#FF0000",
          // Red color
          lineWidth: 4.0,
          lineOpacity: 0.8,
        ),
      );

      if (line != null) {
        _currentLine = line;
        
        // Add origin and destination markers
        await _addRouteMarkers();

        setState(() {
          _hasLine = true;
        });


        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Added encoded line with markers"),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ));
      } else {

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to add encoded line"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: $e"),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  Future<void> _addRouteMarkers() async {
    if (controller == null) return;

    // Convert coordinates to screen positions
    final coordinates = [origin, destination];
    final points = await controller!.toScreenLocationBatch(coordinates);
    
    if (points == null) return;

    setState(() {
      // Clear existing markers
      _markers.clear();
      _markerStates.clear();
      
      // Add origin marker (green)
      _markers.add(RouteMarker(
        "origin", 
        origin, 
        Point<double>(points[0].x.toDouble(), points[0].y.toDouble()),
        _addMarkerState,
        MarkerType.origin,
      ));
      
      // Add destination marker (red)
      _markers.add(RouteMarker(
        "destination", 
        destination, 
        Point<double>(points[1].x.toDouble(), points[1].y.toDouble()),
        _addMarkerState,
        MarkerType.destination,
      ));
    });
  }

  void _updateEncodedLine() async {
    if (controller == null || !_hasLine || _currentLine == null) return;

    try {
      // Alternative approach: Remove and re-add the line with new properties
      // This ensures the encoded geometry is properly processed
      await controller!.removeLine(_currentLine!);
      
      // Small delay to ensure removal is processed
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Create new line with updated properties but same encoded geometry
      final updatedLine = await controller!.addLine(
        LineOptions(
          encodedGeometry: _encodedPolylineExample, // Use original encoded string
          encodedGeometryPrecision: 5,
          lineColor: "#00FF00", // Green color
          lineWidth: 6.0,
          lineOpacity: 1.0,
        ),
      );
      
      if (updatedLine != null) {
        _currentLine = updatedLine;

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Updated line color to green"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ));
      } else {

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to update line"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error updating line: $e"),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  void _clearLines() async {
    if (controller == null) return;

    await controller!.clearLines();
    await controller!.clearSymbols();
    
    setState(() {
      _hasLine = false;
      _currentLine = null;
      _markers.clear();
      _markerStates.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Cleared all lines and markers"),
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: ${_hasLine ? "Line Added" : "No Line"}',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w500,
                    color: _hasLine ? Colors.green : Colors.grey,
                  ),
                ),
                Text(
                  'Markers: ${_markers.length}',
                  style: const TextStyle(
                      fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                NBMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: center,
                    zoom: 10,
                  ),
                  onStyleLoadedCallback: _onStyleLoadedCallback,
                  onCameraIdle: _onCameraIdleCallback,
                  myLocationEnabled: false,
                  trackCameraPosition: true,
                ),
                IgnorePointer(
                  ignoring: true,
                  child: Stack(
                    children: _markers,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _hasLine ? null : _addEncodedLine,
            heroTag: "encoded",
            backgroundColor: _hasLine ? Colors.grey : Colors.red,
            child: const Icon(Icons.timeline, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _hasLine ? _updateEncodedLine : null,
            heroTag: "update",
            backgroundColor: _hasLine ? Colors.purple : Colors.grey,
            child: const Icon(Icons.update, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _clearLines,
            heroTag: "clear",
            backgroundColor: Colors.orange,
            child: const Icon(Icons.clear, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
