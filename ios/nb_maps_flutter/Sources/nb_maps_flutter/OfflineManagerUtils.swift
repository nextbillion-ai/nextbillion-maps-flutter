//
//  OfflineManagerUtils.swift
//  location
//
//  Created by Patryk on 02/06/2020.
//

import Flutter
import Foundation
import Nbmap

class OfflineManagerUtils {
    static var activeDownloaders: [Int: OfflinePackDownloader] = [:]

    static func downloadRegion(
        definition: OfflineRegionDefinition,
        metadata: [String: Any],
        result: @escaping FlutterResult,
        ownerId: UUID,
        channelHandler: OfflineChannelHandler
    ) {
        // Prepare downloader
        let downloader = OfflinePackDownloader(
            result: result,
            ownerId: ownerId,
            channelHandler: channelHandler,
            regionDefintion: definition,
            metadata: metadata
        )

        // Download region
        // Retain before starting: a rejected pack can complete immediately.
        activeDownloaders[downloader.id] = downloader
        _ = downloader.download()
    }

    static func regionsList(result: @escaping FlutterResult) {
        let offlineStorage = NGLOfflineStorage.shared
        guard let packs = offlineStorage.packs else {
            result("[]")
            return
        }
        let regionsArgs = packs.compactMap { pack in
            OfflineRegion.fromOfflinePack(pack)?.toDictionary()
        }
        guard let regionsArgsJsonData = try? JSONSerialization.data(withJSONObject: regionsArgs),
              let regionsArgsJsonString = String(data: regionsArgsJsonData, encoding: .utf8)
        else {
            result(FlutterError(code: "RegionListError", message: nil, details: nil))
            return
        }
        result(regionsArgsJsonString)
    }

    static func setOfflineTileCountLimit(result: @escaping FlutterResult, maximumCount: UInt64) {
        let offlineStorage = NGLOfflineStorage.shared
        offlineStorage.setMaximumAllowedNbmapTiles(maximumCount)
        result(nil)
    }

    static func deleteRegion(result: @escaping FlutterResult, id: Int) {
        let offlineStorage = NGLOfflineStorage.shared
        guard let pacs = offlineStorage.packs else {
            result(FlutterError(code: "DeleteRegionError", message: "Offline packs are not loaded", details: nil))
            return
        }
        let packToRemove = pacs.first(where: { pack -> Bool in
            let contextJsonObject = try? JSONSerialization.jsonObject(with: pack.context)
            let contextJsonDict = contextJsonObject as? [String: Any]
            if let regionId = contextJsonDict?["id"] as? Int {
                return regionId == id
            } else {
                return false
            }
        })
        if let packToRemoveUnwrapped = packToRemove {
            // deletion is only safe if the download is suspended
            packToRemoveUnwrapped.suspend()
            activeDownloaders[id]?.dispose()
            OfflineManagerUtils.releaseDownloader(id: id)

            offlineStorage.removePack(packToRemoveUnwrapped) { error in
                if let error = error {
                    result(FlutterError(
                        code: "DeleteRegionError",
                        message: error.localizedDescription,
                        details: nil
                    ))
                } else {
                    result(nil)
                }
            }
        } else {
            result(FlutterError(
                code: "DeleteRegionError",
                message: "There is no region with given id to delete",
                details: nil
            ))
        }
    }

    static func releaseDownloaders(ownerId: UUID) {
        let owned = activeDownloaders.values.filter { $0.ownerId == ownerId }
        for downloader in owned {
            downloader.dispose()
            activeDownloaders.removeValue(forKey: downloader.id)
        }
    }

    /// Removes downloader from cache so it's memory can be deallocated
    static func releaseDownloader(id: Int) {
        activeDownloaders.removeValue(forKey: id)
    }
}
