import Toybox.Graphics;
import Toybox.Lang;

// Draws the "Off Route!" warning banner on top of the map. A pure drawing
// helper (no state of its own) - NavMapView owns the animated progress
// value and decides when to call it.
module AlertOverlay {

    // progress: 0.0 (hidden, off the top edge) -> 1.0 (fully settled),
    // driven by NavMapView via WatchUi.animate() so the banner slides in/out
    // instead of popping, matching native toast/alert behavior.
    function draw(dc as Graphics.Dc, progress as Float) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var margin = 24;
        var bannerHeight = 64;
        var restTop = (h / 2) - (bannerHeight / 2);
        var startTop = -bannerHeight;
        var top = (startTop + (restTop - startTop) * progress).toNumber();

        dc.setColor(Graphics.COLOR_WHITE, Constants.ALERT_BANNER_COLOR);
        dc.fillRectangle(margin, top, w - (margin * 2), bannerHeight);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            w / 2,
            top + (bannerHeight / 2),
            Graphics.FONT_MEDIUM,
            "Off Route!",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
