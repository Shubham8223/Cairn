import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Handles the "Set Destination" menu opened from SearchView: routes to the
// text search flow, grabs a fresh GPS fix for "Current Location", or opens
// the coordinate entry pickers.
class DestinationMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _view as SearchView;
    private var _fixTimer as Timer.Timer?;
    private var _fixResolved as Boolean = false;

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
            new WatchUi.TextPicker(""),
            new SearchTextPickerDelegate(_view),
            WatchUi.SLIDE_UP
        );
    }

    function startCoordinateEntry() as Void {
        var picker = new CoordinatePicker("Latitude", "N", "S", 90);
        WatchUi.pushView(picker, new LatitudePickerDelegate(_view), WatchUi.SLIDE_UP);
    }

    // Grabs one fresh GPS fix (rather than trusting a possibly-stale cached
    // one) with a soft timeout, since the device may not have a lock yet if
    // the user hasn't opened the map this session.
    function startCurrentLocationFix() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        _view.setStatus("Getting GPS fix...");
        _fixResolved = false;

        PositionService.start(method(:onFix));
        _fixTimer = new Timer.Timer();
        _fixTimer.start(method(:onFixTimeout), 20000, false);
    }

    function onFix(info as Position.Info) as Void {
        PositionService.updateInfo(info);
        if (_fixResolved || info.position == null) {
            return;
        }
        resolveFix(info.position as Position.Location);
    }

    function onFixTimeout() as Void {
        if (_fixResolved) {
            return;
        }
        _fixResolved = true;
        PositionService.stop();
        _view.setStatus("GPS unavailable, try again");
    }

    function resolveFix(location as Position.Location) as Void {
        _fixResolved = true;
        if (_fixTimer != null) {
            _fixTimer.stop();
            _fixTimer = null;
        }
        PositionService.stop();

        var app = getApp();
        app.destination = location;
        app.destinationName = "Current Location";

        var view = new NavMapView();
        WatchUi.switchToView(view, new NavMapDelegate(view), WatchUi.SLIDE_LEFT);
    }

}
