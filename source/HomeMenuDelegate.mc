import Toybox.Lang;
import Toybox.WatchUi;

// Handles the home menu opened from SearchView.
class HomeMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _view as SearchView;

    function initialize(view as SearchView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :findDestination) {
            showDestinationMenu();
        } else if (id == :loadTrail) {
            showTrailList();
        } else if (id == :goToMap) {
            goToMap();
        }
    }

    function showDestinationMenu() as Void {
        var menu = new WatchUi.Menu2({ :title => "Set Destination" });
        menu.addItem(new WatchUi.MenuItem("Search", null, :search, {}));
        menu.addItem(new WatchUi.MenuItem("Current Location", null, :currentLocation, {}));
        menu.addItem(new WatchUi.MenuItem("Coordinates", null, :coordinates, {}));
        WatchUi.pushView(menu, new DestinationMenuDelegate(_view), WatchUi.SLIDE_UP);
    }

    function showTrailList() as Void {
        var trails = TrailStorage.listTrails();
        if (trails.size() == 0) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            _view.setStatus("No saved trails yet");
            return;
        }

        var menu = new WatchUi.Menu2({ :title => "Load Trail" });
        for (var i = 0; i < trails.size(); i++) {
            var record = trails[i] as Dictionary;
            var name = record.get("name") as String;
            var points = record.get("points") as Array;
            menu.addItem(new WatchUi.MenuItem(name, points.size() + " points", i, {}));
        }
        WatchUi.pushView(menu, new TrailListDelegate(_view), WatchUi.SLIDE_UP);
    }

    function goToMap() as Void {
        Navigation.showMap();
    }

}
