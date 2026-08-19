import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;

// First step of manual coordinate entry: collects latitude, then pushes the
// longitude picker with it in hand.
class LatitudePickerDelegate extends WatchUi.PickerDelegate {

    private var _view as SearchView;

    function initialize(view as SearchView) {
        PickerDelegate.initialize();
        _view = view;
    }

    function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onAccept(values as Array) as Boolean {
        var lat = Utils.coordinateValuesToDegrees(values);
        var picker = new CoordinatePicker("Longitude", "E", "W", 180);
        WatchUi.pushView(picker, new LongitudePickerDelegate(_view, lat), WatchUi.SLIDE_LEFT);
        return true;
    }

}

// Second step: collects longitude, combines it with the latitude collected
// above, and sets it as the destination.
class LongitudePickerDelegate extends WatchUi.PickerDelegate {

    private var _view as SearchView;
    private var _latitude as Float;

    function initialize(view as SearchView, latitude as Float) {
        PickerDelegate.initialize();
        _view = view;
        _latitude = latitude;
    }

    function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onAccept(values as Array) as Boolean {
        var lng = Utils.coordinateValuesToDegrees(values);

        var app = getApp();
        app.destination = new Position.Location({ :latitude => _latitude, :longitude => lng, :format => :degrees });
        app.destinationName = "Custom Coordinates";

        var view = new NavMapView();
        WatchUi.switchToView(view, new NavMapDelegate(view), WatchUi.SLIDE_LEFT);
        return true;
    }

}
