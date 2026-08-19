import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Full-screen "Current Location" flow: shows the GpsIndicator radar-ping
// while waiting for a fix, or a clear error after
// Constants.GPS_ACQUIRE_TIMEOUT_SEC. Pushed on top of whatever menu the
// user was on (see DestinationMenuDelegate) rather than trying to pop back
// to a specific screen - switchToView() on success replaces the whole
// stack regardless of depth, and BACK on failure just pops one level,
// naturally returning to that same menu.
class AcquiringLocationView extends WatchUi.View {

    private var _phase as Float = 0.0;
    private var _elapsedSeconds as Number = 0;
    private var _timedOut as Boolean = false;
    private var _pulseTimer as Timer.Timer?;
    private var _secondTimer as Timer.Timer?;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        _pulseTimer = new Timer.Timer();
        _pulseTimer.start(method(:onPulseTick), 50, true);
        _secondTimer = new Timer.Timer();
        _secondTimer.start(method(:onSecondTick), 1000, true);
    }

    function onHide() as Void {
        if (_pulseTimer != null) {
            _pulseTimer.stop();
            _pulseTimer = null;
        }
        if (_secondTimer != null) {
            _secondTimer.stop();
            _secondTimer = null;
        }
    }

    function onPulseTick() as Void {
        _phase += 0.02;
        if (_phase >= 1.0) {
            _phase -= 1.0;
        }
        if (!_timedOut) {
            WatchUi.requestUpdate();
        }
    }

    function onSecondTick() as Void {
        _elapsedSeconds += 1;
        if (_elapsedSeconds >= Constants.GPS_ACQUIRE_TIMEOUT_SEC) {
            setTimedOut();
        }
    }

    // Called by AcquiringLocationDelegate's own (independent) fix timeout
    // too, so either clock tripping first shows the same state.
    function setTimedOut() as Void {
        if (_timedOut) {
            return;
        }
        _timedOut = true;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Constants.GPS_BACKGROUND_COLOR);
        dc.clear();

        var cx = dc.getWidth() / 2;
        var cy = (dc.getHeight() / 2) - 30;

        if (_timedOut) {
            // Same white as "Locating you..." - one consistent message
            // style regardless of GPS state, not a different alarm color.
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                cx,
                dc.getHeight() / 2,
                Graphics.FONT_SMALL,
                "No GPS Signal\nTry open sky\nBACK to return",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            return;
        }

        GpsIndicator.drawGlow(dc, cx, cy);
        GpsIndicator.draw(dc, cx, cy, _phase);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 55, Graphics.FONT_SMALL, "Locating you...", Graphics.TEXT_JUSTIFY_CENTER);
    }

}
