import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;

// Geometry, formatting, and Nominatim-response parsing helpers shared by
// the views/delegates. Kept free of WatchUi/Communications state so it is
// easy to reason about and test in isolation.
module Utils {

    // Great-circle distance between two points, in meters (Haversine).
    function distanceMeters(a as Position.Location, b as Position.Location) as Float {
        var ra = a.toRadians();
        var rb = b.toRadians();
        var lat1 = ra[0];
        var lon1 = ra[1];
        var lat2 = rb[0];
        var lon2 = rb[1];

        var dLat = lat2 - lat1;
        var dLon = lon2 - lon1;
        var sinDLat = Math.sin(dLat / 2.0);
        var sinDLon = Math.sin(dLon / 2.0);
        var h = sinDLat * sinDLat + Math.cos(lat1) * Math.cos(lat2) * sinDLon * sinDLon;
        var c = 2.0 * Math.atan2(Math.sqrt(h), Math.sqrt(1.0 - h));

        return (Constants.EARTH_RADIUS_METERS * c).toFloat();
    }

    function formatDistanceKm(meters as Float) as String {
        var km = meters / 1000.0;
        return km.format("%.2f") + " km";
    }

    // Flat-earth (equirectangular) projection of a Location into meters
    // relative to an origin. Only valid for the small spans (tens/hundreds
    // of meters, a few km at most) this app deals with.
    function toLocalMeters(loc as Position.Location, originLat as Float, originLng as Float) as Array<Float> {
        var d = loc.toDegrees();
        var lat = d[0].toFloat();
        var lng = d[1].toFloat();
        var metersPerDegLng = Constants.METERS_PER_DEGREE_LAT * Math.cos(Math.toRadians(originLat));

        var x = ((lng - originLng) * metersPerDegLng).toFloat();
        var y = ((lat - originLat) * Constants.METERS_PER_DEGREE_LAT).toFloat();
        return [x, y];
    }

    // Shortest distance from point p to the segment a-b, all in local meters.
    function pointSegmentDistanceMeters(p as Array<Float>, a as Array<Float>, b as Array<Float>) as Float {
        var abx = b[0] - a[0];
        var aby = b[1] - a[1];
        var apx = p[0] - a[0];
        var apy = p[1] - a[1];

        var lenSq = abx * abx + aby * aby;
        var t = 0.0;
        if (lenSq > 0.0000001) {
            t = (apx * abx + apy * aby) / lenSq;
            if (t < 0.0) { t = 0.0; }
            if (t > 1.0) { t = 1.0; }
        }

        var projx = a[0] + t * abx;
        var projy = a[1] + t * aby;
        var dx = p[0] - projx;
        var dy = p[1] - projy;
        return Math.sqrt(dx * dx + dy * dy).toFloat();
    }

    // Distance from `current` to the nearest point on the route polyline
    // defined by `routePoints`. Drives off-route detection.
    function nearestDistanceToRoute(current as Position.Location, routePoints as Array<Position.Location>) as Float {
        if (routePoints.size() == 0) {
            return 0.0f;
        }
        if (routePoints.size() == 1) {
            return distanceMeters(current, routePoints[0]);
        }

        var originDeg = current.toDegrees();
        var originLat = originDeg[0].toFloat();
        var originLng = originDeg[1].toFloat();
        var p = toLocalMeters(current, originLat, originLng);

        var minDist = -1.0f;
        for (var i = 0; i < routePoints.size() - 1; i++) {
            var a = toLocalMeters(routePoints[i], originLat, originLng);
            var b = toLocalMeters(routePoints[i + 1], originLat, originLng);
            var d = pointSegmentDistanceMeters(p, a, b);
            if (minDist < 0.0f || d < minDist) {
                minDist = d;
            }
        }
        return minDist;
    }

    // Bounding box (with minimum size + padding) around a set of locations,
    // for feeding to MapView.setMapVisibleArea().
    function boundingBox(locations as Array<Position.Location>, paddingFraction as Float) as Array<Position.Location> {
        var minLat = 0.0;
        var maxLat = 0.0;
        var minLng = 0.0;
        var maxLng = 0.0;
        var haveBounds = false;

        for (var i = 0; i < locations.size(); i++) {
            var d = locations[i].toDegrees();
            var lat = d[0];
            var lng = d[1];
            if (!haveBounds) {
                minLat = lat; maxLat = lat; minLng = lng; maxLng = lng;
                haveBounds = true;
            } else {
                if (lat < minLat) { minLat = lat; }
                if (lat > maxLat) { maxLat = lat; }
                if (lng < minLng) { minLng = lng; }
                if (lng > maxLng) { maxLng = lng; }
            }
        }

        var minSpan = 0.0015; // ~150m, keeps a single point from filling the map
        var latSpan = maxLat - minLat;
        var lngSpan = maxLng - minLng;
        if (latSpan < minSpan) { latSpan = minSpan; }
        if (lngSpan < minSpan) { lngSpan = minSpan; }

        var centerLat = (maxLat + minLat) / 2.0;
        var centerLng = (maxLng + minLng) / 2.0;
        var latHalf = (latSpan / 2.0) * (1.0 + paddingFraction);
        var lngHalf = (lngSpan / 2.0) * (1.0 + paddingFraction);

        var topLeft = new Position.Location({
            :latitude => centerLat + latHalf,
            :longitude => centerLng - lngHalf,
            :format => :degrees
        });
        var bottomRight = new Position.Location({
            :latitude => centerLat - latHalf,
            :longitude => centerLng + lngHalf,
            :format => :degrees
        });
        return [topLeft, bottomRight];
    }

    // Projects a Location to a screen pixel using the same bounding box that
    // was handed to MapView.setMapVisibleArea(), so the manually-drawn
    // destination line lines up with the rendered map underneath it.
    // (MapView.setPolyline() only accepts a single polyline, which is
    // reserved for the recorded/predefined route track, so the straight
    // current->destination line is drawn by hand instead.)
    function projectToScreen(
        loc as Position.Location,
        topLeft as Position.Location,
        bottomRight as Position.Location,
        screenWidth as Number,
        screenHeight as Number
    ) as Array<Number> {
        var locD = loc.toDegrees();
        var tl = topLeft.toDegrees();
        var br = bottomRight.toDegrees();

        var latSpan = tl[0] - br[0];
        var lngSpan = br[1] - tl[1];
        if (latSpan == 0.0) { latSpan = 0.0001; }
        if (lngSpan == 0.0) { lngSpan = 0.0001; }

        var xFrac = (locD[1] - tl[1]) / lngSpan;
        var yFrac = (tl[0] - locD[0]) / latSpan;

        var x = (xFrac * screenWidth).toNumber();
        var y = (yFrac * screenHeight).toNumber();
        return [x, y];
    }

    // -- String helpers (Lang.String has no split()/trim() in Monkey C) ----

    function trimString(s as String) as String {
        var start = 0;
        var end = s.length();
        while (start < end && isSpaceChar(s.substring(start, start + 1) as String)) {
            start++;
        }
        while (end > start && isSpaceChar(s.substring(end - 1, end) as String)) {
            end--;
        }
        return s.substring(start, end) as String;
    }

    function isSpaceChar(c as String) as Boolean {
        return c.equals(" ") || c.equals("\t") || c.equals("\n") || c.equals("\r");
    }

    // Splits a Nominatim `display_name` ("Place, Region, Country") into a
    // [name, country] pair using only the first and last comma-separated
    // segments, trimmed.
    function splitNameAndCountry(displayName as String) as Array<String> {
        var firstComma = displayName.find(",");
        var name = ((firstComma != null) ? displayName.substring(0, firstComma) : displayName) as String;

        var lastComma = null;
        var searchFrom = 0;
        while (true) {
            var found = (displayName.substring(searchFrom, displayName.length()) as String).find(",");
            if (found == null) {
                break;
            }
            lastComma = searchFrom + found;
            searchFrom = lastComma + 1;
            if (searchFrom >= displayName.length()) {
                break;
            }
        }
        var country = ((lastComma != null) ? displayName.substring(lastComma + 1, displayName.length()) : displayName) as String;

        return [trimString(name), trimString(country)];
    }

    // Parses the JSON array returned by the Nominatim /search endpoint into
    // a list of {:name, :country, :lat, :lng} dictionaries. Defensive
    // against missing fields since it's untrusted external data.
    function parseNominatimResults(data as Object?) as Array {
        var results = [];
        if (data == null || !(data instanceof Lang.Array)) {
            return results;
        }

        var items = data as Array;
        for (var i = 0; i < items.size(); i++) {
            var item = items[i];
            if (!(item instanceof Lang.Dictionary)) {
                continue;
            }
            var dict = item as Dictionary;
            var displayName = dict.get("display_name");
            var latStr = dict.get("lat");
            var lonStr = dict.get("lon");
            if (displayName == null || latStr == null || lonStr == null) {
                continue;
            }
            var lat = (latStr as String).toFloat();
            var lon = (lonStr as String).toFloat();
            if (lat == null || lon == null) {
                continue;
            }

            var nameAndCountry = splitNameAndCountry(displayName as String);
            results.add({
                :name => nameAndCountry[0],
                :country => nameAndCountry[1],
                :lat => lat,
                :lng => lon
            });
        }
        return results;
    }
}
