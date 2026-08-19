import Toybox.Lang;
import Toybox.WatchUi;

// Input handling for SearchView: SELECT is the one clear entry point,
// opening the home menu (find destination / load trail / go to map).
// MENU is kept as an unadvertised power-user shortcut straight to the map,
// matching the old behavior, but the menu no longer requires remembering it.
class SearchDelegate extends WatchUi.BehaviorDelegate {

    private var _view as SearchView;

    function initialize(view as SearchView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        var menu = new WatchUi.Menu2({ :title => "Cairn" });
        menu.addItem(new WatchUi.MenuItem("Find Destination", null, :findDestination, {}));
        menu.addItem(new WatchUi.MenuItem("Load Trail", null, :loadTrail, {}));
        menu.addItem(new WatchUi.MenuItem("Go to Map", null, :goToMap, {}));
        WatchUi.pushView(menu, new HomeMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

    function onMenu() as Boolean {
        var view = new NavMapView();
        WatchUi.switchToView(view, new NavMapDelegate(view), WatchUi.SLIDE_LEFT);
        return true;
    }

}
