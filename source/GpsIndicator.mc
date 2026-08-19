import Toybox.Graphics;
import Toybox.Lang;

// Shared "acquiring GPS" radar-ping visual: a static center pin with two
// rings expanding outward and fading, offset half a cycle apart so one is
// always mid-ping - reused by AcquiringLocationView (the "Current Location"
// flow) and NavMapView (the map's own "Waiting for GPS" state) so both get
// the same premium, unmistakably-native-feeling animation instead of a
// simpler one-off pulse.
//
// Callers own a Timer stepping `phase` 0.0 -> 1.0 and wrapping back to 0.0
// (a looping sweep reads as much more "alive" than a back-and-forth
// breathing dot); this module only draws a single frame.
module GpsIndicator {

    const MIN_RADIUS = 9.0;
    const MAX_RADIUS = 34.0;

    // Soft layered "glow" behind the rings - a few filled circles stepping
    // from the screen background up to a lighter shade, approximating a
    // radial vignette without true alpha blending. Call once before draw()
    // against whatever solid background color the caller cleared to.
    function drawGlow(dc as Graphics.Dc, cx as Number, cy as Number) as Void {
        dc.setColor(0x122822, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 58);
        dc.setColor(0x1A3B32, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 44);
    }

    function draw(dc as Graphics.Dc, cx as Number, cy as Number, phase as Float) as Void {
        drawRing(dc, cx, cy, phase);
        drawRing(dc, cx, cy, wrapPhase(phase + 0.5));

        dc.setColor(Constants.ACCENT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 5);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, 5);
    }

    function drawRing(dc as Graphics.Dc, cx as Number, cy as Number, phase as Float) as Void {
        var radius = MIN_RADIUS + (phase * (MAX_RADIUS - MIN_RADIUS));
        dc.setColor(ringColor(phase), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy, radius.toNumber());
        dc.setPenWidth(1);
    }

    // Approximates a fade-out as the ring expands (no true alpha on plain
    // Dc draws) by stepping through progressively dimmer solid colors.
    function ringColor(phase as Float) as Graphics.ColorType {
        if (phase < 0.35) {
            return Constants.ACCENT_COLOR;
        } else if (phase < 0.7) {
            return Graphics.COLOR_DK_GREEN;
        }
        return Graphics.COLOR_DK_GRAY;
    }

    function wrapPhase(p as Float) as Float {
        return (p >= 1.0) ? (p - 1.0) : p;
    }

}
