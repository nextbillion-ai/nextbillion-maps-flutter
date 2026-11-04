import Flutter
import Nbmap
import UIKit
import CoreFoundation

final class RegionalOfflineHandler: NSObject, FlutterPlugin, FlutterStreamHandler {
    private let registrar: FlutterPluginRegistrar
    private let methods: FlutterMethodChannel
    private let events: FlutterEventChannel
    private var sink: FlutterEventSink?
    private var progressToken: NGLRegionalOfflineListenerToken?
    private var previewToken: NGLRegionalOfflineListenerToken?
    private var pageId: String?
    private var closed = false
    private var pendingResults: [UUID: FlutterResult] = [:]
    private static weak var activePageOwner: RegionalOfflineHandler?
    private static var configuredBaseURL: String?
    private static var configuringBaseURL: String?
    private static var configurationCompletions: [() -> Void] = []
    // SDK configuration/local metadata can touch disk. This queue is independent
    // of map creation and never waits synchronously for the platform-view thread.
    private static let storageQueue = DispatchQueue(label: "ai.nextbillion.flutter.regional-offline", qos: .utility)
    static var isConfigured: Bool { configuredBaseURL != nil }

    static func register(with registrar: FlutterPluginRegistrar) {
        registrar.publish(registerHandler(with: registrar))
    }

    static func registerHandler(with registrar: FlutterPluginRegistrar) -> RegionalOfflineHandler {
        let instance = RegionalOfflineHandler(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: instance.methods)
        return instance
    }

    private init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        methods = FlutterMethodChannel(name: "plugins.flutter.io/nb_maps_flutter/regional_offline",
                                       binaryMessenger: registrar.messenger())
        events = FlutterEventChannel(name: "plugins.flutter.io/nb_maps_flutter/regional_offline/events",
                                     binaryMessenger: registrar.messenger())
        super.init()
        events.setStreamHandler(self)
    }

    func handle(_ call: FlutterMethodCall, result originalResult: @escaping FlutterResult) {
        guard !closed else { return }
        let requestId = UUID()
        pendingResults[requestId] = originalResult
        let result: FlutterResult = { [weak self] value in
            guard let self = self, !self.closed,
                  let reply = self.pendingResults.removeValue(forKey: requestId) else { return }
            reply(value)
        }
        let args = call.arguments as? [String: Any] ?? [:]
        if call.method == "supportStatus" {
            result(Self.hasAccount ? (NGLRegionalOffline.isOfflineMapSupportedForCurrentTileServer()
                ? "SUPPORTED" : "TOMTOM_REQUIRED") : "NEXTBILLION_NOT_INITIALIZED")
            return
        }
        // Closing a page must still work after switching to an unsupported server.
        if call.method == "endDownloadPage" {
            if pageId == args["pageId"] as? String { closePage() }
            result(nil)
            return
        }
        guard Self.hasAccount else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Initialize NextBillion first", details: nil))
            return
        }
        guard NGLRegionalOffline.isOfflineMapSupportedForCurrentTileServer() else {
            result(FlutterError(code: "UNSUPPORTED_TILE_SERVER", message: "Regional Offline requires TomTom", details: nil))
            return
        }
        if call.method == "configure" {
            let requested = args["mapsBaseUrl"] as? String
                ?? NGLRegionalOfflineConfig.fromCurrentTileServer().mapsBaseUrl
            let baseURL = requested.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
            guard let url = URL(string: baseURL), ["http", "https"].contains(url.scheme ?? ""),
                  let host = url.host, !host.isEmpty else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected an HTTP(S) mapsBaseUrl", details: nil))
                return
            }
            if let configured = Self.configuredBaseURL ?? Self.configuringBaseURL, configured != baseURL {
                result(FlutterError(code: "CONFIGURATION_FAILED", message: "A different CDN requires app restart", details: nil))
                return
            }
            configure(baseURL: baseURL, useDefault: args["mapsBaseUrl"] == nil || args["mapsBaseUrl"] is NSNull,
                      result: result)
            return
        }
        guard Self.isConfigured else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Call RegionalOffline.configure first", details: nil))
            return
        }
        switch call.method {
        case "fetchRegionList":
            let completion: NGLRegionalOfflineRegionListCompletion = { items, error in
                if let error = error { result(Self.flutterError(error)); return }
                result((items ?? []).map(Self.catalogMap))
            }
            if let country = args["country"] as? String, !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                NGLRegionalOffline.fetchRegionList(country: country, completionHandler: completion)
            } else {
                NGLRegionalOffline.fetchRegionList(completionHandler: completion)
            }
        case "queryRegions":
            NGLRegionalOffline.queryRegions { snapshot, error in
                if let error = error { result(Self.flutterError(error)); return }
                guard let snapshot = snapshot else { result(FlutterError(code: "INVALID_RESPONSE", message: "Missing snapshot", details: nil)); return }
                result(["catalog": snapshot.catalog.map(Self.catalogMap),
                        "installed": snapshot.installed.map(Self.installedMap),
                        "previewStylesReady": snapshot.ambientReady, "displayReady": snapshot.glyphsReady,
                        "canBindOfflineMap": snapshot.stylesReady, "readinessIsBundleOnly": true])
            }
        case "listInstalledRegions":
            Self.readStorage(result) { NGLRegionalOffline.listInstalledRegions().map(Self.installedMap) }
        case "hasInstalledRegions":
            Self.readStorage(result) { NGLRegionalOffline.hasInstalledOfflineRegions() }
        case "offlinePreviewResourceStatus":
            Self.readStorage(result) {
                let status = NGLRegionalOffline.offlinePreviewResourceStatus()
                return ["previewBundleReady": status.previewBundleReady, "previewStylesReady": status.previewBundleReady,
                    "styleJsonCached": status.styleJsonCached, "spritesReady": status.spritesReady,
                    "tileJsonReady": status.tileJsonReady, "displayReady": status.previewBundleReady,
                    "canEnqueueRegionDownload": status.previewBundleReady, "canBindOfflineMap": status.previewBundleReady,
                    "cachedPreviewStyleNames": status.cachedPreviewStyleNames, "readinessIsBundleOnly": true]
            }
        case "getPreviewBundleImportStatus":
            // The published snapshot is engine-aware and does not probe marker files.
            result(Self.previewMap(NGLRegionalOffline.previewBundleImportStatus))
        case "getDownloadProgress": result(Self.progressMaps(NGLRegionalOffline.downloadProgress))
        case "beginDownloadPage":
            guard let id = args["pageId"] as? String, !id.isEmpty else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "pageId is required", details: nil)); return
            }
            guard let owner = registrar.viewController else {
                result(FlutterError(code: "NO_ACTIVITY", message: "A view controller is required", details: nil)); return
            }
            Self.activePageOwner?.closePage()
            pageId = id
            Self.activePageOwner = self
            NGLRegionalOffline.beginDownloadPage(withOwner: owner)
            result(nil)
        case "refreshEngine": NGLRegionalOffline.refreshEngineOnMapResume { result(nil) }
        case "fetchRegionDetail", "loadOfflineDetail", "downloadRegion", "controlDownload":
            guard let id = Self.validRegionId(args["regionId"]) else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "regionId must be a nonnegative 32-bit integer", details: nil)); return
            }
            switch call.method {
            case "fetchRegionDetail":
                NGLRegionalOffline.fetchRegionDetail(forRegionId: id) { detail, json, error in
                    if let error = error { result(Self.flutterError(error)); return }
                    result(Self.detailResultMap(detail, json))
                }
            case "loadOfflineDetail":
                Self.readStorage(result) {
                    let detail = NGLRegionalOffline.loadDetail(forRegionId: id)
                    return Self.detailResultMap(detail.detail, detail.detailJson)
                }
            case "downloadRegion":
                NGLRegionalOffline.downloadRegion(withId: id, clearBefore: args["clearBefore"] as? Bool ?? false) { error in
                    result(error.map(Self.flutterError))
                }
            default:
                let action: NGLRegionalOfflineDownloadAction
                switch args["action"] as? String {
                case "pause": action = .pause
                case "resume": action = .resume
                case "cancel": action = .cancel
                case "delete": action = .delete
                default: result(FlutterError(code: "INVALID_ARGUMENT", message: "Unknown download action", details: nil)); return
                }
                NGLRegionalOffline.controlDownload(forRegionId: id, action: action)
                result(nil)
            }
        default: result(FlutterMethodNotImplemented)
        }
    }

    private func configure(baseURL: String, useDefault: Bool, result: @escaping FlutterResult) {
        if Self.isConfigured {
            attachListeners()
            result(nil)
            return
        }
        Self.configurationCompletions.append { [weak self] in
            guard let self = self, !self.closed else { return }
            self.attachListeners()
            result(nil)
        }
        guard Self.configuringBaseURL == nil else { return }
        Self.configuringBaseURL = baseURL
        Self.storageQueue.async {
            // No database location is supplied: storage stays SDK-owned.
            if useDefault { NGLRegionalOffline.configure() }
            else { NGLRegionalOffline.configure(withMapsBaseUrl: baseURL) }
            DispatchQueue.main.async {
                Self.configuredBaseURL = baseURL
                Self.configuringBaseURL = nil
                let completions = Self.configurationCompletions
                Self.configurationCompletions.removeAll()
                completions.forEach { $0() }
            }
        }
    }

    private static func readStorage(_ result: @escaping FlutterResult, work: @escaping () -> Any?) {
        storageQueue.async {
            let value = work()
            DispatchQueue.main.async { result(value) }
        }
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        guard !closed else { return nil }
        sink = events
        attachListeners()
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        detachListeners()
        sink = nil
        return nil
    }
    func detachFromEngine(for registrar: FlutterPluginRegistrar) { dispose() }

    func dispose() {
        guard !closed else { return }
        closed = true
        pendingResults.removeAll()
        closePage()
        detachListeners()
        sink = nil
        events.setStreamHandler(nil)
        methods.setMethodCallHandler(nil)
    }
    private func closePage() {
        if pageId != nil, Self.activePageOwner === self {
            NGLRegionalOffline.endDownloadPage()
            Self.activePageOwner = nil
        }
        pageId = nil
    }
    private func attachListeners() {
        guard sink != nil, progressToken == nil, Self.isConfigured else { return }
        progressToken = NGLRegionalOffline.addDownloadProgressListener { [weak self] progress in
            self?.sink?(["type": "downloadProgress", "data": Self.progressMaps(progress)])
        }
        previewToken = NGLRegionalOffline.addPreviewBundleImportStatusListener { [weak self] status in
            self?.sink?(["type": "previewBundleImportStatus", "data": Self.previewMap(status)])
        }
    }
    private func detachListeners() {
        if let token = progressToken { NGLRegionalOffline.removeDownloadProgressListener(token) }
        if let token = previewToken { NGLRegionalOffline.removePreviewBundleImportStatusListener(token) }
        progressToken = nil
        previewToken = nil
    }
    private static var hasAccount: Bool { !(NGLAccountManager.accessToken ?? "").isEmpty }

    static func validRegionId(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              number.doubleValue.isFinite,
              number.doubleValue >= 0, number.doubleValue <= Double(Int32.max),
              number.doubleValue == Double(number.int64Value) else { return nil }
        return number.intValue
    }

    static func flutterError(_ error: Error) -> FlutterError {
        let native = error as NSError
        var code = "REGIONAL_OFFLINE_ERROR"
        if native.domain == NGLRegionalOfflineErrorDomain {
            let codes = ["NETWORK", "STORAGE", "INVALID_REGION", "PREVIEW_NOT_READY", "STYLE_NOT_CACHED",
                         "NO_INSTALLED_REGIONS", "CANCELLED", "UNKNOWN", "NETWORK_UNAVAILABLE", "REQUEST_TIMED_OUT",
                         "HTTP_STATUS", "INVALID_RESPONSE", "FILE_SYSTEM", "INSUFFICIENT_STORAGE", "INVALID_PACKAGE",
                         "PACKAGE_DECOMPRESSION", "PACKAGE_INSTALLATION", "DOWNLOAD_ALREADY_ACTIVE",
                         "PREVIEW_DATABASE_OPEN", "PREVIEW_ROLLBACK_FAILED", "UNSUPPORTED_TILE_SERVER"]
            if native.code > 0 && native.code <= codes.count { code = codes[native.code - 1] }
        } else if native.domain == NGLErrorDomain && native.code == 12 { code = "UNSUPPORTED_TILE_SERVER" }
        return FlutterError(code: code, message: native.localizedDescription, details: errorMap(native))
    }
    private static func codecValue(_ value: Any) -> Any {
        if let error = value as? NSError { return errorMap(error) }
        if let url = value as? URL { return url.absoluteString }
        if let map = value as? [String: Any] { return map.mapValues(codecValue) }
        if let array = value as? [Any] { return array.map(codecValue) }
        if value is String || value is NSNumber || value is NSNull { return value }
        return String(describing: value)
    }
    private static func errorMap(_ error: NSError) -> [String: Any] {
        ["domain": error.domain, "nativeCode": error.code, "message": error.localizedDescription,
         "userInfo": error.userInfo.mapValues(codecValue)]
    }
    private static func nullable(_ value: Any?) -> Any { value ?? NSNull() }
    private static func catalogMap(_ row: NGLRegionalOfflineRegionListItem) -> [String: Any] {
        ["regionId": row.regionId, "name": row.name, "adminL0": row.adminL0, "adminL1": row.adminL1,
         "adminL3": row.adminL3, "version": nullable(row.version), "totalSize": row.totalSize,
         "tileCount": row.tileCount, "timestamp": nullable(row.timestamp)]
    }
    private static func installedMap(_ row: NGLRegionalOfflineInstalledRegionSummary) -> [String: Any] {
        ["regionId": row.regionId, "displayName": row.displayName, "packageCount": row.packageCount,
         "totalBytes": row.totalBytes, "regionVersion": nullable(row.regionVersion), "allTarsOk": row.allTarsOk,
         "dataSourceId": row.dataSourceId, "dataSourceLabel": row.dataSourceLabel]
    }
    private static func detailResultMap(_ detail: NGLRegionalOfflineRegionDetail?, _ json: String?) -> [String: Any] {
        ["detailJson": nullable(json), "detail": nullable(detail.map { d -> [String: Any] in
            ["regionId": d.regionId, "version": nullable(d.version), "country": nullable(d.country),
             "adminL1": nullable(d.adminL1), "adminL2": nullable(d.adminL2), "adminL3": nullable(d.adminL3),
             "timestamp": nullable(d.timestamp), "totalSize": d.totalSize,
             "packages": d.tarList.map { p -> [String: Any] in ["tarName": p.tarName, "version": p.version,
                 "tarSize": p.tarSize, "timestamp": nullable(p.timestamp), "minZoom": p.minZoom, "maxZoom": p.maxZoom] }]
        })]
    }
    private static func progressMaps(_ progress: [NSNumber: NGLRegionalOfflineDownloadProgress]) -> [[String: Any]] {
        let names = ["QUEUED", "PREPARING_OFFLINE_DISPLAY", "DOWNLOADING_PACKAGE", "PAUSED_USER",
                     "PAUSED_NETWORK", "FAILED_STORAGE", "FAILED", "COMPLETED", "CANCELLED"]
        return progress.values.sorted { $0.regionId < $1.regionId }.map { p in
            let index = Int(p.state.rawValue)
            return ["regionId": p.regionId, "state": index >= 0 && index < names.count ? names[index] : "UNKNOWN",
                    "downloadedBytes": p.downloadedBytes, "totalBytes": p.totalBytes,
                    "currentPackageName": nullable(p.currentPackageName), "errorMessage": nullable(p.errorMessage),
                    "error": nullable(p.error.map { errorMap($0 as NSError) }), "percent": p.percent]
        }
    }
    private static func previewMap(_ status: NGLRegionalOfflinePreviewBundleImportStatus) -> [String: Any] {
        ["previewBundleReady": status.previewBundleReady, "ensuring": status.ensuring,
         "waitingForNetwork": status.waitingForNetwork, "lastErrorCode": nullable(status.lastErrorCode),
         "lastErrorMessage": nullable(status.lastErrorMessage), "recoverable": status.recoverable]
    }
}
