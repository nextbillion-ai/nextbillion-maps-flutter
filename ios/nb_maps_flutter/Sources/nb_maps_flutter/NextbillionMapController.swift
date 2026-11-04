import Flutter
import Nbmap
import UIKit

class NextbillionMapController: NSObject, FlutterPlatformView, NGLMapViewDelegate, NextbillionMapOptionsSink,
    UIGestureRecognizerDelegate
{
    private var registrar: FlutterPluginRegistrar
    private var channel: FlutterMethodChannel?

    private var mapView: NGLMapView
    private var hasLoadedStyle = false
    private var hasDartController = false
    private var dragEnabled = true
    private var snapshotters: [UUID: NGLMapSnapshotter] = [:]
    private var snapshotResults: [UUID: FlutterResult] = [:]
    private var pendingResults: [UUID: FlutterResult] = [:]
    private var previousDragCoordinate: CLLocationCoordinate2D?
    private var originDragCoordinate: CLLocationCoordinate2D?
    private var dragFeature: NGLFeature?

    private var initialTilt: CGFloat?
    private var cameraTargetBounds: NGLCoordinateBounds?
    private var trackCameraPosition = false
    private var myLocationEnabled = false
    private var scrollingEnabled = true

    private var interactiveFeatureLayerIds = Set<String>()
    private var addedShapesByLayer = [String: NGLShape]()

    func view() -> UIView {
        return mapView
    }

    init(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        registrar: FlutterPluginRegistrar
    ) {
        mapView = NGLMapView(frame: frame)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.registrar = registrar

        super.init()
        NGLRegionalOffline.install()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshRegionalOfflineResources),
            name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshRegionalOfflineResources),
            name: Notification.Name("NGLRegionalOfflineMapDidAppearNotification"), object: mapView)

        channel = FlutterMethodChannel(
            name: "plugins.flutter.io/nbmaps_maps_\(viewId)",
            binaryMessenger: registrar.messenger()
        )
        channel!
            .setMethodCallHandler { [weak self] in self?.onMethodCall(methodCall: $0, result: $1) }

        mapView.delegate = self

        let singleTap = UITapGestureRecognizer(
            target: self,
            action: #selector(handleMapTap(sender:))
        )
        for recognizer in (mapView.gestureRecognizers ?? []) where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)

        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleMapLongPress(sender:))
        )
        for recognizer in (mapView.gestureRecognizers ?? [])
            where recognizer is UILongPressGestureRecognizer {
            longPress.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(longPress)

        if let args = args as? [String: Any] {
            Convert.interpretNextbillionMapOptions(options: args["options"], delegate: self)
            if let initialCameraPosition = args["initialCameraPosition"] as? [String: Any],
               let camera = NGLMapCamera.fromDict(initialCameraPosition, mapView: mapView),
               let zoom = initialCameraPosition["zoom"] as? Double {
                mapView.setCenter(
                    camera.centerCoordinate,
                    zoomLevel: zoom,
                    direction: camera.heading,
                    animated: false
                )
                initialTilt = camera.pitch
            }
            if let onAttributionClickOverride = args["onAttributionClickOverride"] as? Bool {
                if onAttributionClickOverride {
                    setupAttribution(mapView)
                }
            }

            if let enabled = args["dragEnabled"] as? Bool {
                dragEnabled = enabled
            }
        }
        if dragEnabled {
            let pan = UIPanGestureRecognizer(
                target: self,
                action: #selector(handleMapPan(sender:))
            )
            pan.delegate = self
            mapView.addGestureRecognizer(pan)
        }
    }

//    func removeAllForController(controller: NGLAnnotationController, ids: [String]) {
//        let idSet = Set(ids)
//        let annotations = controller.styleAnnotations()
//        controller.removeStyleAnnotations(annotations.filter { idSet.contains($0.identifier) })
//    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        channel?.setMethodCallHandler(nil)
        mapView.delegate = nil
        mapView.showsUserLocation = false
        let cancelled = FlutterError(code: "MAP_DISPOSED", message: "The map has been disposed", details: nil)
        pendingResults.values.forEach { $0(cancelled) }
        snapshotters.values.forEach { $0.cancel() }
    }

    @objc private func refreshRegionalOfflineResources() {
        NGLRegionalOffline.onMapViewWillAppear()
    }

    func gestureRecognizer(
        _: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    func onMethodCall(methodCall: FlutterMethodCall, result originalResult: @escaping FlutterResult) {
        let requestId = UUID()
        pendingResults[requestId] = originalResult
        let result: FlutterResult = { [weak self] value in
            guard let reply = self?.pendingResults.removeValue(forKey: requestId) else { return }
            reply(value)
        }
        switch methodCall.method {
        case "map#waitForMap":
            // The platform view already exists. Style/network failure must not
            // prevent Dart from obtaining a controller and changing the style.
            let notifyStyle = hasLoadedStyle && !hasDartController
            hasDartController = true
            result(nil)
            if notifyStyle { channel?.invokeMethod("map#onStyleLoaded", arguments: nil) }
        case "map#update":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            if let options = arguments["options"] as? [String: Any],
               let styleString = options["styleString"] as? String,
               let error = inlineStyleJSONError(styleString) {
                result(error)
                return
            }
            Convert.interpretNextbillionMapOptions(options: arguments["options"], delegate: self)
            if let camera = getCamera() {
                result(camera.toDict(mapView: mapView))
            } else {
                result(nil)
            }
        case "map#invalidateAmbientCache":
            NGLOfflineStorage.shared.invalidateAmbientCache { error in
                if let error = error {
                    let native = error as NSError
                    result(FlutterError(code: "CACHE_ERROR", message: native.localizedDescription,
                        details: ["domain": native.domain, "nativeCode": native.code]))
                } else {
                    result(nil)
                }
            }
        case "map#updateMyLocationTrackingMode":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            if let myLocationTrackingMode = arguments["mode"] as? UInt,
               let trackingMode = NGLUserTrackingMode(rawValue: myLocationTrackingMode) {
                setMyLocationTrackingMode(myLocationTrackingMode: trackingMode)
            }
            result(nil)
        case "map#matchMapLanguageWithDeviceDefault":
            if let style = mapView.style {
                style.localizeLabels(into: nil)
            }
            result(nil)
        case "map#updateContentInsets":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }

            if let bounds = arguments["bounds"] as? [String: Any],
               let top = bounds["top"] as? CGFloat,
               let left = bounds["left"] as? CGFloat,
               let bottom = bounds["bottom"] as? CGFloat,
               let right = bounds["right"] as? CGFloat,
               let animated = arguments["animated"] as? Bool {
                mapView.setContentInset(
                    UIEdgeInsets(top: top, left: left, bottom: bottom, right: right),
                    animated: animated
                ) {
                    result(nil)
                }
            } else {
                result(nil)
            }
        case "locationComponent#getLastLocation":
            var reply = [String: NSObject]()
            if let loc = mapView.userLocation?.location?.coordinate {
                reply["latitude"] = loc.latitude as NSObject
                reply["longitude"] = loc.longitude as NSObject
                result(reply)
            } else {
                result(nil)
            }
        case "map#setMapLanguage":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            if let localIdentifier = arguments["language"] as? String, let style = mapView.style {
                let locale = Locale(identifier: localIdentifier)
                style.localizeLabels(into: locale)
            }
            result(nil)
        case "map#queryRenderedFeatures":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            var styleLayerIdentifiers: Set<String>?
            if let layerIds = arguments["layerIds"] as? [String] {
                styleLayerIdentifiers = Set<String>(layerIds)
            }
            var filterExpression: NSPredicate?
            if let filter = arguments["filter"] as? [Any] {
                filterExpression = NSPredicate(nglJSONObject: filter)
            }
            var reply = [String: NSObject]()
            var features: [NGLFeature] = []
            if let xValue = arguments["x"] as? Double, let yValue = arguments["y"] as? Double {
                features = mapView.visibleFeatures(
                    at: CGPoint(x: xValue, y: yValue),
                    styleLayerIdentifiers: styleLayerIdentifiers,
                    predicate: filterExpression
                )
            }
            if let top = arguments["top"] as? Double,
               let bottom = arguments["bottom"] as? Double,
               let left = arguments["left"] as? Double,
               let right = arguments["right"] as? Double {
                features = mapView.visibleFeatures(
                    in: CGRect(x: left, y: top, width: right - left, height: bottom - top),
                    styleLayerIdentifiers: styleLayerIdentifiers,
                    predicate: filterExpression
                )
            }
            var featuresJson = [String]()
            for feature in features {
                let dictionary = feature.geoJSONDictionary()
                if let theJSONData = try? JSONSerialization.data(
                    withJSONObject: dictionary,
                    options: []
                ),
                    let theJSONText = String(data: theJSONData, encoding: .utf8) {
                    featuresJson.append(theJSONText)
                }
            }
            reply["features"] = featuresJson as NSObject
            result(reply)
        case "map#setTelemetryEnabled":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            let telemetryEnabled = arguments["enabled"] as? Bool
            UserDefaults.standard.set(telemetryEnabled, forKey: "NGLNbMapsMetricsEnabled")
            result(nil)
        case "map#getTelemetryEnabled":
            let telemetryEnabled = UserDefaults.standard.bool(forKey: "NGLNbMapsMetricsEnabled")
            result(telemetryEnabled)
        case "map#getVisibleRegion":
            var reply = [String: NSObject]()
            let visibleRegion = mapView.visibleCoordinateBounds
            reply["sw"] = [visibleRegion.sw.latitude, visibleRegion.sw.longitude] as NSObject
            reply["ne"] = [visibleRegion.ne.latitude, visibleRegion.ne.longitude] as NSObject
            result(reply)
        case "map#toScreenLocation":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let latitude = arguments["latitude"] as? Double else { invalidArguments(result); return }
            guard let longitude = arguments["longitude"] as? Double else { invalidArguments(result); return }
            let latlng = CLLocationCoordinate2DMake(latitude, longitude)
            let returnVal = mapView.convert(latlng, toPointTo: mapView)
            var reply = [String: NSObject]()
            reply["x"] = returnVal.x as NSObject
            reply["y"] = returnVal.y as NSObject
            result(reply)
        case "map#toScreenLocationBatch":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let data = arguments["coordinates"] as? FlutterStandardTypedData else { invalidArguments(result); return }
            guard data.type == .float64, data.elementCount % 2 == 0 else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected paired Float64 coordinates", details: nil))
                return
            }
            // Copy into aligned storage; an empty buffer need not have a base address.
            var latLngs = [Double](repeating: 0, count: Int(data.elementCount))
            _ = latLngs.withUnsafeMutableBytes { data.data.copyBytes(to: $0) }
            var reply: [Double] = Array(repeating: 0.0, count: latLngs.count)
            for index in stride(from: 0, to: latLngs.count, by: 2) {
                let coordinate = CLLocationCoordinate2DMake(latLngs[index], latLngs[index + 1])
                let returnVal = mapView.convert(coordinate, toPointTo: mapView)
                reply[index] = Double(returnVal.x)
                reply[index + 1] = Double(returnVal.y)
            }
            result(FlutterStandardTypedData(
                float64: Data(bytes: &reply, count: reply.count * 8)
            ))
        case "map#getMetersPerPixelAtLatitude":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            var reply = [String: NSObject]()
            guard let latitude = arguments["latitude"] as? Double else { invalidArguments(result); return }
            let returnVal = mapView.metersPerPoint(atLatitude: latitude)
            reply["metersperpixel"] = returnVal as NSObject
            result(reply)
        case "map#toLatLng":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let xValue = arguments["x"] as? Double else { invalidArguments(result); return }
            guard let yValue = arguments["y"] as? Double else { invalidArguments(result); return }
            let screenPoint = CGPoint(x: xValue, y: yValue)
            let coordinates: CLLocationCoordinate2D = mapView.convert(
                screenPoint,
                toCoordinateFrom: mapView
            )
            var reply = [String: NSObject]()
            reply["latitude"] = coordinates.latitude as NSObject
            reply["longitude"] = coordinates.longitude as NSObject
            result(reply)
        case "camera#move":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let cameraUpdate = arguments["cameraUpdate"] as? [Any] else { invalidArguments(result); return }
            if let camera = Convert
                .parseCameraUpdate(cameraUpdate: cameraUpdate, mapView: mapView) {
                mapView.setCamera(camera, animated: false)
            }
            result(nil)
        case "camera#animate":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let cameraUpdate = arguments["cameraUpdate"] as? [Any] else { invalidArguments(result); return }
            if let camera = Convert
                .parseCameraUpdate(cameraUpdate: cameraUpdate, mapView: mapView) {
                if let duration = arguments["duration"] as? TimeInterval {
                    mapView.setCamera(camera, withDuration: TimeInterval(duration / 1000),
                                      animationTimingFunction: CAMediaTimingFunction(name: CAMediaTimingFunctionName
                                          .easeInEaseOut))
                    result(nil)
                } else {
                    mapView.setCamera(camera, animated: true)
                }
            }
            result(nil)
        case "symbolLayer#add":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let sourceId = arguments["sourceId"] as? String else { invalidArguments(result); return }
            guard let layerId = arguments["layerId"] as? String else { invalidArguments(result); return }
            guard let properties = arguments["properties"] as? [String: String] else { invalidArguments(result); return }
            guard let enableInteraction = arguments["enableInteraction"] as? Bool else { invalidArguments(result); return }
            let belowLayerId = arguments["belowLayerId"] as? String
            let sourceLayer = arguments["sourceLayer"] as? String
            let minzoom = arguments["minzoom"] as? Double
            let maxzoom = arguments["maxzoom"] as? Double
            let filter = arguments["filter"] as? String

            removeLayer(layerId: layerId)
            let addResult = addSymbolLayer(
                sourceId: sourceId,
                layerId: layerId,
                belowLayerId: belowLayerId,
                sourceLayerIdentifier: sourceLayer,
                minimumZoomLevel: minzoom,
                maximumZoomLevel: maxzoom,
                filter: filter,
                enableInteraction: enableInteraction,
                properties: properties
            )
            switch addResult {
            case .success: result(nil)
            case let .failure(error): result(error.flutterError)
            }
        case "regionalOffline#focusRegion":
            guard RegionalOfflineHandler.isConfigured, NGLRegionalOffline.isOfflineMapSupportedForCurrentTileServer() else {
                result(FlutterError(code: "NOT_INITIALIZED", message: "Configure Regional Offline with TomTom first", details: nil)); return
            }
            guard let args = methodCall.arguments as? [String: Any],
                  let id = RegionalOfflineHandler.validRegionId(args["regionId"]) else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid regionId", details: nil)); return
            }
            result(NGLRegionalOffline.focusPreviewRegion(with: mapView, regionId: id))
        case "lineLayer#setProperties":
            guard let args = methodCall.arguments as? [String: Any], let layerId = args["layerId"] as? String,
                  let properties = args["properties"] as? [String: String] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "layerId and properties are required", details: nil)); return
            }
            guard let layer = mapView.style?.layer(withIdentifier: layerId) as? NGLLineStyleLayer else {
                result(FlutterError(code: "INVALID_LAYER", message: "The line layer does not exist", details: layerId)); return
            }
            LayerPropertyConverter.addLineProperties(lineLayer: layer, properties: properties)
            result(nil)
        case "lineLayer#add":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let sourceId = arguments["sourceId"] as? String else { invalidArguments(result); return }
            guard let layerId = arguments["layerId"] as? String else { invalidArguments(result); return }
            guard let properties = arguments["properties"] as? [String: String] else { invalidArguments(result); return }
            guard let enableInteraction = arguments["enableInteraction"] as? Bool else { invalidArguments(result); return }
            let belowLayerId = arguments["belowLayerId"] as? String
            let sourceLayer = arguments["sourceLayer"] as? String
            let minzoom = arguments["minzoom"] as? Double
            let maxzoom = arguments["maxzoom"] as? Double
            let filter = arguments["filter"] as? String

            removeLayer(layerId: layerId)
            let addResult = addLineLayer(
                sourceId: sourceId,
                layerId: layerId,
                belowLayerId: belowLayerId,
                sourceLayerIdentifier: sourceLayer,
                minimumZoomLevel: minzoom,
                maximumZoomLevel: maxzoom,
                filter: filter,
                enableInteraction: enableInteraction,
                properties: properties
            )
            switch addResult {
            case .success: result(nil)
            case let .failure(error): result(error.flutterError)
            }
        case "fillLayer#add":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let sourceId = arguments["sourceId"] as? String else { invalidArguments(result); return }
            guard let layerId = arguments["layerId"] as? String else { invalidArguments(result); return }
            guard let properties = arguments["properties"] as? [String: String] else { invalidArguments(result); return }
            guard let enableInteraction = arguments["enableInteraction"] as? Bool else { invalidArguments(result); return }
            let belowLayerId = arguments["belowLayerId"] as? String
            let sourceLayer = arguments["sourceLayer"] as? String
            let minzoom = arguments["minzoom"] as? Double
            let maxzoom = arguments["maxzoom"] as? Double
            let filter = arguments["filter"] as? String

            removeLayer(layerId: layerId)
            let addResult = addFillLayer(
                sourceId: sourceId,
                layerId: layerId,
                belowLayerId: belowLayerId,
                sourceLayerIdentifier: sourceLayer,
                minimumZoomLevel: minzoom,
                maximumZoomLevel: maxzoom,
                filter: filter,
                enableInteraction: enableInteraction,
                properties: properties
            )
            switch addResult {
            case .success: result(nil)
            case let .failure(error): result(error.flutterError)
            }
        case "fillExtrusionLayer#add":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let sourceId = arguments["sourceId"] as? String else { invalidArguments(result); return }
            guard let layerId = arguments["layerId"] as? String else { invalidArguments(result); return }
            guard let properties = arguments["properties"] as? [String: String] else { invalidArguments(result); return }
            guard let enableInteraction = arguments["enableInteraction"] as? Bool else { invalidArguments(result); return }
            let belowLayerId = arguments["belowLayerId"] as? String
            let sourceLayer = arguments["sourceLayer"] as? String
            let minzoom = arguments["minzoom"] as? Double
            let maxzoom = arguments["maxzoom"] as? Double
            let filter = arguments["filter"] as? String

            removeLayer(layerId: layerId)
            let addResult = addFillExtrusionLayer(
                sourceId: sourceId,
                layerId: layerId,
                belowLayerId: belowLayerId,
                sourceLayerIdentifier: sourceLayer,
                minimumZoomLevel: minzoom,
                maximumZoomLevel: maxzoom,
                filter: filter,
                enableInteraction: enableInteraction,
                properties: properties
            )
            switch addResult {
            case .success: result(nil)
            case let .failure(error): result(error.flutterError)
            }
        case "circleLayer#add":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let sourceId = arguments["sourceId"] as? String else { invalidArguments(result); return }
            guard let layerId = arguments["layerId"] as? String else { invalidArguments(result); return }
            guard let properties = arguments["properties"] as? [String: String] else { invalidArguments(result); return }
            guard let enableInteraction = arguments["enableInteraction"] as? Bool else { invalidArguments(result); return }
            let belowLayerId = arguments["belowLayerId"] as? String
            let sourceLayer = arguments["sourceLayer"] as? String
            let minzoom = arguments["minzoom"] as? Double
            let maxzoom = arguments["maxzoom"] as? Double
            let filter = arguments["filter"] as? String

            removeLayer(layerId: layerId)
            let addResult = addCircleLayer(
                sourceId: sourceId,
                layerId: layerId,
                belowLayerId: belowLayerId,
                sourceLayerIdentifier: sourceLayer,
                minimumZoomLevel: minzoom,
                maximumZoomLevel: maxzoom,
                filter: filter,
                enableInteraction: enableInteraction,
                properties: properties
            )
            switch addResult {
            case .success: result(nil)
            case let .failure(error): result(error.flutterError)
            }
        case "hillshadeLayer#add":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let sourceId = arguments["sourceId"] as? String else { invalidArguments(result); return }
            guard let layerId = arguments["layerId"] as? String else { invalidArguments(result); return }
            guard let properties = arguments["properties"] as? [String: String] else { invalidArguments(result); return }
            let belowLayerId = arguments["belowLayerId"] as? String
            let minzoom = arguments["minzoom"] as? Double
            let maxzoom = arguments["maxzoom"] as? Double

            removeLayer(layerId: layerId)
            addHillshadeLayer(
                sourceId: sourceId,
                layerId: layerId,
                belowLayerId: belowLayerId,
                minimumZoomLevel: minzoom,
                maximumZoomLevel: maxzoom,
                properties: properties
            )
            result(nil)
        case "heatmapLayer#add":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let sourceId = arguments["sourceId"] as? String else { invalidArguments(result); return }
            guard let layerId = arguments["layerId"] as? String else { invalidArguments(result); return }
            guard let properties = arguments["properties"] as? [String: String] else { invalidArguments(result); return }
            let belowLayerId = arguments["belowLayerId"] as? String
            let minzoom = arguments["minzoom"] as? Double
            let maxzoom = arguments["maxzoom"] as? Double

            removeLayer(layerId: layerId)
            addHeatmapLayer(
                sourceId: sourceId,
                layerId: layerId,
                belowLayerId: belowLayerId,
                minimumZoomLevel: minzoom,
                maximumZoomLevel: maxzoom,
                properties: properties
            )
            result(nil)
        case "rasterLayer#add":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let sourceId = arguments["sourceId"] as? String else { invalidArguments(result); return }
            guard let layerId = arguments["layerId"] as? String else { invalidArguments(result); return }
            guard let properties = arguments["properties"] as? [String: String] else { invalidArguments(result); return }
            let belowLayerId = arguments["belowLayerId"] as? String
            let minzoom = arguments["minzoom"] as? Double
            let maxzoom = arguments["maxzoom"] as? Double
            addRasterLayer(
                sourceId: sourceId,
                layerId: layerId,
                belowLayerId: belowLayerId,
                minimumZoomLevel: minzoom,
                maximumZoomLevel: maxzoom,
                properties: properties
            )
            result(nil)
        case "style#setStyleString":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let styleString = arguments["styleString"] as? String else { invalidArguments(result); return }
            if let error = inlineStyleJSONError(styleString) {
                result(error)
                return
            }
            setStyleString(styleString: styleString)
            result(nil)
            
        case "style#setStyleType":
            guard let arguments = methodCall.arguments as? [String: Any],
                  let styleType = Convert.mapStyleType(arguments["styleType"])
            else { invalidArguments(result); return }
            setStyleType(styleType: styleType)
            result(nil)

        case "map#switchTileServer":
            // Compatibility bridge only: existing-MapView provider changes are
            // outside this release's scope. iOS 2.3.2 may retain the old loader.
            // Supported flow: select the provider before map creation, then use
            // style#setStyleType to change themes within that provider.
            // Validate both enums before changing process-wide configuration.
            guard let arguments = methodCall.arguments as? [String: Any],
                  let server = Convert.tileServer(arguments["server"]),
                  let styleType = Convert.mapStyleType(arguments["styleType"])
            else { invalidArguments(result); return }
            NGLAccountManager.use(server)
            setStyleType(styleType: styleType)
            result(true)

        case "style#addImage":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let name = arguments["name"] as? String else { invalidArguments(result); return }
            // guard let length = arguments["length"] as? NSNumber else { invalidArguments(result); return }
            guard let bytes = arguments["bytes"] as? FlutterStandardTypedData else { invalidArguments(result); return }
            guard let sdf = arguments["sdf"] as? Bool else { invalidArguments(result); return }
            let data = bytes.data
            guard let image = UIImage(data: data, scale: UIScreen.main.scale) else { invalidArguments(result); return }
            if sdf {
                mapView.style?.setImage(image.withRenderingMode(.alwaysTemplate), forName: name)
            } else {
                mapView.style?.setImage(image, forName: name)
            }
            result(nil)
        case "style#addImageSource":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let imageSourceId = arguments["imageSourceId"] as? String else { invalidArguments(result); return }
            guard let bytes = arguments["bytes"] as? FlutterStandardTypedData else { invalidArguments(result); return }
            let data = bytes.data
            guard let image = UIImage(data: data) else { invalidArguments(result); return }

            guard let coordinates = arguments["coordinates"] as? [[Double]],
                  coordinates.count == 4, coordinates.allSatisfy({ $0.count == 2 }) else { invalidArguments(result); return }
            let quad = NGLCoordinateQuad(
                topLeft: CLLocationCoordinate2D(
                    latitude: coordinates[0][0],
                    longitude: coordinates[0][1]
                ),
                bottomLeft: CLLocationCoordinate2D(
                    latitude: coordinates[3][0],
                    longitude: coordinates[3][1]
                ),
                bottomRight: CLLocationCoordinate2D(
                    latitude: coordinates[2][0],
                    longitude: coordinates[2][1]
                ),
                topRight: CLLocationCoordinate2D(
                    latitude: coordinates[1][0],
                    longitude: coordinates[1][1]
                )
            )

            // Check for duplicateSource error
            if mapView.style?.source(withIdentifier: imageSourceId) != nil {
                result(FlutterError(
                    code: "duplicateSource",
                    message: "Source with imageSourceId \(imageSourceId) already exists",
                    details: "Can't add duplicate source with imageSourceId: \(imageSourceId)"
                ))
                return
            }

            let source = NGLImageSource(
                identifier: imageSourceId,
                coordinateQuad: quad,
                image: image
            )
            mapView.style?.addSource(source)

            result(nil)
        case "style#updateImageSource":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let imageSourceId = arguments["imageSourceId"] as? String else { invalidArguments(result); return }
            guard let imageSource = mapView.style?
                .source(withIdentifier: imageSourceId) as? NGLImageSource else { invalidArguments(result); return }
            let bytes = arguments["bytes"] as? FlutterStandardTypedData
            if bytes != nil {
                let data = bytes!.data
                guard let image = UIImage(data: data) else { invalidArguments(result); return }
                imageSource.image = image
            }
            let coordinates = arguments["coordinates"] as? [[Double]]
            if let coordinates = coordinates {
                guard coordinates.count == 4, coordinates.allSatisfy({ $0.count == 2 }) else { invalidArguments(result); return }
                let quad = NGLCoordinateQuad(
                    topLeft: CLLocationCoordinate2D(
                        latitude: coordinates[0][0],
                        longitude: coordinates[0][1]
                    ),
                    bottomLeft: CLLocationCoordinate2D(
                        latitude: coordinates[3][0],
                        longitude: coordinates[3][1]
                    ),
                    bottomRight: CLLocationCoordinate2D(
                        latitude: coordinates[2][0],
                        longitude: coordinates[2][1]
                    ),
                    topRight: CLLocationCoordinate2D(
                        latitude: coordinates[1][0],
                        longitude: coordinates[1][1]
                    )
                )
                imageSource.coordinates = quad
            }
            result(nil)
        case "style#removeSource":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let sourceId = arguments["sourceId"] as? String else { invalidArguments(result); return }
            guard let source = mapView.style?.source(withIdentifier: sourceId) else {
                result(nil)
                return
            }
            mapView.style?.removeSource(source)
            result(nil)
        case "style#addLayer":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let imageLayerId = arguments["imageLayerId"] as? String else { invalidArguments(result); return }
            guard let imageSourceId = arguments["imageSourceId"] as? String else { invalidArguments(result); return }
            let minzoom = arguments["minzoom"] as? Double
            let maxzoom = arguments["maxzoom"] as? Double

            // Check for duplicateLayer error
            if (mapView.style?.layer(withIdentifier: imageLayerId)) != nil {
                result(FlutterError(
                    code: "duplicateLayer",
                    message: "Layer already exists",
                    details: "Can't add duplicate layer with imageLayerId: \(imageLayerId)"
                ))
                return
            }
            // Check for noSuchSource error
            guard let source = mapView.style?.source(withIdentifier: imageSourceId) else {
                result(FlutterError(
                    code: "noSuchSource",
                    message: "No source found with imageSourceId \(imageSourceId)",
                    details: "Can't add add layer for imageSourceId \(imageLayerId), as the source does not exist."
                ))
                return
            }

            let layer = NGLRasterStyleLayer(identifier: imageLayerId, source: source)

            if let minzoom = minzoom {
                layer.minimumZoomLevel = Float(minzoom)
            }

            if let maxzoom = maxzoom {
                layer.maximumZoomLevel = Float(maxzoom)
            }

            mapView.style?.addLayer(layer)
            result(nil)
        case "style#addLayerBelow":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let imageLayerId = arguments["imageLayerId"] as? String else { invalidArguments(result); return }
            guard let imageSourceId = arguments["imageSourceId"] as? String else { invalidArguments(result); return }
            guard let belowLayerId = arguments["belowLayerId"] as? String else { invalidArguments(result); return }
            let minzoom = arguments["minzoom"] as? Double
            let maxzoom = arguments["maxzoom"] as? Double

            // Check for duplicateLayer error
            if (mapView.style?.layer(withIdentifier: imageLayerId)) != nil {
                result(FlutterError(
                    code: "duplicateLayer",
                    message: "Layer already exists",
                    details: "Can't add duplicate layer with imageLayerId: \(imageLayerId)"
                ))
                return
            }
            // Check for noSuchSource error
            guard let source = mapView.style?.source(withIdentifier: imageSourceId) else {
                result(FlutterError(
                    code: "noSuchSource",
                    message: "No source found with imageSourceId \(imageSourceId)",
                    details: "Can't add add layer for imageSourceId \(imageLayerId), as the source does not exist."
                ))
                return
            }
            // Check for noSuchLayer error
            guard let belowLayer = mapView.style?.layer(withIdentifier: belowLayerId) else {
                result(FlutterError(
                    code: "noSuchLayer",
                    message: "No layer found with layerId \(belowLayerId)",
                    details: "Can't insert layer below layer with id \(belowLayerId), as no such layer exists."
                ))
                return
            }

            let layer = NGLRasterStyleLayer(identifier: imageLayerId, source: source)

            if let minzoom = minzoom {
                layer.minimumZoomLevel = Float(minzoom)
            }

            if let maxzoom = maxzoom {
                layer.maximumZoomLevel = Float(maxzoom)
            }

            mapView.style?.insertLayer(layer, below: belowLayer)
            result(nil)
        case "style#removeLayer":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let layerId = arguments["layerId"] as? String else { invalidArguments(result); return }
            removeLayer(layerId: layerId)
            result(nil)
        case "style#setFilter":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let layerId = arguments["layerId"] as? String else { invalidArguments(result); return }
            guard let filter = arguments["filter"] as? String else { invalidArguments(result); return }
            guard let layer = mapView.style?.layer(withIdentifier: layerId) else {
                result(nil)
                return
            }
            switch setFilter(layer, filter) {
            case .success: result(nil)
            case let .failure(error): result(error.flutterError)
            }
        case "style#setVisibility":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let layerId = arguments["layerId"] as? String else { invalidArguments(result); return }
            guard let isVisible = arguments["isVisible"] as? Bool else { invalidArguments(result); return }
            guard let layer = mapView.style?.layer(withIdentifier: layerId) else {
                result(nil)
                return
            }
            layer.isVisible = isVisible
            result(nil)
        case "source#addGeoJson":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let sourceId = arguments["sourceId"] as? String else { invalidArguments(result); return }
            guard let geojson = arguments["geojson"] as? String else { invalidArguments(result); return }
            addSourceGeojson(sourceId: sourceId, geojson: geojson)
            result(nil)
        case "style#addSource":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let sourceId = arguments["sourceId"] as? String else { invalidArguments(result); return }
            guard let properties = arguments["properties"] as? [String: Any] else { invalidArguments(result); return }
            addSource(sourceId: sourceId, properties: properties)
            result(nil)
        case "style#findBelowLayer":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let belowAt = arguments["belowAt"] as? [String] else { invalidArguments(result); return }
            guard let styleLayers = mapView.style?.layers else { invalidArguments(result); return }
            for (index, layer) in styleLayers.enumerated().reversed() {
                if !(layer is NGLSymbolStyleLayer) &&
                    !(layer is NGLFillExtrusionStyleLayer) &&
                    (belowAt.filter { layer.identifier.contains($0) }.isEmpty) {
                    if index == styleLayers.count - 1 {
                        result(styleLayers[index].identifier)
                    } else {
                        result(styleLayers[index + 1].identifier)
                    }
                    break
                }
            }
            result(nil)
        case "source#setGeoJson":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let sourceId = arguments["sourceId"] as? String else { invalidArguments(result); return }
            guard let geojson = arguments["geojson"] as? String else { invalidArguments(result); return }
            setSource(sourceId: sourceId, geojson: geojson)
            result(nil)
        case "source#setFeature":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            guard let sourceId = arguments["sourceId"] as? String else { invalidArguments(result); return }
            guard let geojson = arguments["geojsonFeature"] as? String else { invalidArguments(result); return }
            setFeature(sourceId: sourceId, geojsonFeature: geojson)
            result(nil)
        case "snapshot#takeSnapshot":
            guard let arguments = methodCall.arguments as? [String: Any] else { invalidArguments(result); return }
            let camera = NGLMapCamera()

            guard let pitch = arguments["pitch"] as? NSNumber else {
                result(FlutterError(code: "invalidArgument", message: "pitch is not a number",
                                    details: nil))
                return
            }
            camera.pitch = pitch.doubleValue

            guard let heading = arguments["heading"] as? NSNumber else {
                result(FlutterError(code: "invalidArgument", message: "heading is not a number",
                                    details: nil))
                return
            }
            camera.heading = heading.doubleValue

            camera.centerCoordinate = mapView.centerCoordinate
            if arguments["centerCoordinate"] != nil {
                guard let centerCoordinate = arguments["centerCoordinate"] as? [NSNumber],
                      centerCoordinate.count == 2 else {
                    result(FlutterError(
                        code: "invalidArgument",
                        message: "centerCoordinate is not a number list",
                        details: nil
                    ))
                    return
                }
                camera.centerCoordinate = CLLocationCoordinate2D(
                    latitude: centerCoordinate[0].doubleValue,
                    longitude: centerCoordinate[1].doubleValue
                )
            }

            guard let width = arguments["width"] as? NSNumber else {
                result(FlutterError(code: "invalidArgument", message: "width is not a number",
                                    details: nil))
                return
            }
            guard let height = arguments["height"] as? NSNumber else {
                result(FlutterError(code: "invalidArgument", message: "height is not a number",
                                    details: nil))
                return
            }

            guard width.doubleValue.isFinite, height.doubleValue.isFinite,
                  width.doubleValue > 0, height.doubleValue > 0 else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Snapshot dimensions must be positive and finite", details: nil))
                return
            }
            let size = CGSize(width: width.doubleValue, height: height.doubleValue)

            var styleURL: URL = mapView.styleURL
            if arguments["styleUri"] != nil {
                guard let styleUri = arguments["styleUri"] as? String else {
                    result(
                        FlutterError(code: "invalidArgument", message: "styleUri is not a string",
                                     details: nil)
                    )
                    return
                }
                guard let url = URL(string: styleUri) else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid snapshot style URI", details: nil))
                    return
                }
                styleURL = url
            }

            let snapshotOptions: NGLMapSnapshotOptions = .init(
                styleURL: styleURL,
                camera: camera,
                size: size
            )

            snapshotOptions.zoomLevel = mapView.zoomLevel
            if arguments["zoomLevel"] != nil {
                guard let zoomLevel = arguments["zoomLevel"] as? NSNumber else {
                    result(FlutterError(code: "invalidArgument",
                                        message: "zoomLevel is not a number", details: nil))
                    return
                }
                snapshotOptions.zoomLevel = zoomLevel.doubleValue
            }

            if arguments["bounds"] != nil {
                guard let bounds = arguments["bounds"] as? [[NSNumber]],
                      bounds.count == 2, bounds.allSatisfy({ $0.count == 2 }) else {
                    result(FlutterError(code: "invalidArgument",
                                        message: "bounds is not a number list", details: nil))
                    return
                }
                let sw = bounds[0]
                let ne = bounds[1]
                snapshotOptions.coordinateBounds = NGLCoordinateBounds(
                    sw: CLLocationCoordinate2D(latitude: sw[0].doubleValue,
                                               longitude: sw[1].doubleValue),
                    ne: CLLocationCoordinate2D(
                        latitude: ne[0].doubleValue,
                        longitude: ne[1].doubleValue
                    )
                )
            }

            let snapshotId = UUID()
            let snapshotter = NGLMapSnapshotter(options: snapshotOptions)
            snapshotters[snapshotId] = snapshotter
            snapshotResults[snapshotId] = result
            snapshotter.start { [weak self] snapshot, error in
                guard let self = self,
                      let result = self.snapshotResults.removeValue(forKey: snapshotId) else { return }
                self.snapshotters.removeValue(forKey: snapshotId)
                if error != nil {
                    result(FlutterError(
                        code: "canCreateSnapshot",
                        message: error?.localizedDescription,
                        details: error.debugDescription
                    ))
                } else if let image = snapshot?.image {
                    guard let writeToDisk = arguments["writeToDisk"] as? NSNumber else {
                        result(FlutterError(code: "invalidArgument",
                                            message: "writeToDisk is not a boolean", details: nil))
                        return
                    }

                    let value = writeToDisk.boolValue ? RNMBImageUtils
                        .createTempFile(image) : RNMBImageUtils.createBase64(image)
                    result(value?.absoluteString)
                } else {
                    result(FlutterError(code: "NO_RESULT", message: "Snapshot returned no image", details: nil))
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func invalidArguments(_ result: FlutterResult) {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid or missing map arguments", details: nil))
    }

    private func removeLayer(layerId: String) {
        if let layer = mapView.style?.layer(withIdentifier: layerId) {
            mapView.style?.removeLayer(layer)
            interactiveFeatureLayerIds.remove(layerId)
        }
    }

    private func loadIconImage(name: String) -> UIImage? {
        // Build up the full path of the asset.
        // First find the last '/' ans split the image name in the asset directory and the image file name.
        if let range = name.range(of: "/", options: [.backwards]) {
            let directory = String(name[..<range.lowerBound])
            let assetPath = registrar.lookupKey(forAsset: "\(directory)/")
            let fileName = String(name[range.upperBound...])
            // If we can load the image from file then add it to the map.
            return UIImage.loadFromFile(
                imagePath: assetPath,
                imageName: fileName
            )
        }
        return nil
    }

    private func addIconImageToMap(iconImageName: String) {
        // Check if the image has already been added to the map.
        if mapView.style?.image(forName: iconImageName) == nil {
            if let imageFromAsset = loadIconImage(name: iconImageName) {
                mapView.style?.setImage(imageFromAsset, forName: iconImageName)
            }
        }
    }

    private func updateMyLocationEnabled() {
        mapView.showsUserLocation = myLocationEnabled
    }

    private func getCamera() -> NGLMapCamera? {
        return trackCameraPosition ? mapView.camera : nil
    }

    /*
     *  Scan layers from top to bottom and return the first matching feature
     */
    private func firstFeatureOnLayers(at: CGPoint) -> NGLFeature? {
        guard let style = mapView.style else { return nil }

        // get layers in order (interactiveFeatureLayerIds is unordered)
        let clickableLayers = style.layers.filter { layer in
            interactiveFeatureLayerIds.contains(layer.identifier)
        }

        for layer in clickableLayers.reversed() {
            let features = mapView.visibleFeatures(
                at: at,
                styleLayerIdentifiers: [layer.identifier]
            )
            if let feature = features.first {
                return feature
            }
        }
        return nil
    }

    /*
     *  UITapGestureRecognizer
     *  On tap invoke the map#onMapClick callback.
     */
    @IBAction func handleMapTap(sender: UITapGestureRecognizer) {
        // Get the CGPoint where the user tapped.
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

        if let feature = firstFeatureOnLayers(at: point), let id = feature.identifier {
            channel?.invokeMethod("feature#onTap", arguments: [
                "id": id,
                "x": point.x,
                "y": point.y,
                "lng": coordinate.longitude,
                "lat": coordinate.latitude,
            ])
        } else {
            channel?.invokeMethod("map#onMapClick", arguments: [
                "x": point.x,
                "y": point.y,
                "lng": coordinate.longitude,
                "lat": coordinate.latitude,
            ])
        }
    }

    fileprivate func invokeFeatureDrag(
        _ point: CGPoint,
        _ coordinate: CLLocationCoordinate2D,
        _ eventType: String
    ) {
        if let feature = dragFeature,
           let id = feature.identifier,
           let previous = previousDragCoordinate,
           let origin = originDragCoordinate {
            channel?.invokeMethod("feature#onDrag", arguments: [
                "id": id,
                "x": point.x,
                "y": point.y,
                "originLng": origin.longitude,
                "originLat": origin.latitude,
                "currentLng": coordinate.longitude,
                "currentLat": coordinate.latitude,
                "eventType": eventType,
                "deltaLng": coordinate.longitude - previous.longitude,
                "deltaLat": coordinate.latitude - previous.latitude,
            ])
        }
    }

    @IBAction func handleMapPan(sender: UIPanGestureRecognizer) {
        let began = sender.state == UIGestureRecognizer.State.began
        let end = sender.state == UIGestureRecognizer.State.ended
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

        if dragFeature == nil, began, sender.numberOfTouches == 1,
           let feature = firstFeatureOnLayers(at: point),
           let draggable = feature.attribute(forKey: "draggable") as? Bool,
           draggable {
            sender.state = UIGestureRecognizer.State.began
            dragFeature = feature
            originDragCoordinate = coordinate
            previousDragCoordinate = coordinate
            mapView.allowsScrolling = false
            let eventType = "start"
            invokeFeatureDrag(point, coordinate, eventType)
            for gestureRecognizer in (mapView.gestureRecognizers ?? []) {
                if gestureRecognizer is UIPanGestureRecognizer {
                    gestureRecognizer.addTarget(self, action: #selector(handleMapPan))
                    break
                }
            }
        }
        if end, dragFeature != nil {
            mapView.allowsScrolling = true
            let eventType = "end"
            invokeFeatureDrag(point, coordinate, eventType)
            dragFeature = nil
            originDragCoordinate = nil
            previousDragCoordinate = nil
        }

        if !began, !end, dragFeature != nil {
            let eventType = "drag"
            invokeFeatureDrag(point, coordinate, eventType)
            previousDragCoordinate = coordinate
        }
    }

    /*
     *  UILongPressGestureRecognizer
     *  After a long press invoke the map#onMapLongClick callback.
     */
    @IBAction func handleMapLongPress(sender: UILongPressGestureRecognizer) {
        // Fire when the long press starts
        if sender.state == .began {
            // Get the CGPoint where the user tapped.
            let point = sender.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            channel?.invokeMethod("map#onMapLongClick", arguments: [
                "x": point.x,
                "y": point.y,
                "lng": coordinate.longitude,
                "lat": coordinate.latitude,
            ])
        }
    }

    /*
     * Override the attribution button's click target to handle the event locally.
     * Called if the application supplies an onAttributionClick handler.
     */
    func setupAttribution(_ mapView: NGLMapView) {
        mapView.attributionButton.removeTarget(
            mapView,
            action: #selector(mapView.showAttribution),
            for: .touchUpInside
        )
        mapView.attributionButton.addTarget(
            self,
            action: #selector(showAttribution),
            for: UIControl.Event.touchUpInside
        )
    }

    /*
     * Custom click handler for the attribution button. This callback is bound when
     * the application specifies an onAttributionClick handler.
     */
    @objc func showAttribution() {
        channel?.invokeMethod("map#onAttributionClick", arguments: nil)
    }

    /*
     *  NGLMapViewDelegate
     */
    func mapView(_: NGLMapView, didFinishLoading _: NGLStyle) {
        hasLoadedStyle = true
        updateMyLocationEnabled()
        if let tilt = initialTilt {
            let camera = mapView.camera
            camera.pitch = tilt
            mapView.setCamera(camera, animated: false)
            initialTilt = nil
        }
        addedShapesByLayer.removeAll()
        interactiveFeatureLayerIds.removeAll()
        if hasDartController {
            channel?.invokeMethod("map#onStyleLoaded", arguments: nil)
        }
    }

    // handle missing images
    func mapView(_: NGLMapView, didFailToLoadImage name: String) -> UIImage? {
        return loadIconImage(name: name)
    }

    func mapView(_ mapView: NGLMapView, shouldChangeFrom _: NGLMapCamera,
                 to newCamera: NGLMapCamera) -> Bool {
        guard let bbox = cameraTargetBounds else { return true }

        // Get the current camera to restore it after.
        let currentCamera = mapView.camera

        // From the new camera obtain the center to test if it’s inside the boundaries.
        let newCameraCenter = newCamera.centerCoordinate

        // Set the map’s visible bounds to newCamera.
        mapView.camera = newCamera
        let newVisibleCoordinates = mapView.visibleCoordinateBounds

        // Revert the camera.
        mapView.camera = currentCamera

        // Test if the newCameraCenter and newVisibleCoordinates are inside bbox.
        let inside = NGLCoordinateInCoordinateBounds(newCameraCenter, bbox)
        let intersects = NGLCoordinateInCoordinateBounds(newVisibleCoordinates.ne, bbox) &&
            NGLCoordinateInCoordinateBounds(newVisibleCoordinates.sw, bbox)

        return inside && intersects
    }

    func mapView(_: NGLMapView, didUpdate userLocation: NGLUserLocation?) {
        if let channel = channel, let userLocation = userLocation,
           let location = userLocation.location {
            channel.invokeMethod("map#onUserLocationUpdated", arguments: [
                "userLocation": location.toDict(),
                "heading": userLocation.heading?.toDict(),
            ])
        }
    }

    func mapView(_: NGLMapView, didChange mode: NGLUserTrackingMode, animated _: Bool) {
        if let channel = channel {
            channel.invokeMethod("map#onCameraTrackingChanged", arguments: ["mode": mode.rawValue])
            if mode == .none {
                channel.invokeMethod("map#onCameraTrackingDismissed", arguments: nil)
            }
        }
    }

    func addSymbolLayer(
        sourceId: String,
        layerId: String,
        belowLayerId: String?,
        sourceLayerIdentifier: String?,
        minimumZoomLevel: Double?,
        maximumZoomLevel: Double?,
        filter: String?,
        enableInteraction: Bool,
        properties: [String: String]
    ) -> Result<Void, MethodCallError> {
        if let style = mapView.style {
            if let source = style.source(withIdentifier: sourceId) {
                let layer = NGLSymbolStyleLayer(identifier: layerId, source: source)
                LayerPropertyConverter.addSymbolProperties(
                    symbolLayer: layer,
                    properties: properties
                )
                if let sourceLayerIdentifier = sourceLayerIdentifier {
                    layer.sourceLayerIdentifier = sourceLayerIdentifier
                }
                if let minimumZoomLevel = minimumZoomLevel {
                    layer.minimumZoomLevel = Float(minimumZoomLevel)
                }
                if let maximumZoomLevel = maximumZoomLevel {
                    layer.maximumZoomLevel = Float(maximumZoomLevel)
                }
                if let filter = filter {
                    if case let .failure(error) = setFilter(layer, filter) {
                        return .failure(error)
                    }
                }
                if let id = belowLayerId, let belowLayer = style.layer(withIdentifier: id) {
                    style.insertLayer(layer, below: belowLayer)
                } else {
                    style.addLayer(layer)
                }
                if enableInteraction {
                    interactiveFeatureLayerIds.insert(layerId)
                }
            }
        }
        return .success(())
    }

    func addLineLayer(
        sourceId: String,
        layerId: String,
        belowLayerId: String?,
        sourceLayerIdentifier: String?,
        minimumZoomLevel: Double?,
        maximumZoomLevel: Double?,
        filter: String?,
        enableInteraction: Bool,
        properties: [String: String]
    ) -> Result<Void, MethodCallError> {
        if let style = mapView.style {
            if let source = style.source(withIdentifier: sourceId) {
                let layer = NGLLineStyleLayer(identifier: layerId, source: source)
                LayerPropertyConverter.addLineProperties(lineLayer: layer, properties: properties)
                if let sourceLayerIdentifier = sourceLayerIdentifier {
                    layer.sourceLayerIdentifier = sourceLayerIdentifier
                }
                if let minimumZoomLevel = minimumZoomLevel {
                    layer.minimumZoomLevel = Float(minimumZoomLevel)
                }
                if let maximumZoomLevel = maximumZoomLevel {
                    layer.maximumZoomLevel = Float(maximumZoomLevel)
                }
                if let filter = filter {
                    if case let .failure(error) = setFilter(layer, filter) {
                        return .failure(error)
                    }
                }
                if let id = belowLayerId, let belowLayer = style.layer(withIdentifier: id) {
                    style.insertLayer(layer, below: belowLayer)
                } else {
                    style.addLayer(layer)
                }
                if enableInteraction {
                    interactiveFeatureLayerIds.insert(layerId)
                }
            }
        }
        return .success(())
    }

    func addFillLayer(
        sourceId: String,
        layerId: String,
        belowLayerId: String?,
        sourceLayerIdentifier: String?,
        minimumZoomLevel: Double?,
        maximumZoomLevel: Double?,
        filter: String?,
        enableInteraction: Bool,
        properties: [String: String]
    ) -> Result<Void, MethodCallError> {
        if let style = mapView.style {
            if let source = style.source(withIdentifier: sourceId) {
                let layer = NGLFillStyleLayer(identifier: layerId, source: source)
                LayerPropertyConverter.addFillProperties(fillLayer: layer, properties: properties)
                if let sourceLayerIdentifier = sourceLayerIdentifier {
                    layer.sourceLayerIdentifier = sourceLayerIdentifier
                }
                if let minimumZoomLevel = minimumZoomLevel {
                    layer.minimumZoomLevel = Float(minimumZoomLevel)
                }
                if let maximumZoomLevel = maximumZoomLevel {
                    layer.maximumZoomLevel = Float(maximumZoomLevel)
                }
                if let filter = filter {
                    if case let .failure(error) = setFilter(layer, filter) {
                        return .failure(error)
                    }
                }
                if let id = belowLayerId, let belowLayer = style.layer(withIdentifier: id) {
                    style.insertLayer(layer, below: belowLayer)
                } else {
                    style.addLayer(layer)
                }
                if enableInteraction {
                    interactiveFeatureLayerIds.insert(layerId)
                }
            }
        }
        return .success(())
    }

    func addFillExtrusionLayer(
        sourceId: String,
        layerId: String,
        belowLayerId: String?,
        sourceLayerIdentifier: String?,
        minimumZoomLevel: Double?,
        maximumZoomLevel: Double?,
        filter: String?,
        enableInteraction: Bool,
        properties: [String: String]
    ) -> Result<Void, MethodCallError> {
        if let style = mapView.style {
            if let source = style.source(withIdentifier: sourceId) {
                let layer = NGLFillExtrusionStyleLayer(identifier: layerId, source: source)
                LayerPropertyConverter.addFillExtrusionProperties(
                    fillExtrusionLayer: layer,
                    properties: properties
                )
                if let sourceLayerIdentifier = sourceLayerIdentifier {
                    layer.sourceLayerIdentifier = sourceLayerIdentifier
                }
                if let minimumZoomLevel = minimumZoomLevel {
                    layer.minimumZoomLevel = Float(minimumZoomLevel)
                }
                if let maximumZoomLevel = maximumZoomLevel {
                    layer.maximumZoomLevel = Float(maximumZoomLevel)
                }
                if let filter = filter {
                    if case let .failure(error) = setFilter(layer, filter) {
                        return .failure(error)
                    }
                }
                if let id = belowLayerId, let belowLayer = style.layer(withIdentifier: id) {
                    style.insertLayer(layer, below: belowLayer)
                } else {
                    style.addLayer(layer)
                }
                if enableInteraction {
                    interactiveFeatureLayerIds.insert(layerId)
                }
            }
        }
        return .success(())
    }

    func addCircleLayer(
        sourceId: String,
        layerId: String,
        belowLayerId: String?,
        sourceLayerIdentifier: String?,
        minimumZoomLevel: Double?,
        maximumZoomLevel: Double?,
        filter: String?,
        enableInteraction: Bool,
        properties: [String: String]
    ) -> Result<Void, MethodCallError> {
        if let style = mapView.style {
            if let source = style.source(withIdentifier: sourceId) {
                let layer = NGLCircleStyleLayer(identifier: layerId, source: source)
                LayerPropertyConverter.addCircleProperties(
                    circleLayer: layer,
                    properties: properties
                )
                if let sourceLayerIdentifier = sourceLayerIdentifier {
                    layer.sourceLayerIdentifier = sourceLayerIdentifier
                }
                if let minimumZoomLevel = minimumZoomLevel {
                    layer.minimumZoomLevel = Float(minimumZoomLevel)
                }
                if let maximumZoomLevel = maximumZoomLevel {
                    layer.maximumZoomLevel = Float(maximumZoomLevel)
                }
                if let filter = filter {
                    if case let .failure(error) = setFilter(layer, filter) {
                        return .failure(error)
                    }
                }
                if let id = belowLayerId, let belowLayer = style.layer(withIdentifier: id) {
                    style.insertLayer(layer, below: belowLayer)
                } else {
                    style.addLayer(layer)
                }
                if enableInteraction {
                    interactiveFeatureLayerIds.insert(layerId)
                }
            }
        }
        return .success(())
    }

    func setFilter(_ layer: NGLStyleLayer, _ filter: String) -> Result<Void, MethodCallError> {
        do {
            let filter = try JSONSerialization.jsonObject(
                with: filter.data(using: .utf8)!,
                options: .fragmentsAllowed
            )
            if filter is NSNull {
                return .success(())
            }
            let predicate = NSPredicate(nglJSONObject: filter)
            if let layer = layer as? NGLVectorStyleLayer {
                layer.predicate = predicate
            } else {
                return .failure(MethodCallError.invalidLayerType(
                    details: "Layer '\(layer.identifier)' does not support filtering."
                ))
            }
            return .success(())
        } catch {
            return .failure(MethodCallError.invalidExpression)
        }
    }

    func addHillshadeLayer(
        sourceId: String,
        layerId: String,
        belowLayerId: String?,
        minimumZoomLevel: Double?,
        maximumZoomLevel: Double?,
        properties: [String: String]
    ) {
        if let style = mapView.style {
            if let source = style.source(withIdentifier: sourceId) {
                let layer = NGLHillshadeStyleLayer(identifier: layerId, source: source)
                LayerPropertyConverter.addHillshadeProperties(
                    hillshadeLayer: layer,
                    properties: properties
                )
                if let minimumZoomLevel = minimumZoomLevel {
                    layer.minimumZoomLevel = Float(minimumZoomLevel)
                }
                if let maximumZoomLevel = maximumZoomLevel {
                    layer.maximumZoomLevel = Float(maximumZoomLevel)
                }
                if let id = belowLayerId, let belowLayer = style.layer(withIdentifier: id) {
                    style.insertLayer(layer, below: belowLayer)
                } else {
                    style.addLayer(layer)
                }
            }
        }
    }

    func addHeatmapLayer(
        sourceId: String,
        layerId: String,
        belowLayerId: String?,
        minimumZoomLevel: Double?,
        maximumZoomLevel: Double?,
        properties: [String: String]
    ) {
        if let style = mapView.style {
            if let source = style.source(withIdentifier: sourceId) {
                let layer = NGLHeatmapStyleLayer(identifier: layerId, source: source)
                LayerPropertyConverter.addHeatmapProperties(
                    heatmapLayer: layer,
                    properties: properties
                )
                if let minimumZoomLevel = minimumZoomLevel {
                    layer.minimumZoomLevel = Float(minimumZoomLevel)
                }
                if let maximumZoomLevel = maximumZoomLevel {
                    layer.maximumZoomLevel = Float(maximumZoomLevel)
                }
                if let id = belowLayerId, let belowLayer = style.layer(withIdentifier: id) {
                    style.insertLayer(layer, below: belowLayer)
                } else {
                    style.addLayer(layer)
                }
            }
        }
    }

    func addRasterLayer(
        sourceId: String,
        layerId: String,
        belowLayerId: String?,
        minimumZoomLevel: Double?,
        maximumZoomLevel: Double?,
        properties: [String: String]
    ) {
        if let style = mapView.style {
            if let source = style.source(withIdentifier: sourceId) {
                let layer = NGLRasterStyleLayer(identifier: layerId, source: source)
                LayerPropertyConverter.addRasterProperties(
                    rasterLayer: layer,
                    properties: properties
                )
                if let minimumZoomLevel = minimumZoomLevel {
                    layer.minimumZoomLevel = Float(minimumZoomLevel)
                }
                if let maximumZoomLevel = maximumZoomLevel {
                    layer.maximumZoomLevel = Float(maximumZoomLevel)
                }
                if let id = belowLayerId, let belowLayer = style.layer(withIdentifier: id) {
                    style.insertLayer(layer, below: belowLayer)
                } else {
                    style.addLayer(layer)
                }
            }
        }
    }

    func addSource(sourceId: String, properties: [String: Any]) {
        if let style = mapView.style, let type = properties["type"] as? String {
            var source: NGLSource?

            switch type {
            case "vector":
                source = SourcePropertyConverter.buildVectorTileSource(
                    identifier: sourceId,
                    properties: properties
                )
            case "raster":
                source = SourcePropertyConverter.buildRasterTileSource(
                    identifier: sourceId,
                    properties: properties
                )
            case "raster-dem":
                source = SourcePropertyConverter.buildRasterDemSource(
                    identifier: sourceId,
                    properties: properties
                )
            case "image":
                source = SourcePropertyConverter.buildImageSource(
                    identifier: sourceId,
                    properties: properties
                )
            case "geojson":
                source = SourcePropertyConverter.buildShapeSource(
                    identifier: sourceId,
                    properties: properties
                )
            default:
                // unsupported source type
                source = nil
            }
            if let source = source {
                style.addSource(source)
            }
        }
    }

    func mapViewDidBecomeIdle(_: NGLMapView) {
        if let channel = channel {
            channel.invokeMethod("map#onIdle", arguments: nil)
        }
    }

    func mapView(_: NGLMapView, regionWillChangeAnimated _: Bool) {
        if let channel = channel {
            channel.invokeMethod("camera#onMoveStarted", arguments: nil)
        }
    }

    func mapViewRegionIsChanging(_ mapView: NGLMapView) {
        if !trackCameraPosition { return }
        if let channel = channel {
            channel.invokeMethod("camera#onMove", arguments: [
                "position": getCamera()?.toDict(mapView: mapView),
            ])
        }
    }

    func mapView(_ mapView: NGLMapView, regionDidChangeAnimated _: Bool) {
        let arguments = trackCameraPosition ? [
            "position": getCamera()?.toDict(mapView: mapView)
        ] : [:]
        if let channel = channel {
            channel.invokeMethod("camera#onIdle", arguments: arguments)
        }
    }

    func addSourceGeojson(sourceId: String, geojson: String) {
        do {
            let parsed = try NGLShape(
                data: geojson.data(using: .utf8)!,
                encoding: String.Encoding.utf8.rawValue
            )
            let source = NGLShapeSource(identifier: sourceId, shape: parsed, options: [:])
            addedShapesByLayer[sourceId] = parsed
            mapView.style?.addSource(source)
            print(source)
        } catch {}
    }

    func setSource(sourceId: String, geojson: String) {
        do {
            // Process encoded geometry if present in the GeoJSON
            let processedGeoJson = PolylineDecoder.processEncodedGeometryInFeatureCollection(geojson: geojson)

            let parsed = try NGLShape(
                data: processedGeoJson.data(using: .utf8)!,
                encoding: String.Encoding.utf8.rawValue
            )
            if let source = mapView.style?.source(withIdentifier: sourceId) as? NGLShapeSource {
                addedShapesByLayer[sourceId] = parsed
                source.shape = parsed
            }
        } catch {
            print("iOS: Error setting source: \(error)")
        }
    }

    private func processEncodedGeometry(geojsonFeature: String) -> String {
        do {
            guard let data = geojsonFeature.data(using: .utf8),
                  let featureDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return geojsonFeature
            }
            let processedFeature = PolylineDecoder.processEncodedGeometry(featureDict)
            let processedData = try JSONSerialization.data(withJSONObject: processedFeature)
            return String(data: processedData, encoding: .utf8) ?? geojsonFeature
        } catch {
            print("iOS: Error processing encoded geometry: \(error)")
            return geojsonFeature
        }
    }

    func setFeature(sourceId: String, geojsonFeature: String) {
        do {
            // Process encoded geometry if present
            let processedGeoJsonFeature = processEncodedGeometry(geojsonFeature: geojsonFeature)
            
            let newShape = try NGLShape(
                data: processedGeoJsonFeature.data(using: .utf8)!,
                encoding: String.Encoding.utf8.rawValue
            )
            if let source = mapView.style?.source(withIdentifier: sourceId) as? NGLShapeSource,
               let shape = addedShapesByLayer[sourceId] as? NGLShapeCollectionFeature,
               let feature = newShape as? NGLShape & NGLFeature {
                if let index = shape.shapes
                    .firstIndex(where: {
                        if let id = $0.identifier as? String,
                           let featureId = feature.identifier as? String {
                            return id == featureId
                        }

                        if let id = $0.identifier as? NSNumber,
                           let featureId = feature.identifier as? NSNumber {
                            return id == featureId
                        }
                        return false
                    }) {
                    var shapes = shape.shapes
                    shapes[index] = feature

                    source.shape = NGLShapeCollectionFeature(shapes: shapes)
                }

                addedShapesByLayer[sourceId] = source.shape
            }

        } catch {
            print("iOS: Error processing feature: \(error)")
        }
    }


    /*
     *  NextbillionMapOptionsSink
     */
    func setCameraTargetBounds(bounds: NGLCoordinateBounds?) {
        cameraTargetBounds = bounds
    }

    func setCompassEnabled(compassEnabled: Bool) {
        mapView.compassView.isHidden = compassEnabled
        mapView.compassView.isHidden = !compassEnabled
    }

    func setMinMaxZoomPreference(min: Double, max: Double) {
        mapView.minimumZoomLevel = min
        mapView.maximumZoomLevel = max
    }

    private func inlineStyleJSONError(_ styleString: String) -> FlutterError? {
        let value = styleString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.hasPrefix("{") || value.hasPrefix("[") else { return nil }
        return FlutterError(code: "UNSUPPORTED_STYLE_JSON",
                            message: "Inline JSON styles are not supported on iOS. Save the JSON to a local file and pass its file:// URL, or use a style URL.",
                            details: nil)
    }

    func setStyleString(styleString: String) {
        // Check if json, url, absolute path or asset path:
        if styleString.isEmpty {
            NSLog("setStyleString - string empty")
        } else if styleString.hasPrefix("{") || styleString.hasPrefix("[") {
            // Currently the iOS NbMaps SDK does not have a builder for json.
            NSLog("setStyleString - JSON style currently not supported")
        } else if styleString.hasPrefix("/") {
            // Absolute path
            mapView.styleURL = URL(fileURLWithPath: styleString, isDirectory: false)
        } else if let fileURL = URL(string: styleString), fileURL.isFileURL {
            // Dart File.uri produces file:// URLs, not Flutter asset keys.
            mapView.styleURL = fileURL
        } else if
            !styleString.hasPrefix("http://"),
            !styleString.hasPrefix("https://"),
            !styleString.hasPrefix("nbmaps://"),
            !styleString.hasPrefix("tomtom://"),
            !styleString.hasPrefix("orbis://"),
            !styleString.hasPrefix("maptiler:/")
        {
            // We are assuming that the style will be loaded from an asset here.
            let assetPath = registrar.lookupKey(forAsset: styleString)
            mapView.styleURL = URL(string: assetPath, relativeTo: Bundle.main.resourceURL)

        } else {
            mapView.styleURL = URL(string: styleString)
        }
        NGLRegionalOfflineStyleCatalog.registerMapStyle(forMapView: mapView, styleURL: mapView.styleURL)
    }
    
    func setStyleType(styleType: NGMapStyleType) {
        mapView.setStyleWith(styleType)
        NGLRegionalOfflineStyleCatalog.registerMapStyle(forMapView: mapView, styleURL: mapView.styleURL)
    }

    func setRotateGesturesEnabled(rotateGesturesEnabled: Bool) {
        mapView.allowsRotating = rotateGesturesEnabled
    }

    func setScrollGesturesEnabled(scrollGesturesEnabled: Bool) {
        mapView.allowsScrolling = scrollGesturesEnabled
        scrollingEnabled = scrollGesturesEnabled
    }

    func setTiltGesturesEnabled(tiltGesturesEnabled: Bool) {
        mapView.allowsTilting = tiltGesturesEnabled
    }

    func setTrackCameraPosition(trackCameraPosition: Bool) {
        self.trackCameraPosition = trackCameraPosition
    }

    func setZoomGesturesEnabled(zoomGesturesEnabled: Bool) {
        mapView.allowsZooming = zoomGesturesEnabled
    }

    func setMyLocationEnabled(myLocationEnabled: Bool) {
        if self.myLocationEnabled == myLocationEnabled {
            return
        }
        self.myLocationEnabled = myLocationEnabled
        updateMyLocationEnabled()
    }

    func setMyLocationTrackingMode(myLocationTrackingMode: NGLUserTrackingMode) {
        mapView.userTrackingMode = myLocationTrackingMode
    }

    func setMyLocationRenderMode(myLocationRenderMode: MyLocationRenderMode) {
        switch myLocationRenderMode {
        case .normal:
            mapView.showsUserHeadingIndicator = false
        case .compass:
            mapView.showsUserHeadingIndicator = true
        case .gps:
            NSLog("RenderMode.GPS currently not supported")
        }
    }

    func setLogoViewMargins(xValue: Double, yValue: Double) {
        mapView.logoViewMargins = CGPoint(x: xValue, y: yValue)
    }

    func setCompassViewPosition(position: NGLOrnamentPosition) {
        mapView.compassViewPosition = position
    }

    func setCompassViewMargins(xValue: Double, yValue: Double) {
        mapView.compassViewMargins = CGPoint(x: xValue, y: yValue)
    }

    func setAttributionButtonMargins(xValue: Double, yValue: Double) {
        mapView.attributionButtonMargins = CGPoint(x: xValue, y: yValue)
    }

    func setAttributionButtonPosition(position: NGLOrnamentPosition) {
        mapView.attributionButtonPosition = position
    }
}
