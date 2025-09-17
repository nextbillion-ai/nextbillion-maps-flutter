import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

import 'package:nb_maps_flutter_example/page.dart';

class TrackCurrentLocationPage extends ExamplePage {
  const TrackCurrentLocationPage()
      : super(const Icon(Icons.place), 'TrackCurrentLocation');

  @override
  Widget build(BuildContext context) {
    return TrackCurrentLocation();
  }
}

class TrackCurrentLocation extends StatefulWidget {
  @override
  TrackCurrentLocationState createState() => TrackCurrentLocationState();
}

class TrackCurrentLocationState extends State<TrackCurrentLocation> {
  NextbillionMapController? controller;

  String locationTrackImage = "assets/symbols/location_on.png";

  void _onMapCreated(NextbillionMapController controller) {
    setState(() {
      this.controller = controller;
    });
  }

  Future<void> _onStyleLoadedCallback() async {
    controller?.updateMyLocationTrackingMode(MyLocationTrackingMode.tracking);
  }

  void _onUserLocationUpdate(UserLocation location) {
    if (kDebugMode) {
      print('${location.position.longitude}, ${location.position.latitude}');
    }
  }

  void _onCameraTrackingChanged() {
    setState(() {
      locationTrackImage = 'assets/symbols/location_off.png';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          NBMap(
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoadedCallback,
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 14.0,
            ),
            trackCameraPosition: true,
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.tracking,
            onUserLocationUpdated: _onUserLocationUpdate,
            onCameraTrackingDismissed: _onCameraTrackingChanged,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10.0, bottom: 100),
                child: GestureDetector(
                    child: Image(
                      image: AssetImage(locationTrackImage),
                      width: 28,
                      height: 28,
                    ),
                    onTap: () {
                      controller?.updateMyLocationTrackingMode(
                          MyLocationTrackingMode.tracking);
                      setState(() {
                        locationTrackImage = 'assets/symbols/location_on.png';
                      });
                    }),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
