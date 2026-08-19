import Toybox.Lang;
import Toybox.WatchUi;

// Handles picking a saved trail from the "Load Trail" menu: makes it the
// active route (see RouteRecorder.loadTrail()) and jumps to the map so the
// user can see/follow it immediately.
class TrailListDelegate extends WatchUi.Menu2InputDelegate {

    private var _view as SearchView;

    function initialize(view as SearchView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var index = item.getId() as Number;
        var points = TrailStorage.loadTrailPoints(index);
        if (points.size() < 2) {
            _view.setStatus("Couldn't load that trail");
            return;
        }

        getApp().routeRecorder.loadTrail(points);
        Navigation.showMap();
    }

}
