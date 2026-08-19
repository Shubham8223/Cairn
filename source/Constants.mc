import Toybox.Graphics;
import Toybox.Lang;

// Central place for tunable values so behavior can be adjusted without
// hunting through view/delegate logic.
module Constants {

    // -- Search --------------------------------------------------------
    const NOMINATIM_URL as String = "https://nominatim.openstreetmap.org/search";
    const NOMINATIM_USER_AGENT as String = "Cairn/1.0 garmin-forerunner-965";
    const SEARCH_RESULT_LIMIT as Number = 5;

    // -- Home screen ----------------------------------------------------
    const HOME_HINT_TEXT as String = "Press SELECT\nto begin";

    // -- Off-route detection --------------------------------------------
    const OFF_ROUTE_THRESHOLD_METERS as Float = 50.0f;
    // Consecutive over-threshold GPS fixes required before flagging off-route,
    // so a single noisy fix near the boundary doesn't flicker the banner.
    const OFF_ROUTE_CONFIRM_FIXES as Number = 2;

    // -- Route recording --------------------------------------------------
    const WAYPOINT_CAPTURE_INTERVAL_MS as Number = 5000;
    const MAX_WAYPOINTS as Number = 500;

    // -- Saved trails -------------------------------------------------------
    const MAX_SAVED_TRAILS as Number = 20;
    const TOAST_DURATION_MS as Number = 2000;

    // -- Geometry ---------------------------------------------------------
    const EARTH_RADIUS_METERS as Float = 6371000.0f;
    const METERS_PER_DEGREE_LAT as Float = 111320.0f;

    // -- Map drawing --------------------------------------------------------
    const TRACK_LINE_COLOR = Graphics.COLOR_GREEN;
    const DEST_LINE_COLOR = Graphics.COLOR_BLUE;
    const ALERT_BANNER_COLOR = Graphics.COLOR_RED;
    const ACCENT_COLOR = Graphics.COLOR_GREEN;

    // -- Map zoom -----------------------------------------------------------
    // Angular span (degrees) shown around the current position; UP/DOWN step
    // through this list rather than a continuous zoom, so it stays
    // predictable. Roughly ~150m across at the closest level to ~20km at the
    // widest, similar to native Garmin map zoom steps.
    const ZOOM_SPANS_DEGREES as Array<Float> = [0.0015f, 0.003f, 0.006f, 0.012f, 0.025f, 0.05f, 0.1f, 0.2f];
    const DEFAULT_ZOOM_INDEX as Number = 3;

    // Fallback route usable without a live recorded track, so off-route
    // detection always has something to compare against. A small demo
    // loop; replace with real waypoints for an actual trail.
    const PREDEFINED_ROUTE = [
        { :lat => 40.0150f, :lng => -105.2705f },
        { :lat => 40.0170f, :lng => -105.2680f },
        { :lat => 40.0190f, :lng => -105.2650f },
        { :lat => 40.0175f, :lng => -105.2620f },
        { :lat => 40.0150f, :lng => -105.2600f }
    ];
}
