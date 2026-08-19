import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Single place every "go to the map" call site routes through, so the
// WatchUi.MapView availability guard (see Garmin's own MapSample: MapView
// isn't guaranteed to exist/be usable on every device/firmware) lives in
// one spot instead of duplicated across every destination-source flow.
module Navigation {

    function showMap() as Void {
        if (!(WatchUi has :MapView)) {
            WatchUi.pushView(new UnsupportedView(), null, WatchUi.SLIDE_UP);
            return;
        }
        var view = new NavMapView();
        WatchUi.switchToView(view, new NavMapDelegate(view), WatchUi.SLIDE_LEFT);
    }

}

// Rare fallback for a device/firmware without map support - avoids
// crashing into the "Cartography not available" case Garmin's own sample
// guards against.
class UnsupportedView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onLayout(dc) as Void {
    }

    function onUpdate(dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_SMALL,
            "Maps not available\non this device",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

}
