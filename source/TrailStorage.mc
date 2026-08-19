import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Position;

// Persists recorded trails across app restarts using Application.Storage,
// so a route recorded once can be reloaded on a later hike/run instead of
// only ever falling back to the hardcoded PREDEFINED_ROUTE. Each trail is
// stored as {"name", "points" => [{"lat", "lng"}, ...]}.
//
// String keys, not Symbols: Storage.setValue() throws
// UnexpectedTypeException("Given value cannot be serialized") on Symbol
// keys/values at runtime, even though it compiles fine - Symbols aren't
// serializable, unlike the in-memory-only Dictionary literals elsewhere in
// this app (e.g. Constants.PREDEFINED_ROUTE) that use :symbol keys safely
// because they never round-trip through Storage.
module TrailStorage {

    const STORAGE_KEY = "savedTrails";

    // Cheap read for listing - callers needing actual Locations should use
    // loadTrailPoints(), not decode :points here themselves.
    function listTrails() as Array {
        var raw = Storage.getValue(STORAGE_KEY);
        if (raw == null || !(raw instanceof Lang.Array)) {
            return [];
        }
        return raw as Array;
    }

    // false if MAX_SAVED_TRAILS is already reached; caller should surface
    // that as a "delete one first" message.
    function saveTrail(name as String, points as Array<Position.Location>) as Boolean {
        var trails = listTrails();
        if (trails.size() >= Constants.MAX_SAVED_TRAILS) {
            return false;
        }

        var encoded = [];
        for (var i = 0; i < points.size(); i++) {
            var d = points[i].toDegrees();
            encoded.add({ "lat" => d[0].toFloat(), "lng" => d[1].toFloat() });
        }

        var updated = [];
        for (var i = 0; i < trails.size(); i++) {
            updated.add(trails[i]);
        }
        updated.add({ "name" => name, "points" => encoded });

        // Cast needed: the compiler infers an overly-specific structural
        // type for this literal-built array/dictionary tree that doesn't
        // structurally match Storage's recursive ValueType polytype, even
        // though the nested Array/Dictionary/Float/String shapes are all
        // individually storable at runtime.
        Storage.setValue(STORAGE_KEY, updated as Storage.ValueType);
        return true;
    }

    function loadTrailPoints(index as Number) as Array<Position.Location> {
        var trails = listTrails();
        var points = [];
        if (index < 0 || index >= trails.size()) {
            return points;
        }

        var record = trails[index] as Dictionary;
        var encoded = record.get("points") as Array;
        for (var i = 0; i < encoded.size(); i++) {
            var e = encoded[i] as Dictionary;
            points.add(new Position.Location({
                :latitude => e.get("lat") as Float,
                :longitude => e.get("lng") as Float,
                :format => :degrees
            }));
        }
        return points;
    }

    function deleteTrail(index as Number) as Void {
        var trails = listTrails();
        if (index < 0 || index >= trails.size()) {
            return;
        }
        var updated = [];
        for (var i = 0; i < trails.size(); i++) {
            if (i != index) {
                updated.add(trails[i]);
            }
        }
        Storage.setValue(STORAGE_KEY, updated);
    }

}
