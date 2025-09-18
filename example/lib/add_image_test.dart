import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'page.dart';

class AddImageTestPage extends ExamplePage {
  AddImageTestPage() : super(const Icon(Icons.add_photo_alternate), 'Add Image Test');

  @override
  Widget build(BuildContext context) {
    return const AddImageTestBody();
  }
}

class AddImageTestBody extends StatefulWidget {
  const AddImageTestBody();

  @override
  State<StatefulWidget> createState() => AddImageTestBodyState();
}

class AddImageTestBodyState extends State<AddImageTestBody> {
  AddImageTestBodyState();

  static const LatLng center = LatLng(12.971598, 77.594566); // Bangalore coordinates

  NextbillionMapController? controller;
  int _symbolCount = 0;
  bool _imageAdded = false;
  List<Symbol> _symbols = [];

  // Pre-defined coordinates for symbols with text (northern area)
  static final List<LatLng> _coordinatesWithText = [
    const LatLng(12.981598, 77.594566), // North Center
    const LatLng(12.985598, 77.598566), // Northeast
    const LatLng(12.977598, 77.590566), // Northwest
    const LatLng(12.989598, 77.588566), // Far Northwest
    const LatLng(12.973598, 77.600566), // Far Northeast
    const LatLng(12.991598, 77.594566), // Far North
  ];

  // Pre-defined coordinates for icon-only symbols (southern area)
  static final List<LatLng> _coordinatesIconOnly = [
    const LatLng(12.961598, 77.594566), // South Center
    const LatLng(12.957598, 77.598566), // Southeast
    const LatLng(12.965598, 77.590566), // Southwest
    const LatLng(12.953598, 77.588566), // Far Southwest
    const LatLng(12.969598, 77.600566), // Far Southeast
    const LatLng(12.949598, 77.594566), // Far South
  ];

  void _onMapCreated(NextbillionMapController controller) {
    this.controller = controller;
  }

  void _onStyleLoaded() {
    print('Style loaded - ready to add images');
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Adds the custom icon image from assets using addImage method
  Future<void> _addCustomImage() async {
    if (_imageAdded) {
      print('Image already added');
      return;
    }

    try {
      // Load image from assets
      final ByteData bytes = await rootBundle.load('assets/symbols/custom-icon.png');
      final Uint8List imageBytes = bytes.buffer.asUint8List();
      
      // Add image to map style using addImage method
      await controller!.addImage('custom-icon', imageBytes, false); // sdf = false for regular image
      
      setState(() {
        _imageAdded = true;
      });
      
      print('Custom image added successfully with name: custom-icon');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Custom image added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error adding custom image: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Adds symbols with custom icon at predefined coordinates
  Future<void> _addSymbolsWithCustomIcon() async {
    if (!_imageAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add the custom image first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Clear existing symbols first
      await _clearAllSymbols();

      // Add symbols at predefined coordinates
      final List<SymbolOptions> symbolOptionsList = [];
      final List<Map<String, dynamic>> symbolDataList = [];

      for (int i = 0; i < _coordinatesWithText.length; i++) {
        final coordinate = _coordinatesWithText[i];
        
        symbolOptionsList.add(
          SymbolOptions(
            geometry: coordinate,
            textField: 'Text ${i + 1}',
            iconImage: 'custom-icon',
            textSize: 16.0,
            textOpacity: 1.0,
            textColor: '#FF0000',
            textHaloColor: '#FFFFFF',
            textHaloWidth: 2.0,
            textOffset: Offset(0, 1.0),
            textAnchor: 'top',
          ),
        );
        
        symbolDataList.add({'id': i, 'name': 'Text ${i + 1}', 'type': 'withText'});
      }

      // Add all symbols at once
      final addedSymbols = await controller!.addSymbols(symbolOptionsList, symbolDataList);
      
      setState(() {
        _symbols = addedSymbols!;
        _symbolCount = _symbols.length;
      });

      print('Added ${_symbols.length} symbols with custom icon');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${_symbols.length} symbols with custom icon!'),
          backgroundColor: Colors.green,
        ),
      );

      // Move camera to show all points
      await _fitCameraToPoints();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding symbols: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Test with textAllowsOverlap for TomTom compatibility
  Future<void> _testTextWithOverlap() async {
    if (!_imageAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add the custom image first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Clear existing symbols first
      await _clearAllSymbols();

      // Add symbols at predefined coordinates with minimal configuration
      final List<SymbolOptions> symbolOptionsList = [];
      final List<Map<String, dynamic>> symbolDataList = [];

      for (int i = 0; i < _coordinatesWithText.length; i++) {
        final coordinate = _coordinatesWithText[i];
        
        symbolOptionsList.add(
          SymbolOptions(
            geometry: coordinate,
            textField: 'Overlap ${i + 1}', // 简单文本
            iconImage: 'custom-icon',
          ),
        );
        
        symbolDataList.add({'id': i + 300, 'name': 'Overlap ${i + 1}'});
      }

      // Add all symbols at once
      final addedSymbols = await controller!.addSymbols(symbolOptionsList, symbolDataList);
      
      setState(() {
        _symbols = addedSymbols!;
        _symbolCount = _symbols.length;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${_symbols.length} symbols with minimal config!'),
          backgroundColor: Colors.orange,
        ),
      );

      // Move camera to show all points
      await _fitCameraToPoints();
      
    } catch (e) {
      print('Error adding symbols: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding symbols: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Test version without fontNames - let style use default fonts
  Future<void> _testTextWithoutFont() async {
    if (!_imageAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add the custom image first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Clear existing symbols first
      await _clearAllSymbols();

      // Add symbols at predefined coordinates
      final List<SymbolOptions> symbolOptionsList = [];
      final List<Map<String, dynamic>> symbolDataList = [];

      for (int i = 0; i < _coordinatesWithText.length; i++) {
        final coordinate = _coordinatesWithText[i];
        
        symbolOptionsList.add(
          SymbolOptions(
            geometry: coordinate,
            textField: 'NoFont ${i + 1}',
            iconImage: 'custom-icon',
            textSize: 18.0,
            textOpacity: 1.0,
            textColor: '#0000FF',
            textHaloColor: '#FFFFFF',
            textHaloWidth: 2.0,
            textOffset: const Offset(0, 1.5),
            textAnchor: 'top',
          ),
        );
        
        symbolDataList.add({'id': i, 'name': 'NoFont ${i + 1}'});
      }

      // Add all symbols at once
      final addedSymbols = await controller!.addSymbols(symbolOptionsList, symbolDataList);
      
      setState(() {
        _symbols = addedSymbols!;
        _symbolCount = _symbols.length;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${_symbols.length} symbols without font specification!'),
          backgroundColor: Colors.blue,
        ),
      );

      // Move camera to show all points
      await _fitCameraToPoints();
      
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding symbols: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Adds symbols with custom icon at predefined coordinates (without text)
  Future<void> _addSymbolsWithCustomIconOnly() async {
    if (!_imageAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add the custom image first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Clear existing symbols first
      await _clearAllSymbols();

      // Add symbols at predefined coordinates
      final List<SymbolOptions> symbolOptionsList = [];
      final List<Map<String, dynamic>> symbolDataList = [];

      for (int i = 0; i < _coordinatesIconOnly.length; i++) {
        final coordinate = _coordinatesIconOnly[i];
        
        symbolOptionsList.add(
          SymbolOptions(
            geometry: coordinate,
            iconImage: 'custom-icon',
            // No textField - icon only, using same simple config as PlaceSymbolPage
          ),
        );
        
        symbolDataList.add({'id': i, 'name': 'Icon ${i + 1}', 'type': 'iconOnly'});
      }

      // Add all symbols at once
      final addedSymbols = await controller!.addSymbols(symbolOptionsList, symbolDataList);
      
      setState(() {
        _symbols = addedSymbols!;
        _symbolCount = _symbols.length;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${_symbols.length} symbols (icon only, no text)!'),
          backgroundColor: Colors.green,
        ),
      );

      // Move camera to show all points
      await _fitCameraToPoints();
      
    } catch (e) {
      print('Error adding symbols: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding symbols: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Fits camera to show all current symbols
  Future<void> _fitCameraToPoints() async {
    if (_symbols.isEmpty) return;

    // Get all coordinates from current symbols
    List<LatLng> allCoordinates = [];
    for (final symbol in _symbols) {
      if (symbol.options.geometry != null) {
        allCoordinates.add(symbol.options.geometry!);
      }
    }

    if (allCoordinates.isEmpty) return;

    // Calculate bounds
    double minLat = allCoordinates.first.latitude;
    double maxLat = allCoordinates.first.latitude;
    double minLng = allCoordinates.first.longitude;
    double maxLng = allCoordinates.first.longitude;

    for (final coord in allCoordinates) {
      minLat = min(minLat, coord.latitude);
      maxLat = max(maxLat, coord.latitude);
      minLng = min(minLng, coord.longitude);
      maxLng = max(maxLng, coord.longitude);
    }

    // Add some padding
    const double padding = 0.005;
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    await controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        left: 50.0,
        top: 50.0,
        right: 50.0,
        bottom: 50.0,
      ),
    );
  }

  /// Clears all symbols from the map
  Future<void> _clearAllSymbols() async {
    if (_symbols.isNotEmpty) {
      await controller!.removeSymbols(_symbols);
      setState(() {
        _symbols.clear();
        _symbolCount = 0;
      });
      
      print('Cleared all symbols');
    }
  }

  /// Resets everything - removes image and symbols
  Future<void> _resetAll() async {
    try {
      // Clear symbols first
      await _clearAllSymbols();
      
      // Remove the custom image (note: there's no removeImage method in the current API)
      // So we just reset our state flag
      setState(() {
        _imageAdded = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset completed!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during reset: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Shows information about the predefined coordinates
  void _showCoordinatesInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Predefined Coordinates'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // With Text coordinates
                  Text(
                    'With Text Coordinates (North Area)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_coordinatesWithText.length, (index) {
                    final coord = _coordinatesWithText[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        radius: 12,
                        child: Text('${index + 1}', style: const TextStyle(fontSize: 10)),
                      ),
                      title: Text('Text ${index + 1}'),
                      subtitle: Text(
                        'Lat: ${coord.latitude.toStringAsFixed(6)}\n'
                        'Lng: ${coord.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 16),
                  
                  // Icon Only coordinates
                  Text(
                    'Icon Only Coordinates (South Area)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_coordinatesIconOnly.length, (index) {
                    final coord = _coordinatesIconOnly[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal,
                        radius: 12,
                        child: Text('${index + 1}', style: const TextStyle(fontSize: 10)),
                      ),
                      title: Text('Icon ${index + 1}'),
                      subtitle: Text(
                        'Lat: ${coord.latitude.toStringAsFixed(6)}\n'
                        'Lng: ${coord.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Map widget
        Center(
          child: SizedBox(
            height: 350.0,
            child: NBMap(
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
              initialCameraPosition: const CameraPosition(
                target: center,
                zoom: 12.0,
              ),
            ),
          ),
        ),
        
        // Status information
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Image Status',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Icon(
                        _imageAdded ? Icons.check_circle : Icons.cancel,
                        color: _imageAdded ? Colors.green : Colors.red,
                      ),
                      Text(_imageAdded ? 'Added' : 'Not Added'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Symbols Count',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '$_symbolCount',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Text('symbols'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Control buttons
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Step 1: Add Image
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Step 1: Add Custom Image',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Add Custom Image'),
                            onPressed: _imageAdded ? null : _addCustomImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _imageAdded ? Colors.grey : Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Loads custom-icon.png from assets using addImage() method',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Step 2: Add Symbols
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Step 2: Add Symbols with Custom Icon',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.location_on),
                                  label: const Text('With Text'),
                                  onPressed: !_imageAdded ? null : _addSymbolsWithCustomIcon,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: !_imageAdded ? Colors.grey : Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.location_on_outlined),
                                  label: const Text('Icon Only'),
                                  onPressed: !_imageAdded ? null : _addSymbolsWithCustomIconOnly,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: !_imageAdded ? Colors.grey : Colors.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.text_fields),
                                  label: const Text('No Font'),
                                  onPressed: !_imageAdded ? null : _testTextWithoutFont,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: !_imageAdded ? Colors.grey : Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.layers_clear),
                                  label: const Text('Minimal'),
                                  onPressed: !_imageAdded ? null : _testTextWithOverlap,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: !_imageAdded ? Colors.grey : Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'With Text: ${_coordinatesWithText.length} coordinates (North)\nIcon Only: ${_coordinatesIconOnly.length} coordinates (South)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Utility buttons
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Utilities',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.info),
                                  label: const Text('Show Coordinates'),
                                  onPressed: _showCoordinatesInfo,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.fit_screen),
                                  label: const Text('Fit to Points'),
                                  onPressed: _symbols.isEmpty ? null : _fitCameraToPoints,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Clear Symbols'),
                                  onPressed: _symbols.isEmpty ? null : _clearAllSymbols,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reset All'),
                                  onPressed: _resetAll,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
