import Toybox.Lang;
import Toybox.WatchUi;

// Input handling for SearchView: SELECT opens the "Set Destination" menu
// (search / current location / coordinates), MENU skips straight to the
// map with no destination set.
class SearchDelegate extends WatchUi.BehaviorDelegate {

    private var _view as SearchView;

    function initialize(view as SearchView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        var menu = new WatchUi.Menu2({ :title => "Set Destination" });
        menu.addItem(new WatchUi.MenuItem("Search", null, :search, {}));
        menu.addItem(new WatchUi.MenuItem("Current Location", null, :currentLocation, {}));
        menu.addItem(new WatchUi.MenuItem("Coordinates", null, :coordinates, {}));
        WatchUi.pushView(menu, new DestinationMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

    function onMenu() as Boolean {
        var view = new NavMapView();
        WatchUi.switchToView(view, new NavMapDelegate(view), WatchUi.SLIDE_LEFT);
        return true;
    }

}
