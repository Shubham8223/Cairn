import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Input handling for SearchView: SELECT opens the text-entry search flow,
// MENU skips straight to the map with no destination set.
class SearchDelegate extends WatchUi.BehaviorDelegate {

    private var _view as SearchView;

    function initialize(view as SearchView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        var settings = System.getDeviceSettings();
        if (!settings.connectionAvailable) {
            _view.setStatus("Connect to Wi-Fi to search");
            return true;
        }
        WatchUi.pushView(
            new WatchUi.TextPicker(""),
            new SearchTextPickerDelegate(_view),
            WatchUi.SLIDE_UP
        );
        return true;
    }

    function onMenu() as Boolean {
        WatchUi.switchToView(new NavMapView(), new NavMapDelegate(), WatchUi.SLIDE_LEFT);
        return true;
    }

}
