package ai.nextbillion.maps_flutter;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.List;

import ai.nextbillion.kits.geojson.Feature;
import ai.nextbillion.kits.geojson.FeatureCollection;
import ai.nextbillion.kits.geojson.Geometry;
import ai.nextbillion.kits.geojson.GeometryCollection;
import ai.nextbillion.kits.geojson.Point;
import ai.nextbillion.kits.turf.TurfMeasurement;
import ai.nextbillion.maps.geometry.LatLng;
import ai.nextbillion.maps.geometry.LatLngBounds;

public class GeoJSONUtils {
  public static LatLng toLatLng(@Nullable Point point) {
    if (point == null) {
      return null;
    }
    return new LatLng(point.latitude(), point.longitude());
  }

  private static GeometryCollection toGeometryCollection(List<Feature> features) {
    ArrayList<Geometry> geometries = new ArrayList<>();
    geometries.ensureCapacity(features.size());
    for (Feature feature : features) {
      geometries.add(feature.geometry());
    }
    return GeometryCollection.fromGeometries(geometries);
  }

  @Nullable
  public static LatLngBounds toLatLngBounds(@NonNull FeatureCollection featureCollection) {
    List<Feature> features = featureCollection.features();

    if (features == null) {
      return null;
    }
    double[] box = TurfMeasurement.bbox(toGeometryCollection(features));

    return LatLngBounds.from(box[3], box[2], box[1], box[0]);
  }
}
