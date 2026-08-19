import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Landing screen: a single clear call-to-action (SELECT opens the home
// menu) rather than the old two-button "SELECT vs MENU" legend the user
// had to memorize. Also surfaces status/errors from the destination flow
// (search, GPS fix, trail load/save) since those are transient pushed
// views that disappear once the user backs out of them, leaving this as
// the durable surface underneath.
class SearchView extends WatchUi.View {

    private var _statusText as String = Constants.HOME_HINT_TEXT;

    // Small "breathing" accent dot above the title, purely decorative -
    // gives the landing screen a live/ready feel instead of a static splash.
    // Driven by a Timer (not WatchUi.animate(), which only animates
    // Drawable properties like Bitmap.locX, not arbitrary view fields).
    private var _dotRadius as Float = 3.0;
    private var _dotGrowing as Boolean = true;
    private var _pulseTimer as Timer.Timer?;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
        _pulseTimer = new Timer.Timer();
        _pulseTimer.start(method(:onPulseTick), 60, true);
    }

    function onHide() as Void {
        if (_pulseTimer != null) {
            _pulseTimer.stop();
            _pulseTimer = null;
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        var titleFont = Graphics.FONT_MEDIUM;
        var hintFont = Graphics.FONT_XTINY;
        var titleDims = dc.getTextDimensions("Cairn", titleFont);
        var hintDims = dc.getTextDimensions(_statusText, hintFont);
        var blockGap = 12;
        var dotGap = 18;

        // Stack [dot] -> [title] -> [hint block] as one vertically-centered
        // group so the pieces never collide regardless of font metrics.
        var totalHeight = dotGap + titleDims[1] + blockGap + hintDims[1];
        var top = cy - (totalHeight / 2);

        dc.setColor(Constants.ACCENT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, top, _dotRadius.toNumber());

        var titleTop = top + dotGap;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, titleTop, titleFont, "Cairn", Graphics.TEXT_JUSTIFY_CENTER);

        var hintTop = titleTop + titleDims[1] + blockGap;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, hintTop, hintFont, _statusText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Called by the search flow (delegate / text picker delegate / results
    // delegate) to reflect progress and errors back to the user.
    function setStatus(text as String) as Void {
        _statusText = text;
        WatchUi.requestUpdate();
    }

    function onPulseTick() as Void {
        var step = 0.25;
        if (_dotGrowing) {
            _dotRadius += step;
            if (_dotRadius >= 6.0) {
                _dotGrowing = false;
            }
        } else {
            _dotRadius -= step;
            if (_dotRadius <= 3.0) {
                _dotGrowing = true;
            }
        }
        WatchUi.requestUpdate();
    }

}
