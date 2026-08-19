import Toybox.Lang;
import Toybox.Position;
import Toybox.Timer;

// Captures GPS waypoints every WAYPOINT_CAPTURE_INTERVAL_MS while an active
// recording session is running, and doubles as the source of the "current
// route" used for off-route detection and the drawn track. Route source
// priority is: live recording > a saved trail loaded via loadTrail() >
// the hardcoded PREDEFINED_ROUTE fallback.
//
// This is a class (not a module) because its Timer callback needs a real
// `self` to bind method(:onTimer) against.
class RouteRecorder {

    var waypoints as Array<Position.Location> = [];
    var recording as Boolean = false;

    private var _timer as Timer.Timer?;
    private var _predefinedCache as Array<Position.Location>?;
    private var _loadedTrail as Array<Position.Location>?;

    function initialize() {
    }

    function startRecording() as Void {
        if (recording) {
            return;
        }
        waypoints = [];
        // A fresh recording supersedes whatever was loaded before.
        _loadedTrail = null;
        recording = true;
        _timer = new Timer.Timer();
        _timer.start(method(:onTimer), Constants.WAYPOINT_CAPTURE_INTERVAL_MS, true);
    }

    function stopRecording() as Void {
        recording = false;
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    // Timer tick: capture the current GPS fix as a waypoint, memory-capped
    // at Constants.MAX_WAYPOINTS.
    function onTimer() as Void {
        if (waypoints.size() >= Constants.MAX_WAYPOINTS) {
            return;
        }
        var loc = PositionService.getLocation();
        if (loc != null) {
            waypoints.add(loc);
        }
    }

    // Makes a previously-saved trail (see TrailStorage) the active route,
    // in place of the live recording buffer.
    function loadTrail(points as Array<Position.Location>) as Void {
        stopRecording();
        waypoints = [];
        _loadedTrail = points;
    }

    // The route currently used for track display + off-route detection.
    function getRoutePoints() as Array<Position.Location> {
        if (waypoints.size() > 0) {
            return waypoints;
        }
        if (_loadedTrail != null && (_loadedTrail as Array).size() > 0) {
            return _loadedTrail as Array<Position.Location>;
        }
        return loadPredefinedRoute();
    }

    // Whether there's a real (non-fallback) route worth offering to save,
    // i.e. enough points to be a meaningful track.
    function hasSavableTrail() as Boolean {
        return waypoints.size() >= 2;
    }

    function loadPredefinedRoute() as Array<Position.Location> {
        if (_predefinedCache != null) {
            return _predefinedCache as Array<Position.Location>;
        }
        var pts = [];
        var raw = Constants.PREDEFINED_ROUTE;
        for (var i = 0; i < raw.size(); i++) {
            var entry = raw[i] as Dictionary;
            pts.add(new Position.Location({
                :latitude => entry.get(:lat) as Float,
                :longitude => entry.get(:lng) as Float,
                :format => :degrees
            }));
        }
        _predefinedCache = pts;
        return pts;
    }
}
