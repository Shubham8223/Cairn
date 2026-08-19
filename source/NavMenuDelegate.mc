import Toybox.Lang;
import Toybox.WatchUi;

// Handles the "Trail Options" menu opened from NavMapView (currently just
// Save Trail; NavMapDelegate only shows this menu when there's a trail
// worth saving).
class NavMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _view as NavMapView;

    function initialize(view as NavMapView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :saveTrail) {
            WatchUi.pushView(
                new WatchUi.TextPicker(getApp().lastTrailName),
                new TrailSaveTextPickerDelegate(_view),
                WatchUi.SLIDE_UP
            );
        }
    }

}
