import Toybox.Lang;
import Toybox.Position;
import Toybox.Timer;
import Toybox.WatchUi;

// Owns the actual GPS fix request/timeout for AcquiringLocationView.
// Starting/stopping here (not in the view) keeps the async
// PositionService/Timer lifecycle paired with input handling (BACK
// cancels it) rather than view show/hide timing.
class AcquiringLocationDelegate extends WatchUi.BehaviorDelegate {

    private var _view as AcquiringLocationView;
    private var _fixTimer as Timer.Timer?;
    private var _resolved as Boolean = false;

    function initialize(view as AcquiringLocationView) {
        BehaviorDelegate.initialize();
        _view = view;

        PositionService.start(method(:onFix));
        _fixTimer = new Timer.Timer();
        _fixTimer.start(method(:onFixTimeout), Constants.GPS_ACQUIRE_TIMEOUT_SEC * 1000, false);
    }

    function onFix(info as Position.Info) as Void {
        PositionService.updateInfo(info);
        if (_resolved || info.position == null) {
            return;
        }
        _resolved = true;
        stopFixTimer();
        PositionService.stop();

        var app = getApp();
        app.destination = info.position;
        app.destinationName = "Current Location";
        Navigation.showMap();
    }

    function onFixTimeout() as Void {
        if (_resolved) {
            return;
        }
        _resolved = true;
        PositionService.stop();
        _view.setTimedOut();
    }

    function onBack() as Boolean {
        if (!_resolved) {
            _resolved = true;
            stopFixTimer();
            PositionService.stop();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function stopFixTimer() as Void {
        if (_fixTimer != null) {
            _fixTimer.stop();
            _fixTimer = null;
        }
    }

}
