import Foundation
import Nbmap

class OfflineRegionDefinition {
    let bounds: [[Double]]
    let mapStyleUrl: URL
    let minZoom: Double
    let maxZoom: Double

    init(bounds: [[Double]], mapStyleUrl: URL, minZoom: Double, maxZoom: Double) {
        self.bounds = bounds
        self.mapStyleUrl = mapStyleUrl
        self.minZoom = minZoom
        self.maxZoom = maxZoom
    }

    func getBounds() -> NGLCoordinateBounds {
        return NGLCoordinateBounds(
            sw: CLLocationCoordinate2D(latitude: bounds[0][0], longitude: bounds[0][1]),
            ne: CLLocationCoordinate2D(latitude: bounds[1][0], longitude: bounds[1][1])
        )
    }

    static func fromDictionary(_ jsonDict: [String: Any]) -> OfflineRegionDefinition? {
        guard let bounds = jsonDict["bounds"] as? [[Double]],
              let mapStyleUrlString = jsonDict["mapStyleUrl"] as? String,
              let mapStyleUrl = URL(string: mapStyleUrlString),
              let minZoom = jsonDict["minZoom"] as? Double,
              let maxZoom = jsonDict["maxZoom"] as? Double,
              bounds.count == 2, bounds.allSatisfy({ $0.count == 2 && $0.allSatisfy({ $0.isFinite }) }),
              bounds.allSatisfy({ (-90...90).contains($0[0]) && (-180...180).contains($0[1]) }),
              bounds[0][0] <= bounds[1][0], minZoom.isFinite, maxZoom.isFinite,
              minZoom >= 0, maxZoom >= minZoom
        else { return nil }
        return OfflineRegionDefinition(
            bounds: bounds,
            mapStyleUrl: mapStyleUrl,
            minZoom: minZoom,
            maxZoom: maxZoom
        )
    }

    func toDictionary() -> [String: Any] {
        return [
            "bounds": bounds,
            "mapStyleUrl": mapStyleUrl.absoluteString,
            "minZoom": minZoom,
            "maxZoom": maxZoom,
        ]
    }

    func toNGLTilePyramidOfflineRegion() -> NGLTilePyramidOfflineRegion {
        return NGLTilePyramidOfflineRegion(
            styleURL: mapStyleUrl,
            bounds: getBounds(),
            fromZoomLevel: minZoom,
            toZoomLevel: maxZoom
        )
    }
}
