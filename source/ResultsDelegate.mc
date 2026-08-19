import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;

// Handles selection from the search-results Menu2: stores the chosen
// place as the app's destination and switches to the navigation map.
class ResultsDelegate extends WatchUi.Menu2InputDelegate {

    private var _results as Array;

    function initialize(results as Array) {
        Menu2InputDelegate.initialize();
        _results = results;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var idx = item.getId() as Number;
        var r = _results[idx] as Dictionary;

        var app = getApp();
        app.destination = new Position.Location({
            :latitude => r.get(:lat) as Float,
            :longitude => r.get(:lng) as Float,
            :format => :degrees
        });
        app.destinationName = r.get(:name) as String;

        Navigation.showMap();
    }

}
