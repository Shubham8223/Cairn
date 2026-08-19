import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Handles the "Set Destination" menu opened from SearchView: routes to the
// text search flow, an animated GPS-fix flow for "Current Location", or
// the coordinate entry pickers.
class DestinationMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _view as SearchView;

    function initialize(view as SearchView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :search) {
            startSearch();
        } else if (id == :currentLocation) {
            startCurrentLocationFix();
        } else if (id == :coordinates) {
            startCoordinateEntry();
        }
    }

    function startSearch() as Void {
        var settings = System.getDeviceSettings();
        if (!settings.connectionAvailable) {
            _view.setStatus("Connect to Wi-Fi to search");
            return;
        }
        WatchUi.pushView(
            new WatchUi.TextPicker(getApp().lastSearchText),
            new SearchTextPickerDelegate(_view),
            WatchUi.SLIDE_UP
        );
    }

    function startCoordinateEntry() as Void {
        var picker = new CoordinatePicker("Latitude", "N", "S", 90);
        WatchUi.pushView(picker, new LatitudePickerDelegate(_view), WatchUi.SLIDE_UP);
    }

    // Pushes a dedicated animated view rather than trying to reveal
    // SearchView by popping a fixed number of times - that broke as soon
    // as this menu itself became one level deeper (Home menu -> Set
    // Destination submenu), landing back on the wrong screen. Pushing on
    // top instead means success (Navigation.showMap()) replaces the whole
    // stack regardless of depth, and BACK-to-cancel just pops one level to
    // wherever we actually came from.
    function startCurrentLocationFix() as Void {
        var view = new AcquiringLocationView();
        WatchUi.pushView(view, new AcquiringLocationDelegate(view), WatchUi.SLIDE_UP);
    }

}
