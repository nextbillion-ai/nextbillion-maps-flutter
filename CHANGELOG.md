## v3.0.0, Sep 18, 2025
### Major Features
* **Map Style Switching**: Add comprehensive support for dynamic map style switching
  - Add `WellKnownTileServer` enum for TomTom and MapTiler tile servers
  - Add `NBMapStyleType` enum for bright, night, and satellite styles
  - Add `NbDefaultStyle` class for style configuration with name, URL, and version
  - Implement `getPredefinedMapStyles()` method to fetch available styles from tile server
  - Implement `setMapStyleType()` method for programmatic style switching
  - Add style switching example page with both type-based and URL-based switching

* **iOS Metal Rendering**: Major performance upgrade for iOS platform
  - Migrate to Metal-based rendering engine (NextBillionMap 2.0.1)
  - Significant performance improvements over OpenGL-based rendering
  - Better GPU utilization and reduced battery consumption
  - Enhanced graphics quality and smoother animations
  - Support for advanced iOS graphics capabilities

### API Enhancements
* **NextBillion Configuration**: Add new configuration methods
  - Add `getBaseUri()` and `setBaseUri()` methods for custom tile server configuration
  - Add support for dynamic tile server switching
  - Improve API flexibility for custom deployment scenarios

### Bug Fixes
* **Camera Updates**: Fix critical camera operation issues
  - Fix typo in Android `Convert.java`: "zoozmBy" → "zoomBy" 
  - Fix `zoomBy` camera update with focus point support
  - Fix `scrollBy` method return value handling
  - Resolve `IllegalArgumentException` when using `zoomBy` with focus coordinates

### Testing & Quality
* **Test Coverage**: Improve test reliability and coverage
  - Fix Mockito test configuration for `updateMapOptions` method
  - Update mock method channel to use `invokeMapMethod` instead of `invokeMethod`
  - Add comprehensive test coverage for new map style features
  - Fix CI/CD pipeline issues and Flutter version compatibility

### Development & Tooling
* **Build System**: Update build configurations
  - Update Android Gradle Plugin to 8.9.2 for better compatibility
  - Update Gradle wrapper to support newer Java versions
  - Fix lint issues across Android and iOS native code
  - Update Flutter version requirements to 3.24.0+
  - Degrade Mockito version for better compatibility

### Example Application
* **Map Style Demo**: Add comprehensive style switching demonstration
  - New `MapStyleSwitchPage` with dual-mode switching (type vs URL)
  - Real-time style preview and switching capabilities
  - Style loading status indicators and error handling
  - Support for both predefined and custom style URLs

### Breaking Changes
* **Version Bump**: Major version increase to 3.0.0
  - Updated minimum Flutter version to 3.24.0
  - Updated Dart SDK requirement to >=3.5.0 <4.0.0
  - Some internal API changes for improved type safety

* **iOS Metal Migration**: Important iOS compatibility notes
  - iOS SDK upgraded to NextBillionMap 2.0.1 (Metal-based)
  - Requires iOS 12+ for Metal rendering support
  - May require testing on iOS devices to verify Metal compatibility
  - OpenGL-based rendering is no longer supported on iOS

### Platform Support
* **iOS Metal Migration**: Major iOS rendering engine upgrade
  - Migrate iOS SDK from NextBillionMap 1.1.5 to 2.0.0
  - Transition from OpenGL to Metal rendering engine for improved performance
  - Enhanced GPU utilization and reduced CPU overhead on iOS devices
  - Better graphics performance and smoother map rendering
  - Improved memory management and power efficiency
  - Support for advanced iOS graphics features and optimizations

* **Android SDK Update**: Update Android native SDK
  - Update Android SDK from 1.2.0 to 1.3.0-beta.2
  - Enhanced tile server configuration capabilities
  - Improved performance and stability

* **Cross-Platform**: Enhanced platform implementations
  - Improved iOS style switching implementation with Metal support
  - Enhanced Android tile server configuration
  - Better error handling across both platforms
  - Unified API experience despite different underlying rendering engines

## v2.3.0, Aug 28
* **Encoded Geometry Support**: Add support for Google polyline encoded geometry strings in LineOptions
  - Add `encodedGeometry` and `encodedGeometryPrecision` fields to LineOptions for efficient route rendering
  - Implement PolylineDecoder for both Android and iOS platforms to handle encoded geometry decoding
  - Support for Google's polyline encoding algorithm with configurable precision levels
  - Significant performance improvement for routes with large numbers of coordinates

## v2.2.0, Jun 26, 2025
* Update Android native SDK to 1.2.0 , There're some lint issue fix on this version

## v2.1.0, May 14, 2025
* Update Android maps dependency to 1.1.7 to fix error
  - Error logs :
  - drawable/nbmap_user_icon_shadow has unresolved theme attributes! Consider using Resources.getDrawable(int, Theme) or Context.getDrawable(int). W/Resources(27021): java.lang.RuntimeException

## v2.0.0, Apr 15, 2025
* Update project to support flutter 3.29, Fixed PluginRegistry.Registrar issue
* resolved lint issues, updated description of the library

## v1.2.0, Dec 16, 2024
* Adapting to Android Gradle Plugin 8.0 Without Using the AGP Upgrading Assistant

## v1.1.0, Nov 28, 2024
* Update Android NB Maps SDK to 1.1.5 
* Adapt to Android Gradle Plugin 8.0
* Upgrade the compile SDK version to 34 to support Flutter SDK 3.24.0+

## v1.0.0, Sept 5, 2024
* Pinned `NextBillionMap` dependency to version `1.1.5`.

## v0.4.3, Sep 4, 2024
* Update Android NB Maps SDK to 1.1.4 and Update iOS NB Maps framework to 1.1.5
  * Modify user agent for Android and iOS
  * Add cross-platform info into the native user agent

## v0.4.2, June 6, 2024
* Update Android NB Maps SDK to 1.1.3 and Update iOS NB Maps framework to 1.1.4

## v0.4.1, June 5, 2024
* Add setUserId method to NextBillion
* Add getUserId method to NextBillion
* Add getNbId method to NextBillion
## v0.4.0, May 29, 2024
* Remove state check exception when calling methods of NextbillionMapController after the controller is disposed

## v0.3.5, May 7, 2024
* Add result for NextBillion methods

## v0.3.4, May 7, 2024
* Add await for some methods in controller
* Support obtaining the disposed status from the controller

## v0.3.2, Apr 29, 2024
* Update Android NB Maps SDK to 1.1.0
* Update iOS NB Maps framework to 1.1.0

## v0.3.1, Apr 24, 2024
* Throw an exception when calling methods of NextbillionMapController after the controller is disposed

## v0.3.0, Nov 8, 2023
* Update Android NB Maps SDK to 1.0.3

## v0.2.0, Sept 26, 2023
* Update iOS NB Maps framework to 1.0.3
* Update Android NB Maps SDK to 1.0.2
* Support to fit camera into bounds with multi points

## v0.1.6, Sept 15, 2023
* Fix the animateCamera issue
  * When calling controller.animateCamera() within onStyleLoadedCallback 

## v0.1.5, Aug 17, 2023
* Update Android NB Maps SDK to 1.0.0
* Update the default map style

## v0.1.4, Aug 16, 2023
* Update iOS NB Maps framework to 1.0.2
* Support to change the base url of map style url
* Update the default map style

## v0.1.0, July 20, 2023
* Display MapView
  * Camera position
  * Map Click Callback
  * OnMapLongClickCallback
  * MapView Created callback
  * Map Style loaded callback
* Map Options
  * Map Style String
  * Enable Map Compass
  * Enable zoom/scroll/tilt/rotate gestures
  * Enable User Location
  * Config Location Tracking Mode
  * Config Location Render Mode
* Location Component
  * Tracking Current location
  * Get Current location
  * OnLocationUpdate Callback
* Camera API
  * Animate Camera
  * Move Camera
  * OnCameraTrackingDismissedCallback
  * OnCameraTrackingChangedCallback
  * OnCameraIdleCallback
* Annotations View
  * Symbol annotation
  * Line annotation
  * Fill annotation
  * Circle annotation
  * Add Asset Image Symbol
* Query Features
* Customize source & layers
  * GeoJson Source
  * Image Source
  * Raster Source
  * Vector Source
  * Hillshade Layer
  * Fill Layer
  * Line Layer
  * Circle Layer
  * Symbol Layer
  * Raster Layer

## v0.1.4, August 16, 2023
* Update iOS native framework version from 1.0.1 to 1.0.2