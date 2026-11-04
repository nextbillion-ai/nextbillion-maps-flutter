import Flutter
import Foundation
import Nbmap
import UIKit

public class SwiftNbMapsFlutterPlugin: NSObject, FlutterPlugin {
    private let ownerId = UUID()
    private var channels: [FlutterMethodChannel] = []
    private var regionalOffline: RegionalOfflineHandler?
    private var downloadChannels: [UUID: OfflineChannelHandler] = [:]
    private var pendingResults: [UUID: FlutterResult] = [:]
    private var closed = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = SwiftNbMapsFlutterPlugin()
        registrar.publish(plugin)
        plugin.registerChannels(with: registrar)
    }

    private func registerChannels(with registrar: FlutterPluginRegistrar) {
        regionalOffline = RegionalOfflineHandler.registerHandler(with: registrar)
        let instance = NbMapFactory(withRegistrar: registrar)
        registrar.register(instance, withId: "plugins.flutter.io/nb_maps_flutter")

        let channel = FlutterMethodChannel(
            name: "plugins.flutter.io/nb_maps_flutter",
            binaryMessenger: registrar.messenger()
        )

        let nextBillionChannel = FlutterMethodChannel(
            name: "plugins.flutter.io/nextbillion_init",
            binaryMessenger: registrar.messenger()
        )

        channels = [channel, nextBillionChannel]
        nextBillionChannel.setMethodCallHandler { call, result in
            switch call.method {
            case "nextbillion/init_nextbillion":
                if let args = call.arguments as? [String: Any] {
                    if let token = args["accessKey"] as? String? {
                        NGLAccountManager.accessToken = token
                    }

                    let libraryBundle = Bundle(for: SwiftNbMapsFlutterPlugin.self)

                    let version = libraryBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "Unknown"
                    let buildNumber = libraryBundle.object(forInfoDictionaryKey: "CFBundleVersion") ?? "Unknown"

                    let crossPlatformInfo = "Flutter-\(version)-\(buildNumber)"
                    NGLAccountManager.crossPlatformInfo = crossPlatformInfo
                }
                result(nil)
            case "nextbillion/init_nextbillion_tile_server":
                if let args = call.arguments as? [String: Any] {
                    guard let server = Convert.tileServer(args["server"]) else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "Unknown tile server", details: nil))
                        return
                    }
                    if let token = args["accessKey"] as? String? {
                        NGLAccountManager.accessToken = token
                    }
                    NGLAccountManager.use(server)
                    
                    let libraryBundle = Bundle(for: SwiftNbMapsFlutterPlugin.self)
                   
                    let version = libraryBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "Unknown"
                    let buildNumber = libraryBundle.object(forInfoDictionaryKey: "CFBundleVersion") ?? "Unknown"
                 
                    let crossPlatformInfo: String = "Flutter-\(version)-\(buildNumber)"
                    NGLAccountManager.crossPlatformInfo = crossPlatformInfo
                }
                result(nil)
            case "nextbillion/get_access_key":
                result(NGLAccountManager.accessToken)
            case "nextbillion/set_access_key":
                if let args = call.arguments as? [String: Any] {
                    if let token = args["accessKey"] as? String? {
                        NGLAccountManager.accessToken = token
                    }
                }
                result(nil)
            case "nextbillion/get_base_uri":
                result(NGLAccountManager.apiBaseURL()?.absoluteString)
            case "nextbillion/set_base_uri":
                if let args = call.arguments as? [String: Any] {
                    guard let baseUri = args["baseUri"] as? String,
                          let url = URL(string: baseUri),
                          ["http", "https"].contains(url.scheme ?? ""), url.host != nil else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected an HTTP(S) baseUri", details: nil))
                        return
                    }
                    NGLAccountManager.setAPIBaseURL(url)
                }
                result(nil)
            case "nextbillion/set_key_header_name":
                let args = call.arguments as? [String: Any]
                NGLAccountManager.apiKeyHeaderName = args?["apiKeyHeaderName"] as? String
                result(nil)
            case "nextbillion/get_key_header_name":
                result(NGLAccountManager.apiKeyHeaderName)
            case "nextbillion/get_nb_id":
                result(NGLAccountManager.nbId)
            case "nextbillion/get_user_id":
                result(NGLAccountManager.userId)
            case "nextbillion/set_user_id":
                if let args = call.arguments as? [String: Any] {
                    if let userId = args["userId"] as? String? {
                        NGLAccountManager.userId = userId
                    }
                }
                result(nil)
            case "nextbillion/predefined_styles":
                let styles = NGLStyle.predefinedStyles()
                var serializableStyles: [[String: Any]] = []
                
                for style in styles {
                    let styleDict: [String: Any] = [
                        "name": style.name,
                        "url": style.url.absoluteString,
                        "version": style.version
                    ]
                    serializableStyles.append(styleDict)
                }
                
                result(serializableStyles)

            case "nextbillion/switch_tile_server":
                // Process-wide configuration; select before constructing maps.
                // Existing MapView cross-provider switching is out of scope.
                guard let args = call.arguments as? [String: Any],
                      let server = Convert.tileServer(args["server"]) else {
                    result(false)
                    return
                }
                NGLAccountManager.use(server)
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        let ownerId = self.ownerId
        channel.setMethodCallHandler { [weak self] methodCall, originalResult in
            guard let self = self, !self.closed else { return }
            let result = self.guardedResult(originalResult)
            switch methodCall.method {
            case "setHttpHeaders":
                guard let arguments = methodCall.arguments as? [String: Any],
                      let headers = arguments["headers"] as? [String: String]
                else {
                    result(FlutterError(
                        code: "setHttpHeadersError",
                        message: "could not decode arguments",
                        details: nil
                    ))
                    return
                }
                let sessionConfig = URLSessionConfiguration.default
                sessionConfig.httpAdditionalHeaders = headers // your headers here
                NGLNetworkConfiguration.sharedManager.sessionConfiguration = sessionConfig
                result(nil)
            case "installOfflineMapTiles":
                guard let arguments = methodCall.arguments as? [String: String],
                      let tilesdb = arguments["tilesdb"], !tilesdb.isEmpty else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "tilesdb is required", details: nil))
                    return
                }
                do {
                    try self.installOfflineMapTiles(registrar: registrar, tilesdb: tilesdb, result: result)
                } catch {
                    result(FlutterError(code: "INSTALL_OFFLINE_TILES", message: error.localizedDescription, details: nil))
                }
            case "downloadOfflineRegion":
                // Get download region arguments from caller
                guard let args = methodCall.arguments as? [String: Any],
                      let definitionDictionary = args["definition"] as? [String: Any],
                      let metadata = args["metadata"] as? [String: Any],
                      let defintion = OfflineRegionDefinition.fromDictionary(definitionDictionary),
                      let channelName = args["channelName"] as? String
                else {
                    print(
                        "downloadOfflineRegion unexpected arguments: \(String(describing: methodCall.arguments))"
                    )
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid offline region arguments", details: nil))
                    return
                }
                // Prepare channel
                let channelHandler = OfflineChannelHandler(
                    messenger: registrar.messenger(),
                    channelName: channelName,
                    enabled: args["observe"] as? Bool ?? true
                )
                if args["observe"] as? Bool != false {
                    let id = UUID()
                    self.downloadChannels[id] = channelHandler
                    channelHandler.onDisposed = { [weak self] in self?.downloadChannels.removeValue(forKey: id) }
                }
                OfflineManagerUtils.downloadRegion(
                    definition: defintion,
                    metadata: metadata,
                    result: result,
                    ownerId: ownerId,
                    channelHandler: channelHandler
                )
            case "setOfflineTileCountLimit":
                guard let arguments = methodCall.arguments as? [String: Any],
                      let limit = arguments["limit"] as? UInt64
                else {
                    result(FlutterError(
                        code: "SetOfflineTileCountLimitError",
                        message: "could not decode arguments",
                        details: nil
                    ))
                    return
                }
                OfflineManagerUtils.setOfflineTileCountLimit(result: result, maximumCount: limit)
            case "getListOfRegions":
                // Note: this does not download anything from internet, it only fetches data drom database
                OfflineManagerUtils.regionsList(result: result)
            case "deleteOfflineRegion":
                guard let args = methodCall.arguments as? [String: Any],
                      let id = args["id"] as? Int
                else {
                    result(nil)
                    return
                }
                OfflineManagerUtils.deleteRegion(result: result, id: id)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        closed = true
        pendingResults.removeAll()
        regionalOffline?.dispose()
        regionalOffline = nil
        OfflineManagerUtils.releaseDownloaders(ownerId: ownerId)
        let pendingChannels = Array(downloadChannels.values)
        pendingChannels.forEach { $0.dispose() }
        downloadChannels.removeAll()
        channels.forEach { $0.setMethodCallHandler(nil) }
        channels.removeAll()
    }

    private func guardedResult(_ original: @escaping FlutterResult) -> FlutterResult {
        let id = UUID()
        pendingResults[id] = original
        return { [weak self] value in
            let deliver = { [weak self] in
                guard let self = self, !self.closed,
                      let reply = self.pendingResults.removeValue(forKey: id) else { return }
                reply(value)
            }
            if Thread.isMainThread { deliver() }
            else { DispatchQueue.main.async(execute: deliver) }
        }
    }

    private func installOfflineMapTiles(registrar: FlutterPluginRegistrar, tilesdb: String,
                                        result: @escaping FlutterResult) throws {
        guard let path = Self.getTilesDbPath(registrar: registrar, tilesdb: tilesdb),
              FileManager.default.fileExists(atPath: path) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("nbmap_import_" + UUID().uuidString)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let database = directory.appendingPathComponent("cache.db")
                try FileManager.default.copyItem(atPath: path, toPath: database.path)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, !self.closed else {
                        try? FileManager.default.removeItem(at: directory)
                        return
                    }
                    // The SDK owns the default active path and validates merge
                    // compatibility (2.3.2 accepts v6, not v5 input databases).
                    NGLOfflineStorage.shared.addContents(of: database) { _, _, error in
                        try? FileManager.default.removeItem(at: directory)
                        result(error.map { FlutterError(code: "INSTALL_OFFLINE_TILES",
                            message: $0.localizedDescription, details: nil) })
                    }
                }
            } catch {
                try? FileManager.default.removeItem(at: directory)
                result(FlutterError(code: "INSTALL_OFFLINE_TILES", message: error.localizedDescription, details: nil))
            }
        }
    }

    private static func getTilesDbPath(registrar: FlutterPluginRegistrar,
                                       tilesdb: String) -> String? {
        if tilesdb.starts(with: "/") {
            return tilesdb
        } else {
            let key = registrar.lookupKey(forAsset: tilesdb)
            return Bundle.main.path(forResource: key, ofType: nil)
        }
    }
}
