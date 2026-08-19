import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Timer;
import Toybox.WatchUi;

// Main navigation screen: live GPS position + destination marker on a
// WatchUi.MapView basemap, with the recorded/predefined route drawn as a
// polyline, a hand-drawn straight line to the destination, a distance
// readout, and the off-route alert overlay.
//
// MapView.setPolyline() only accepts a single MapPolyline, so that slot is
// reserved for the (potentially many-point) route track; the two-point
// current->destination line is instead drawn directly on the Dc using the
// same bounding box handed to setMapVisibleArea(), so it lines up with the
// rendered map underneath it.
class NavMapView extends WatchUi.MapView {

    private var _distanceText as String = "";
    private var _gpsReady as Boolean = false;
    private var _offRoute as Boolean = false;
    private var _offRouteStreak as Number = 0;
    // Animated 0.0 (hidden) -> 1.0 (settled) drive value for AlertOverlay,
    // so the banner slides/fades instead of popping in and out. Stepped by
    // a Timer rather than WatchUi.animate(), which only animates Drawable
    // properties (e.g. Bitmap.locX) - not arbitrary view fields like this.
    private var _alertProgress as Float = 0.0;
    private var _alertTarget as Float = 0.0;
    private var _alertTimer as Timer.Timer?;
    private var _lastTopLeft as Position.Location?;
    private var _lastBottomRight as Position.Location?;

    function initialize() {
        MapView.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        MapView.onLayout(dc);
        setScreenVisibleArea(0, 0, dc.getWidth(), dc.getHeight());
    }

    function onShow() as Void {
        PositionService.start(method(:onPositionUpdate));
        refreshDestinationMarker();
        refreshRoutePolyline();
    }

    function onHide() as Void {
        PositionService.stop();
        if (_alertTimer != null) {
            _alertTimer.stop();
            _alertTimer = null;
        }
    }

    // Recorded/predefined route track -> the map's single polyline slot.
    function refreshRoutePolyline() as Void {
        var pts = getApp().routeRecorder.getRoutePoints();
        if (pts.size() < 2) {
            return;
        }
        var line = new WatchUi.MapPolyline();
        for (var i = 0; i < pts.size(); i++) {
            line.addLocation(pts[i]);
        }
        line.setColor(Constants.TRACK_LINE_COLOR);
        line.setWidth(3);
        setPolyline(line);
    }

    function refreshDestinationMarker() as Void {
        var dest = getApp().destination;
        if (dest == null) {
            return;
        }
        var marker = new WatchUi.MapMarker(dest);
        var name = getApp().destinationName;
        marker.setLabel(name != null ? name : "Destination");
        setMapMarker(marker);
    }

    // Fires on every GPS fix. Recomputes map bounds, distance-to-destination,
    // and off-route state, then requests a redraw.
    function onPositionUpdate(info as Position.Info) as Void {
        PositionService.updateInfo(info);
        var current = info.position;
        _gpsReady = (current != null);

        if (current != null) {
            updateMapBounds(current);
            updateDistanceText(current);
            updateOffRouteState(current);
        }

        WatchUi.requestUpdate();
    }

    function updateMapBounds(current as Position.Location) as Void {
        var dest = getApp().destination;
        var points = (dest != null) ? [current, dest] : [current];
        var box = Utils.boundingBox(points, 0.35f);
        _lastTopLeft = box[0];
        _lastBottomRight = box[1];
        // Called from the position callback, not onUpdate(), per the API
        // docs' warning against calling this inside onUpdate() (map flicker).
        setMapVisibleArea(box[0], box[1]);
    }

    function updateDistanceText(current as Position.Location) as Void {
        var dest = getApp().destination;
        if (dest == null) {
            _distanceText = "";
            return;
        }
        var meters = Utils.distanceMeters(current, dest);
        _distanceText = Utils.formatDistanceKm(meters);
    }

    // Distance from the nearest point on the active route; requires a couple
    // of consecutive over-threshold fixes before flagging off-route (so a
    // single noisy GPS fix near the boundary doesn't flicker the banner),
    // but clears immediately once the user is back within range.
    function updateOffRouteState(current as Position.Location) as Void {
        var routePts = getApp().routeRecorder.getRoutePoints();
        if (routePts.size() < 2) {
            _offRouteStreak = 0;
            setOffRoute(false);
            return;
        }

        var dist = Utils.nearestDistanceToRoute(current, routePts);
        var beyondThreshold = dist > Constants.OFF_ROUTE_THRESHOLD_METERS;
        _offRouteStreak = beyondThreshold ? (_offRouteStreak + 1) : 0;

        if (_offRouteStreak >= Constants.OFF_ROUTE_CONFIRM_FIXES) {
            setOffRoute(true);
        } else if (!beyondThreshold) {
            setOffRoute(false);
        }
    }

    function setOffRoute(value as Boolean) as Void {
        if (value == _offRoute) {
            return;
        }
        _offRoute = value;
        if (value) {
            Attention.vibrate([new Attention.VibeProfile(75, 1000)]);
        }
        _alertTarget = value ? 1.0 : 0.0;
        if (_alertTimer == null) {
            _alertTimer = new Timer.Timer();
            _alertTimer.start(method(:onAlertAnimTick), 30, true);
        }
    }

    // Steps _alertProgress toward _alertTarget each tick and stops itself
    // once it arrives, so the banner slides/fades smoothly in either
    // direction instead of popping in and out.
    function onAlertAnimTick() as Void {
        var step = 0.15;
        if (_alertProgress < _alertTarget) {
            _alertProgress += step;
            if (_alertProgress > _alertTarget) {
                _alertProgress = _alertTarget;
            }
        } else if (_alertProgress > _alertTarget) {
            _alertProgress -= step;
            if (_alertProgress < _alertTarget) {
                _alertProgress = _alertTarget;
            }
        }

        if (_alertProgress == _alertTarget && _alertTimer != null) {
            _alertTimer.stop();
            _alertTimer = null;
        }

        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        MapView.onUpdate(dc);

        if (!_gpsReady) {
            drawGpsBanner(dc);
        } else {
            drawDestinationLine(dc);
            drawHud(dc);
        }

        if (_alertProgress > 0.0) {
            AlertOverlay.draw(dc, _alertProgress);
        }
    }

    function drawDestinationLine(dc as Graphics.Dc) as Void {
        var dest = getApp().destination;
        var current = PositionService.getLocation();
        if (dest == null || current == null || _lastTopLeft == null || _lastBottomRight == null) {
            return;
        }

        var w = dc.getWidth();
        var h = dc.getHeight();
        var p1 = Utils.projectToScreen(current, _lastTopLeft as Position.Location, _lastBottomRight as Position.Location, w, h);
        var p2 = Utils.projectToScreen(dest, _lastTopLeft as Position.Location, _lastBottomRight as Position.Location, w, h);

        dc.setColor(Constants.DEST_LINE_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(p1[0], p1[1], p2[0], p2[1]);
        dc.setPenWidth(1);
    }

    // Both rows are centered on the screen's vertical axis and kept near
    // the top-center of the round bezel's safe area - anything nearer the
    // corners (e.g. a fixed (20, 20) label) gets clipped by the round
    // display outside its inscribed circle.
    function drawHud(dc as Graphics.Dc) as Void {
        var cx = dc.getWidth() / 2;
        var y = 30;

        if (getApp().routeRecorder.recording) {
            drawRecordingBadge(dc, cx, y);
            y += 24;
        }

        if (_distanceText.length() > 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawText(cx, y, Graphics.FONT_SMALL, _distanceText, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function drawRecordingBadge(dc as Graphics.Dc, cx as Number, y as Number) as Void {
        var font = Graphics.FONT_XTINY;
        var label = "REC";
        var dims = dc.getTextDimensions(label, font);
        var dotGap = 12;
        var totalWidth = dims[0] + dotGap;
        var left = cx - (totalWidth / 2);

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(left + 3, y + (dims[1] / 2), 4);

        dc.drawText(left + dotGap, y, font, label, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function drawGpsBanner(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(w / 2, h / 2, Graphics.FONT_SMALL, "Waiting for GPS...", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

}
