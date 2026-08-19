import Toybox.Lang;
import Toybox.Position;

// Thin wrapper around the Positioning API holding the last known GPS fix
// so any view/module (RouteRecorder, NavMapView) can read live location
// without each one running its own subscription.
//
// stop() re-sends the same callback Method that start() was given (rather
// than binding a fresh one of its own) because Monkey C modules have no
// `self` to bind method(:symbol) against - only classes do.
module PositionService {

    var lastInfo as Position.Info? = null;
    var callback as Method(info as Position.Info) as Void or Null;

    function start(cb as Method(info as Position.Info) as Void) as Void {
        callback = cb;
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, cb);
    }

    function stop() as Void {
        if (callback != null) {
            Position.enableLocationEvents(Position.LOCATION_DISABLE, callback);
        }
    }

    function updateInfo(info as Position.Info) as Void {
        lastInfo = info;
    }

    function getLocation() as Position.Location? {
        return (lastInfo != null) ? lastInfo.position : null;
    }

    function hasFix() as Boolean {
        return getLocation() != null;
    }
}
