import Toybox.Communications;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.Position;
import Toybox.WatchUi;

// Handles the submitted search text: fires the Nominatim HTTP GET request
// and routes the parsed response to a results Menu2 (or a status message
// on SearchView for empty/failed/no-result cases).
class SearchTextPickerDelegate extends WatchUi.TextPickerDelegate {

    private var _view as SearchView;

    function initialize(view as SearchView) {
        TextPickerDelegate.initialize();
        _view = view;
    }

    function onTextEntered(text as String, changed as Boolean) as Boolean {
        if (text == null || text.length() == 0) {
            _view.setStatus(Constants.HOME_HINT_TEXT);
            return true;
        }
        getApp().lastSearchText = text;

        // Same search box doubles as coordinate entry: "40.015,-105.27" (or
        // space-separated) skips the network round-trip entirely.
        var coords = Utils.tryParseCoordinates(text);
        if (coords != null) {
            var app = getApp();
            app.destination = coords as Position.Location;
            app.destinationName = "Custom Coordinates";
            Navigation.showMap();
            return true;
        }

        _view.setStatus("Searching...");

        var params = {
            "q" => text,
            "format" => "json",
            "limit" => Constants.SEARCH_RESULT_LIMIT
        };

        // Bias (not restrict) results toward wherever we last had a GPS
        // fix, like "near me" in a normal maps app - falls back to a plain
        // global search when no fix is cached yet (e.g. fresh app launch).
        var current = PositionService.getLocation();
        if (current != null) {
            var box = Utils.boundingBoxAroundCenter(current, Constants.SEARCH_BIAS_SPAN_DEGREES);
            var topLeft = box[0].toDegrees();
            var bottomRight = box[1].toDegrees();
            params.put("viewbox", topLeft[1] + "," + topLeft[0] + "," + bottomRight[1] + "," + bottomRight[0]);
        }

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => { "User-Agent" => Constants.NOMINATIM_USER_AGENT },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(Constants.NOMINATIM_URL, params, options, method(:onSearchResponse));
        return true;
    }

    function onCancel() as Boolean {
        return true;
    }

    function onSearchResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        if (responseCode != 200 || data == null) {
            _view.setStatus("Search failed, try again");
            return;
        }

        var results = Utils.parseNominatimResults(data as Object);
        if (results.size() == 0) {
            _view.setStatus("No results found");
            return;
        }

        _view.setStatus(Constants.HOME_HINT_TEXT);

        var menu = new WatchUi.Menu2({ :title => "Results" });
        for (var i = 0; i < results.size(); i++) {
            var r = results[i];
            menu.addItem(new WatchUi.MenuItem(r.get(:name), r.get(:country), i, {}));
        }
        WatchUi.pushView(menu, new ResultsDelegate(results), WatchUi.SLIDE_UP);
    }

}
