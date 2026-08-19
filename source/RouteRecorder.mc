import Toybox.Lang;
import Toybox.Position;
import Toybox.Timer;

// Captures GPS waypoints every WAYPOINT_CAPTURE_INTERVAL_MS while an active
// recording session is running, and doubles as the source of the "current
// route" used for off-route detection (falling back to the hardcoded
// PREDEFINED_ROUTE when nothing has been recorded yet).
//
// This is a class (not a module) because its Timer callback needs a real
// `self` to bind method(:onTimer) against.
class RouteRecorder {

    var waypoints as Array<Position.Location> = [];
    var recording as Boolean = false;

    private var _timer as Timer.Timer?;
    private var _predefinedCache as Array<Position.Location>?;

    function initialize() {
    }

    function startRecording() as Void {
        if (recording) {
            return;
        }
        waypoints = [];
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

    // The route currently used for track display + off-route detection:
    // the live recorded track if any points exist, otherwise the
    // hardcoded predefined demo route.
    function getRoutePoints() as Array<Position.Location> {
        if (waypoints.size() > 0) {
            return waypoints;
        }
        return loadPredefinedRoute();
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
