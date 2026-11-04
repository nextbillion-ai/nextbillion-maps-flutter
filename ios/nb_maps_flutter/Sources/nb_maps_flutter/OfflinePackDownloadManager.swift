//
//  OfflinePackDownloadManager.swift
//  location
//
//  Created by Patryk on 03/06/2020.
//

import Flutter
import Foundation
import Nbmap

class OfflinePackDownloader {
    let id = UUID().hashValue
    // MARK: Properties

    let ownerId: UUID
    private var result: FlutterResult?
    private let channelHandler: OfflineChannelHandler
    private let regionDefinition: OfflineRegionDefinition
    private let metadata: [String: Any]

    /// Currently managed pack
    private var pack: NGLOfflinePack?

    /// This variable is set to true when this downloader has finished downloading and called the result method. It is used to prevent
    /// the result method being called multiple times
    private var isCompleted = false
    private var didReply = false

    // MARK: Initializers

    init(
        result: @escaping FlutterResult,
        ownerId: UUID,
        channelHandler: OfflineChannelHandler,
        regionDefintion: OfflineRegionDefinition,
        metadata: [String: Any]
    ) {
        self.result = result
        self.ownerId = ownerId
        self.channelHandler = channelHandler
        regionDefinition = regionDefintion
        self.metadata = metadata

        setupNotifications()
    }

    deinit {
        print("Removing offline pack notification observers")
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Public methods

    func download() -> Int {
        let storage = NGLOfflineStorage.shared
        // While the Android SDK generates a region ID in createOfflineRegion, the iOS
        // SDK does not have this feature. Therefore, we generate a region ID here.
        let regionData = OfflineRegion(id: id, metadata: metadata, definition: regionDefinition)
        let tilePyramidRegion = regionDefinition.toNGLTilePyramidOfflineRegion()
        storage
            .addPack(for: tilePyramidRegion,
                     withContext: regionData.prepareContext()) { [weak self] pack, error in
            guard let self = self, !self.isCompleted else {
                if let pack = pack, pack.state != .invalid { pack.suspend() }
                return
            }
            if let pack = pack {
                self.onPackCreated(pack: pack)
            } else {
                self.onPackCreationError(error: error)
            }
        }
        return id
    }

    // MARK: Pack management

    private func onPackCreated(pack: NGLOfflinePack) {
        if let region = OfflineRegion.fromOfflinePack(pack),
           let regionData = try? JSONSerialization.data(withJSONObject: region.toDictionary()) {
            // Start downloading
            self.pack = pack
            // Provide region with generated
            replyOnce(String(data: regionData, encoding: .utf8))
            channelHandler.onStart()
            pack.resume()
        } else {
            onPackCreationError(error: OfflinePackError.invalidPackData)
        }
    }

    private func onPackCreationError(error: Error?) {
        isCompleted = true
        let failure = error.map(RegionalOfflineHandler.flutterError)
        replyOnce(FlutterError(code: failure?.code == "UNSUPPORTED_TILE_SERVER"
            ? "UNSUPPORTED_TILE_SERVER" : "nbmapsInvalidRegionDefinition",
            message: error?.localizedDescription, details: failure?.details))
        channelHandler.dispose()
        OfflineManagerUtils.releaseDownloader(id: id)
    }

    private func replyOnce(_ value: Any?) {
        guard !didReply else { return }
        didReply = true
        let reply = result
        result = nil
        reply?(value)
    }

    func dispose() {
        isCompleted = true
        result = nil
        NotificationCenter.default.removeObserver(self)
        if let pack = pack, pack.state != .invalid { pack.suspend() }
        pack = nil
        channelHandler.dispose()
    }

    @objc private func tileServerChanged() {
        guard pack != nil, !isCompleted,
              !NGLRegionalOffline.isOfflineMapSupportedForCurrentTileServer() else { return }
        isCompleted = true
        channelHandler.onError(errorCode: "UNSUPPORTED_TILE_SERVER",
            errorMessage: "The offline download was paused because the active tile server is not TomTom.",
            errorDetails: nil)
        OfflineManagerUtils.releaseDownloader(id: id)
    }

    // MARK: Progress obseration

    @objc private func onPackDownloadProgress(notification: NSNotification) {
        guard !isCompleted else { return }
        // Verify if correct pack is checked
        guard let pack = notification.object as? NGLOfflinePack,
              verifyPack(pack: pack) else { return }
        // Calculate progress of downloading
        let packProgress = pack.progress
        let downloadProgress = calculateDownloadingProgress(
            requiredResourceCount: packProgress.countOfResourcesExpected,
            completedResourceCount: packProgress.countOfResourcesCompleted
        )
        // Check if downloading is complete
        if pack.state == .complete {
            print("Region downloaded successfully")
            // set download state to inactive
            // This can be called multiple times but result can only be called once. We use this
            // check to ensure that
            guard !isCompleted else { return }
            isCompleted = true
            channelHandler.onSuccess()
            if let region = OfflineRegion.fromOfflinePack(pack) {
                OfflineManagerUtils.releaseDownloader(id: region.id)
            }
        } else {
            print("Region download progress \(downloadProgress)")
            channelHandler.onProgress(progress: downloadProgress)
        }
    }

    @objc private func onPackDownloadError(notification: NSNotification) {
        guard let pack = notification.object as? NGLOfflinePack,
              verifyPack(pack: pack) else { return }
        let error = notification.userInfo?[NGLOfflinePackUserInfoKey.error] as? NSError
        print("Pack download error: \(String(describing: error?.localizedDescription))")
        // set download state to inactive
        guard !isCompleted else { return }
        isCompleted = true
        let failure = error.map(RegionalOfflineHandler.flutterError)
        channelHandler.onError(
            errorCode: failure?.code == "UNSUPPORTED_TILE_SERVER" ? "UNSUPPORTED_TILE_SERVER" : "Downloading error",
            errorMessage: error?.localizedDescription,
            errorDetails: failure?.details
        )
        pack.suspend()
        OfflineManagerUtils.releaseDownloader(id: id)
    }

    @objc private func onMaximumAllowedNbMapsTiles(notification: NSNotification) {
        guard let pack = notification.object as? NGLOfflinePack,
              verifyPack(pack: pack) else { return }
        let maximumCount = (notification.userInfo?[NGLOfflinePackUserInfoKey.maximumCount]
            as? NSNumber)?.uint64Value ?? 0
        print("NbMaps tile count limit exceeded: \(maximumCount)")
        // set download state to inactive
        guard !isCompleted else { return }
        isCompleted = true
        channelHandler.onError(
            errorCode: "nbmapsTileCountLimitExceeded",
            errorMessage: "NbMaps tile count limit exceeded: \(maximumCount)",
            errorDetails: nil
        )
        pack.suspend()
        OfflineManagerUtils.releaseDownloader(id: id)
    }

    // MARK: Util methods

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(tileServerChanged),
            name: Notification.Name("NGLTileServerOptionsDidChangeNotification"), object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onPackDownloadProgress(notification:)),
            name: NSNotification.Name.NGLOfflinePackProgressChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onPackDownloadError(notification:)),
            name: NSNotification.Name.NGLOfflinePackError,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onMaximumAllowedNbMapsTiles(notification:)),
            name: NSNotification.Name.NGLOfflinePackMaximumNbmapTilesReached,
            object: nil
        )
    }

    /// Since NotificationCenter will send notifications about all packs downloads we need to make sure we only handle packs
    /// managed by this downloader. So this method checks if the pack we got from a notification is the same as the pack being
    /// managed by this downloader and if it is it returns true. Otherwise it returns false
    private func verifyPack(pack: NGLOfflinePack) -> Bool {
        guard let currentlyManagedPack = self.pack else {
            // No pack is being managed yet
            return false
        }
        // We can tell whether 2 packs are the same by comparing metadata we assigned earlier
        return pack.state != .invalid && currentlyManagedPack.state != .invalid
            && pack === currentlyManagedPack
    }

    private func calculateDownloadingProgress(
        requiredResourceCount: UInt64,
        completedResourceCount: UInt64
    ) -> Double {
        return requiredResourceCount > 0
            ? 100.0 * Double(completedResourceCount) / Double(requiredResourceCount)
            : 0.0
    }
}

enum OfflinePackError: Error {
    case invalidPackData
}
