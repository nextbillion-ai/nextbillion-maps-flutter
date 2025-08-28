package ai.nextbillion.maps_flutter;

import ai.nextbillion.kits.geojson.LineString;
import ai.nextbillion.kits.geojson.Point;
import com.google.gson.Gson;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Utility class for decoding encoded polyline strings into geometry objects.
 * Supports Google's polyline encoding algorithm.
 */
public class PolylineDecoder {

    /**
     * Decodes an encoded polyline string into a LineString geometry.
     * 
     * @param encodedString The encoded polyline string
     * @param precision The precision used for encoding (default is 5)
     * @return LineString geometry object
     */
    public static LineString decodePolyline(String encodedString, int precision) {
        if (encodedString == null || encodedString.isEmpty()) {
            android.util.Log.d("GeometryDecoder", "Empty encoded string");
            return null;
        }

        android.util.Log.d("GeometryDecoder", "Decoding string: " + encodedString + " with precision: " + precision);

        List<Point> points = decodePolylineToPoints(encodedString, precision);
        if (points.isEmpty()) {
            android.util.Log.w("GeometryDecoder", "No points decoded from string: " + encodedString);
            return null;
        }

        android.util.Log.d("GeometryDecoder", "Decoded " + points.size() + " points");
        return LineString.fromLngLats(points);
    }

    /**
     * Decodes an encoded polyline string into a list of Point objects.
     * 
     * @param encodedString The encoded polyline string
     * @param precision The precision used for encoding (default is 5)
     * @return List of Point objects
     */
    public static List<Point> decodePolylineToPoints(String encodedString, int precision) {
        List<Point> points = new ArrayList<>();
        
        if (encodedString == null || encodedString.isEmpty()) {
            return points;
        }

        int index = 0;
        int len = encodedString.length();
        int lat = 0;
        int lng = 0;
        double factor = Math.pow(10, precision);

        while (index < len) {
            int b;
            int shift = 0;
            int result = 0;
            
            // Decode latitude
            do {
                b = encodedString.charAt(index++) - 63;
                result |= (b & 0x1f) << shift;
                shift += 5;
            } while (b >= 0x20);
            
            int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
            lat += dlat;

            shift = 0;
            result = 0;
            
            // Decode longitude
            do {
                b = encodedString.charAt(index++) - 63;
                result |= (b & 0x1f) << shift;
                shift += 5;
            } while (b >= 0x20);
            
            int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
            lng += dlng;

            Point point = Point.fromLngLat(lng / factor, lat / factor);
            points.add(point);
        }

        return points;
    }

    /**
     * Encodes a list of Point objects into a polyline string.
     * 
     * @param points List of Point objects
     * @param precision The precision to use for encoding (default is 5)
     * @return Encoded polyline string
     */
    public static String encodePolyline(List<Point> points, int precision) {
        if (points == null || points.isEmpty()) {
            return "";
        }

        StringBuilder result = new StringBuilder();
        double factor = Math.pow(10, precision);
        
        int prevLat = 0;
        int prevLng = 0;

        for (Point point : points) {
            int lat = (int) Math.round(point.latitude() * factor);
            int lng = (int) Math.round(point.longitude() * factor);

            int deltaLat = lat - prevLat;
            int deltaLng = lng - prevLng;

            result.append(encodeSignedNumber(deltaLat));
            result.append(encodeSignedNumber(deltaLng));

            prevLat = lat;
            prevLng = lng;
        }

        return result.toString();
    }

    private static String encodeSignedNumber(int num) {
        int sgn_num = num << 1;
        if (num < 0) {
            sgn_num = ~sgn_num;
        }
        return encodeNumber(sgn_num);
    }

    private static String encodeNumber(int num) {
        StringBuilder result = new StringBuilder();
        while (num >= 0x20) {
            result.append((char) ((0x20 | (num & 0x1f)) + 63));
            num >>= 5;
        }
        result.append((char) (num + 63));
        return result.toString();
    }

    /**
     * Process encoded geometry in a FeatureCollection GeoJSON string.
     * This method handles multiple features that may contain encoded geometry.
     * 
     * @param geojson The GeoJSON string (FeatureCollection or Feature)
     * @return Processed GeoJSON string with decoded coordinates
     */
    public static String processEncodedGeometryInFeatureCollection(String geojson) {
        try {
            Gson gson = new Gson();
            Map<String, Object> geoJsonMap = gson.fromJson(geojson, Map.class);
            
            if (geoJsonMap == null) {

                return geojson;
            }
            
            String type = (String) geoJsonMap.get("type");
            
            if ("FeatureCollection".equals(type)) {
                // Process FeatureCollection
                List<Map<String, Object>> features = (List<Map<String, Object>>) geoJsonMap.get("features");
                if (features != null) {
                    for (Map<String, Object> feature : features) {
                        processEncodedGeometryInFeature(feature);
                    }

                }
            } else if ("Feature".equals(type)) {
                // Process single Feature
                processEncodedGeometryInFeature(geoJsonMap);

            }
            
            return gson.toJson(geoJsonMap);
            
        } catch (Exception e) {

            return geojson;
        }
    }

    /**
     * Process encoded geometry in a single feature.
     * 
     * @param featureMap The feature map to process
     */
    private static void processEncodedGeometryInFeature(Map<String, Object> featureMap) {
        try {
            Map<String, Object> geometry = (Map<String, Object>) featureMap.get("geometry");
            if (geometry == null) {
                return;
            }
            
            String geometryType = (String) geometry.get("type");
            if (!"LineString".equals(geometryType)) {
                return;
            }
            
            String encodedGeometry = (String) geometry.get("encodedGeometry");
            if (encodedGeometry == null) {
                return;
            }
            
            Object precisionObj = geometry.get("encodedGeometryPrecision");
            int precision = 5; // default precision
            if (precisionObj instanceof Number) {
                precision = ((Number) precisionObj).intValue();
            }
            

            
            LineString decodedLineString = decodePolyline(encodedGeometry, precision);
            if (decodedLineString != null) {
                // Convert Point objects to [longitude, latitude] arrays for GeoJSON
                List<List<Double>> coordinatesArray = new ArrayList<>();
                for (Point point : decodedLineString.coordinates()) {
                    List<Double> coord = new ArrayList<>();
                    coord.add(point.longitude());
                    coord.add(point.latitude());
                    coordinatesArray.add(coord);
                }
                
                // Replace the geometry with decoded coordinates
                geometry.put("coordinates", coordinatesArray);
                geometry.remove("encodedGeometry");
                geometry.remove("encodedGeometryPrecision");
                

            }
            
        } catch (Exception e) {

        }
    }
}
