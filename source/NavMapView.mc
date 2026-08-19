import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
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
    private var _zoomIndex as Number = Constants.DEFAULT_ZOOM_INDEX;
    private var _toastText as String = "";
    private var _toastTimer as Timer.Timer?;
    // Shared GpsIndicator radar-ping animation (see AcquiringLocationView,
    // which uses the same visual) plus an elapsed-time counter that flips
    // the banner to a clear error state after
    // Constants.GPS_ACQUIRE_TIMEOUT_SEC, instead of waiting on
    // "Waiting for GPS..." forever with no feedback.
    private var _gpsPhase as Float = 0.0;
    private var _gpsPulseTimer as Timer.Timer?;
    private var _gpsWaitSeconds as Number = 0;
    private var _gpsWaitTicker as Timer.Timer?;
    private var _lastTopLeft as Position.Location?;
    private var _lastBottomRight as Position.Location?;

    function initialize() {
        MapView.initialize();
        // Required: every Garmin MapView sample sets an explicit mode right
        // after initialize(). Preview (not Browse) because this view drives
        // its own visible-area/zoom logic (see updateMapBounds/zoomIn/
        // zoomOut) rather than handing pan/zoom to the native map widget.
        setMapMode(WatchUi.MAP_MODE_PREVIEW);

        // Set here, not onLayout(): matches Garmin's own MapSample, and a
        // direct smoke test proved onLayout() isn't guaranteed to run
        // before the first render in every navigation path, which threw
        // "Screen visible area top left is not set" mid-crash.
        var settings = System.getDeviceSettings();
        setScreenVisibleArea(0, 0, settings.screenWidth, settings.screenHeight);

        // MapView also throws ("Map visible area top left is not set") if
        // asked to render before setMapVisibleArea() is ever called, and
        // that doesn't happen until the first GPS fix arrives via
        // updateMapBounds(). Seed it with the same fallback location
        // RouteRecorder already uses when nothing's been recorded, so
        // there's always something valid to draw - real position replaces
        // it the instant a fix comes in.
        var fallback = Constants.PREDEFINED_ROUTE[0] as Dictionary;
        var defaultCenter = new Position.Location({
            :latitude => fallback.get(:lat) as Float,
            :longitude => fallback.get(:lng) as Float,
            :format => :degrees
        });
        var defaultBox = Utils.boundingBoxAroundCenter(defaultCenter, Constants.ZOOM_SPANS_DEGREES[_zoomIndex]);
        setMapVisibleArea(defaultBox[0], defaultBox[1]);
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
        PositionService.start(method(:onPositionUpdate));
        refreshDestinationMarker();
        refreshRoutePolyline();

        if (!_gpsReady) {
            startGpsWaitAnimation();
        }
    }

    function onHide() as Void {
        PositionService.stop();
        if (_alertTimer != null) {
            _alertTimer.stop();
            _alertTimer = null;
        }
        if (_toastTimer != null) {
            _toastTimer.stop();
            _toastTimer = null;
        }
        stopGpsWaitAnimation();
    }

    function startGpsWaitAnimation() as Void {
        if (_gpsPulseTimer == null) {
            _gpsPulseTimer = new Timer.Timer();
            _gpsPulseTimer.start(method(:onGpsPulseTick), 50, true);
        }
        if (_gpsWaitTicker == null) {
            _gpsWaitSeconds = 0;
            _gpsWaitTicker = new Timer.Timer();
            _gpsWaitTicker.start(method(:onGpsWaitTick), 1000, true);
        }
    }

    function stopGpsWaitAnimation() as Void {
        if (_gpsPulseTimer != null) {
            _gpsPulseTimer.stop();
            _gpsPulseTimer = null;
        }
        if (_gpsWaitTicker != null) {
            _gpsWaitTicker.stop();
            _gpsWaitTicker = null;
        }
    }

    function onGpsPulseTick() as Void {
        _gpsPhase += 0.02;
        if (_gpsPhase >= 1.0) {
            _gpsPhase -= 1.0;
        }
        if (!_gpsReady) {
            WatchUi.requestUpdate();
        }
    }

    function onGpsWaitTick() as Void {
        _gpsWaitSeconds += 1;
        WatchUi.requestUpdate();
    }

    // Brief on-screen confirmation (e.g. "Trail Saved"), used by
    // NavMenuDelegate. Auto-clears after Constants.TOAST_DURATION_MS.
    function showToast(text as String) as Void {
        _toastText = text;
        WatchUi.requestUpdate();

        if (_toastTimer != null) {
            _toastTimer.stop();
        }
        _toastTimer = new Timer.Timer();
        _toastTimer.start(method(:onToastTimeout), Constants.TOAST_DURATION_MS, false);
    }

    function onToastTimeout() as Void {
        _toastText = "";
        _toastTimer = null;
        WatchUi.requestUpdate();
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
        var wasReady = _gpsReady;
        _gpsReady = (current != null);

        if (current != null) {
            stopGpsWaitAnimation();
            if (!wasReady) {
                showToast("GPS Connected");
            }
            updateMapBounds(current);
            updateDistanceText(current);
            updateOffRouteState(current);
        } else if (wasReady) {
            // Lost the fix after having one - show the same acquiring
            // state (and give it a fresh timeout window) rather than
            // silently freezing on stale data.
            startGpsWaitAnimation();
        }

        WatchUi.requestUpdate();
    }

    // Centered on current position at the user-controlled zoom span (see
    // zoomIn()/zoomOut()) rather than auto-fitting the destination, so
    // manual zoom behaves predictably like a native map's UP/DOWN zoom.
    function updateMapBounds(current as Position.Location) as Void {
        var span = Constants.ZOOM_SPANS_DEGREES[_zoomIndex];
        var box = Utils.boundingBoxAroundCenter(current, span);
        _lastTopLeft = box[0];
        _lastBottomRight = box[1];
        // Called from the position callback, not onUpdate(), per the API
        // docs' warning against calling this inside onUpdate() (map flicker).
        setMapVisibleArea(box[0], box[1]);
    }

    // Bound to the physical UP/DOWN (next/previous page) buttons by
    // NavMapDelegate. Re-centers on the last known fix immediately rather
    // than waiting for the next GPS callback, so zoom feels responsive.
    function zoomIn() as Void {
        adjustZoom(-1);
    }

    function zoomOut() as Void {
        adjustZoom(1);
    }

    function adjustZoom(delta as Number) as Void {
        var maxIndex = Constants.ZOOM_SPANS_DEGREES.size() - 1;
        var newIndex = _zoomIndex + delta;
        if (newIndex < 0) {
            newIndex = 0;
        } else if (newIndex > maxIndex) {
            newIndex = maxIndex;
        }
        if (newIndex == _zoomIndex) {
            return;
        }
        _zoomIndex = newIndex;

        var current = PositionService.getLocation();
        if (current != null) {
            updateMapBounds(current);
        }
        WatchUi.requestUpdate();
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
            _alertTimer.start(method(:onAlertAnimTick), 50, true);
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
        if (!_gpsReady) {
            // Skip the map render entirely rather than let it show through:
            // the seeded fallback location's tiles may not even be
            // downloaded on this device, which would just be a flat black
            // rectangle behind the banner anyway. A deliberate background
            // reads as designed; a possibly-blank map render doesn't.
            drawGpsBanner(dc);
        } else {
            MapView.onUpdate(dc);
            drawDestinationLine(dc);
            drawHud(dc);
        }

        if (_alertProgress > 0.0) {
            AlertOverlay.draw(dc, _alertProgress);
        }

        if (_toastText.length() > 0) {
            drawToast(dc);
        }
    }

    // Bottom-center, mirroring the HUD's top-center placement - stays
    // inside the round bezel's safe area the same way drawHud() does.
    function drawToast(dc as Graphics.Dc) as Void {
        var cx = dc.getWidth() / 2;
        var y = dc.getHeight() - 40;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(cx, y, Graphics.FONT_XTINY, _toastText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_WHITE, Constants.GPS_BACKGROUND_COLOR);
        dc.clear();

        if (_gpsWaitSeconds >= Constants.GPS_ACQUIRE_TIMEOUT_SEC) {
            drawGpsTimeoutError(dc, cx, h / 2);
            return;
        }

        var cy = (h / 2) - 30;
        GpsIndicator.drawGlow(dc, cx, cy);
        GpsIndicator.draw(dc, cx, cy, _gpsPhase);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 55, Graphics.FONT_SMALL, "Waiting for GPS...", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Same white FONT_SMALL as the "Waiting for GPS..." text above -
    // deliberately not a different alarm color, so the GPS status message
    // reads as one consistent element regardless of state.
    function drawGpsTimeoutError(dc as Graphics.Dc, cx as Number, cy as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            cy,
            Graphics.FONT_SMALL,
            "No GPS Signal\nTry open sky\nBACK to exit",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

}
