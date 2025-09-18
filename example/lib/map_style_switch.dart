import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';

import 'page.dart';

class MapStyleSwitchPage extends ExamplePage {
  MapStyleSwitchPage() : super(const Icon(Icons.map), 'Map Style Switch');

  @override
  Widget build(BuildContext context) {
    return const MapStyleSwitch();
  }
}

enum SwitchMode {
  type,
  url,
}

class MapStyleSwitch extends StatefulWidget {
  const MapStyleSwitch();

  @override
  State createState() => MapStyleSwitchState();
}

class MapStyleSwitchState extends State<MapStyleSwitch> {
  NextbillionMapController? mapController;
  NBMapStyleType currentStyleType = NBMapStyleType.bright;
  
  // Available style types for cycling
  final List<NBMapStyleType> availableStyleTypes = [
    NBMapStyleType.bright,
    NBMapStyleType.night,
    NBMapStyleType.satellite,
  ];

  // URL string switching
  List<NbDefaultStyle>? predefinedStylesList;
  String? baseUrl;
  int currentUrlIndex = 0;
  bool isLoadingPredefinedStyles = false;
  bool predefinedStylesLoadFailed = false;

  // Mode switching
  SwitchMode currentMode = SwitchMode.type;

  @override
  void initState() {
    super.initState();
    _loadPredefinedStyles();
  }

  Future<void> _loadPredefinedStyles() async {
    setState(() {
      isLoadingPredefinedStyles = true;
      predefinedStylesLoadFailed = false;
    });

    try {
      final styles = await NextBillion.predefinedStyles();
      baseUrl = await NextBillion.getBaseUri();
      setState(() {
        predefinedStylesList = styles;
        isLoadingPredefinedStyles = false;
        predefinedStylesLoadFailed = false;
      });
    } catch (e) {
      setState(() {
        isLoadingPredefinedStyles = false;
        predefinedStylesLoadFailed = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load predefined styles: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  void _onMapCreated(NextbillionMapController controller) {
    mapController = controller;
  }

  void _onStyleLoadedCallback() {
    String currentStyleName = '';
    
    if (currentMode == SwitchMode.type) {
      currentStyleName = _getStyleTypeName(currentStyleType);
    } else if (currentMode == SwitchMode.url && predefinedStylesList != null && predefinedStylesList!.isNotEmpty) {
      currentStyleName = predefinedStylesList![currentUrlIndex].name;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Style loaded: $currentStyleName"),
      backgroundColor: Theme.of(context).primaryColor,
      duration: const Duration(seconds: 1),
    ));
  }

  String _getStyleTypeName(NBMapStyleType styleType) {
    switch (styleType) {
      case NBMapStyleType.bright:
        return 'Bright';
      case NBMapStyleType.night:
        return 'Night';
      case NBMapStyleType.satellite:
        return 'Satellite';
    }
  }

  String _getModeName(SwitchMode mode) {
    switch (mode) {
      case SwitchMode.type:
        return 'Type';
      case SwitchMode.url:
        return 'URL';
    }
  }

  void _switchMode() {
    setState(() {
      currentMode = currentMode == SwitchMode.type ? SwitchMode.url : SwitchMode.type;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Switched to ${_getModeName(currentMode)} mode"),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 1),
    ));
  }

  void _switchToNextStyle() {
    if (mapController == null) return;
    
    if (currentMode == SwitchMode.type) {
      _switchToNextType();
    } else if (currentMode == SwitchMode.url) {
      _switchToNextUrl();
    }
  }

  void _switchToPreviousStyle() {
    if (mapController == null) return;
    
    if (currentMode == SwitchMode.type) {
      _switchToPreviousType();
    } else if (currentMode == SwitchMode.url) {
      _switchToPreviousUrl();
    }
  }

  void _switchToNextType() {
    // Find current index and get next style type
    final currentIndex = availableStyleTypes.indexOf(currentStyleType);
    final nextIndex = (currentIndex + 1) % availableStyleTypes.length;
    final nextStyleType = availableStyleTypes[nextIndex];
    
    setState(() {
      currentStyleType = nextStyleType;
    });
    
    // Use controller to switch style type
    mapController!.setStyleType(nextStyleType);
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Switching to ${_getStyleTypeName(nextStyleType)} style..."),
      backgroundColor: Colors.blue,
      duration: const Duration(seconds: 1),
    ));
  }

  void _switchToPreviousType() {
    // Find current index and get previous style type
    final currentIndex = availableStyleTypes.indexOf(currentStyleType);
    final previousIndex = (currentIndex - 1 + availableStyleTypes.length) % availableStyleTypes.length;
    final previousStyleType = availableStyleTypes[previousIndex];
    
    setState(() {
      currentStyleType = previousStyleType;
    });
    
    // Use controller to switch style type
    mapController!.setStyleType(previousStyleType);
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Switching to ${_getStyleTypeName(previousStyleType)} style..."),
      backgroundColor: Colors.blue,
      duration: const Duration(seconds: 1),
    ));
  }

  void _switchToNextUrl() {
    if (mapController == null || predefinedStylesList == null || predefinedStylesList!.isEmpty) return;
    
    final nextIndex = (currentUrlIndex + 1) % predefinedStylesList!.length;
    final nextStyle = predefinedStylesList![nextIndex];
    
    setState(() {
      currentUrlIndex = nextIndex;
    });

    // Use the controller to switch the style URL
    // On Android, the base URL must be prepended to the style URL
    String mapUrl = Platform.isAndroid ? baseUrl! + nextStyle.url : nextStyle.url;
    print("mapUrl : " + mapUrl);
    mapController!.setStyleString(mapUrl);
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Switching to ${nextStyle.name} (v${nextStyle.version})..."),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 1),
    ));
  }

  void _switchToPreviousUrl() {
    if (mapController == null || predefinedStylesList == null || predefinedStylesList!.isEmpty) return;
    
    final previousIndex = (currentUrlIndex - 1 + predefinedStylesList!.length) % predefinedStylesList!.length;
    final previousStyle = predefinedStylesList![previousIndex];
    
    setState(() {
      currentUrlIndex = previousIndex;
    });
    
    // Use controller to switch style string
    mapController!.setStyleString(previousStyle.url);
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Switching to ${previousStyle.name} (v${previousStyle.version})..."),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 1),
    ));
  }

  String _getCurrentStyleName() {
    if (currentMode == SwitchMode.type) {
      return _getStyleTypeName(currentStyleType);
    } else if (currentMode == SwitchMode.url) {
      if (isLoadingPredefinedStyles) {
        return 'Loading...';
      } else if (predefinedStylesLoadFailed) {
        return 'Failed to load';
      } else if (predefinedStylesList != null && predefinedStylesList!.isNotEmpty) {
        return predefinedStylesList![currentUrlIndex].name;
      } else {
        return 'No URLs';
      }
    }
    return 'Unknown';
  }

  Color _getCurrentModeColor() {
    if (currentMode == SwitchMode.type) {
      return Colors.blue;
    } else if (currentMode == SwitchMode.url) {
      if (predefinedStylesLoadFailed) {
        return Colors.red;
      } else {
        return Colors.green;
      }
    }
    return Colors.grey;
  }

  bool _isUrlModeEnabled() {
    return !isLoadingPredefinedStyles && !predefinedStylesLoadFailed && 
           predefinedStylesList != null && predefinedStylesList!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode Switch Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: "mode_switch",
                onPressed: _isUrlModeEnabled() ? _switchMode : null,
                mini: true,
                backgroundColor: _getCurrentModeColor(),
                child: Icon(
                  currentMode == SwitchMode.type ? Icons.link : Icons.style,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Mode Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getCurrentModeColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getModeName(currentMode),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Style Controls
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Previous style button
                  FloatingActionButton(
                    heroTag: "previous_style",
                    onPressed: _switchToPreviousStyle,
                    mini: true,
                    backgroundColor: _getCurrentModeColor(),
                    child: const Icon(Icons.keyboard_arrow_up),
                  ),
                  // Current style indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: isLoadingPredefinedStyles
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _getCurrentStyleName(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                  // Next style button
                  FloatingActionButton(
                    heroTag: "next_style",
                    child: const Icon(Icons.keyboard_arrow_down),
                    onPressed: _switchToNextStyle,
                    mini: true,
                    backgroundColor: _getCurrentModeColor(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        // Add swipe gesture for style switching
        onHorizontalDragEnd: (DragEndDetails details) {
          if (details.primaryVelocity! > 0) {
            // Swipe right - go to previous style
            _switchToPreviousStyle();
          } else if (details.primaryVelocity! < 0) {
            // Swipe left - go to next style
            _switchToNextStyle();
          }
        },
        child: NBMap(
          styleType: currentStyleType,
          onMapCreated: _onMapCreated,
          initialCameraPosition: const CameraPosition(
            target: LatLng(1.351267, 103.843178),
            zoom: 14
          ),
          onStyleLoadedCallback: _onStyleLoadedCallback,
          myLocationTrackingMode: MyLocationTrackingMode.tracking,
          myLocationEnabled: true,
          trackCameraPosition: true,
        ),
      ),
    );
  }
}
