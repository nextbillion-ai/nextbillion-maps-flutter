import Foundation
import Nbmap

/**
 * Utility class for decoding encoded polyline strings into geometry objects.
 * Supports Google's polyline encoding algorithm.
 */
class PolylineDecoder {
    
    /**
     * Decodes an encoded polyline string into an array of CLLocationCoordinate2D.
     *
     * @param encodedString The encoded polyline string
     * @param precision The precision used for encoding (default is 5)
     * @return Array of CLLocationCoordinate2D
     */
    static func decodePolyline(_ encodedString: String, precision: Int = 5) -> [CLLocationCoordinate2D] {
        guard !encodedString.isEmpty else { 

            return [] 
        }
        

        
        var coordinates: [CLLocationCoordinate2D] = []
        var index = encodedString.startIndex
        var lat = 0
        var lng = 0
        let factor = pow(10.0, Double(precision))
        
        while index < encodedString.endIndex {
            var b: Int
            var shift = 0
            var result = 0
            
            // Decode latitude
            repeat {
                b = Int(encodedString[index].asciiValue! - 63)
                index = encodedString.index(after: index)
                result |= (b & 0x1f) << shift
                shift += 5
            } while b >= 0x20
            
            let dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            lat += dlat
            
            shift = 0
            result = 0
            
            // Decode longitude
            repeat {
                b = Int(encodedString[index].asciiValue! - 63)
                index = encodedString.index(after: index)
                result |= (b & 0x1f) << shift
                shift += 5
            } while b >= 0x20
            
            let dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            lng += dlng
            
            let coordinate = CLLocationCoordinate2D(
                latitude: Double(lat) / factor,
                longitude: Double(lng) / factor
            )
            coordinates.append(coordinate)
        }
        

        if coordinates.isEmpty {

        }
        
        return coordinates
    }
    
    /**
     * Encodes an array of CLLocationCoordinate2D into a polyline string.
     *
     * @param coordinates Array of CLLocationCoordinate2D
     * @param precision The precision to use for encoding (default is 5)
     * @return Encoded polyline string
     */
    static func encodePolyline(_ coordinates: [CLLocationCoordinate2D], precision: Int = 5) -> String {
        guard !coordinates.isEmpty else { return "" }
        
        var result = ""
        let factor = pow(10.0, Double(precision))
        
        var prevLat = 0
        var prevLng = 0
        
        for coordinate in coordinates {
            let lat = Int(round(coordinate.latitude * factor))
            let lng = Int(round(coordinate.longitude * factor))
            
            let deltaLat = lat - prevLat
            let deltaLng = lng - prevLng
            
            result += encodeSignedNumber(deltaLat)
            result += encodeSignedNumber(deltaLng)
            
            prevLat = lat
            prevLng = lng
        }
        
        return result
    }
    
    private static func encodeSignedNumber(_ num: Int) -> String {
        var sgnNum = num << 1
        if num < 0 {
            sgnNum = ~sgnNum
        }
        return encodeNumber(sgnNum)
    }
    
    private static func encodeNumber(_ num: Int) -> String {
        var result = ""
        var n = num
        while n >= 0x20 {
            result += String(Character(UnicodeScalar(0x20 | (n & 0x1f) + 63)!))
            n >>= 5
        }
        result += String(Character(UnicodeScalar(n + 63)!))
        return result
    }
    
    /**
     * Processes a GeoJSON feature dictionary to decode encoded geometry if present.
     * If the feature's geometry contains encodedGeometry property, it will be decoded
     * and replaced with actual coordinates.
     */
    static func processEncodedGeometry(_ featureDict: [String: Any]) -> [String: Any] {
        var processedFeature = featureDict
        
        guard let geometry = featureDict["geometry"] as? [String: Any],
              let geometryType = geometry["type"] as? String,
              geometryType == "LineString" else {
            return featureDict
        }
        
        // Check if this geometry has encoded data
        if let encodedGeometry = geometry["encodedGeometry"] as? String {
            let precision = geometry["encodedGeometryPrecision"] as? Int ?? 5
            
            // Decode the geometry
            let coordinates = decodePolyline(encodedGeometry, precision: precision)
            
            // Check if we have valid coordinates
            guard !coordinates.isEmpty else {

                return featureDict
            }
            
            // Convert to GeoJSON coordinate format [[lng, lat], [lng, lat], ...]
            let geoJsonCoordinates = coordinates.map { [$0.longitude, $0.latitude] }
            

            
            // Update the geometry with decoded coordinates
            var updatedGeometry = geometry
            updatedGeometry["coordinates"] = geoJsonCoordinates
            updatedGeometry.removeValue(forKey: "encodedGeometry")
            updatedGeometry.removeValue(forKey: "encodedGeometryPrecision")
            
            processedFeature["geometry"] = updatedGeometry
        }
        
        return processedFeature
    }
    
    /**
     * Process encoded geometry in a FeatureCollection GeoJSON string.
     * This method handles multiple features that may contain encoded geometry.
     */
    static func processEncodedGeometryInFeatureCollection(geojson: String) -> String {
        do {
            guard let data = geojson.data(using: .utf8),
                  let featureCollectionDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {

                return geojson
            }
            
            // Check if this is a FeatureCollection
            guard let type = featureCollectionDict["type"] as? String, type == "FeatureCollection" else {

                let processedDict = processEncodedGeometry(featureCollectionDict)
                let processedData = try JSONSerialization.data(withJSONObject: processedDict)
                return String(data: processedData, encoding: .utf8) ?? geojson
            }
            
            // Process each feature in the collection
            guard let features = featureCollectionDict["features"] as? [[String: Any]] else {

                return geojson
            }
            
            let processedFeatures = features.map { feature in
                return processEncodedGeometry(feature)
            }
            
            var processedFeatureCollection = featureCollectionDict
            processedFeatureCollection["features"] = processedFeatures
            
            let processedData = try JSONSerialization.data(withJSONObject: processedFeatureCollection)
            let processedGeoJson = String(data: processedData, encoding: .utf8) ?? geojson
            

            return processedGeoJson
            
        } catch {

            return geojson
        }
    }
}
