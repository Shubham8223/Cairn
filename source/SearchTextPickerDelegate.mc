import Toybox.Communications;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.Position;
import Toybox.WatchUi;

// Handles the submitted search text: fires the Nominatim HTTP GET request
// and routes the parsed response to a results Menu2 (or a status message
// on SearchView for empty/failed/no-result cases).
//
// Two-stage when a GPS fix is available: a tight, hard-restricted "nearby"
// search first (so a category term like "petrol pump" actually returns
// nearby results, the way Google Maps does), falling back to a wider,
// merely-biased global search if that comes back empty (so a specific
// named place like "Qutub Minar" still resolves even far from it).
class SearchTextPickerDelegate extends WatchUi.TextPickerDelegate {

    private var _view as SearchView;
    private var _searchText as String = "";
    private var _triedGlobalFallback as Boolean = false;

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

        _searchText = text;
        _triedGlobalFallback = false;
        var current = PositionService.getLocation();
        if (current != null) {
            _view.setStatus("Searching nearby...");
            fireSearch(current, true);
        } else {
            _triedGlobalFallback = true;
            _view.setStatus("Searching...");
            fireSearch(null, false);
        }
        return true;
    }

    function onCancel() as Boolean {
        return true;
    }

    function fireSearch(current as Position.Location?, nearby as Boolean) as Void {
        var params = {
            "q" => _searchText,
            "format" => "json",
            "limit" => Constants.SEARCH_RESULT_LIMIT
        };

        if (current != null) {
            var span = nearby ? Constants.SEARCH_NEARBY_SPAN_DEGREES : Constants.SEARCH_BIAS_SPAN_DEGREES;
            var box = Utils.boundingBoxAroundCenter(current, span);
            var topLeft = box[0].toDegrees();
            var bottomRight = box[1].toDegrees();
            params.put("viewbox", topLeft[1] + "," + topLeft[0] + "," + bottomRight[1] + "," + bottomRight[0]);
            if (nearby) {
                params.put("bounded", 1);
            }
        }

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => { "User-Agent" => Constants.NOMINATIM_USER_AGENT },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(Constants.NOMINATIM_URL, params, options, method(:onSearchResponse));
    }

    function onSearchResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        var results = (responseCode == 200 && data != null) ? Utils.parseNominatimResults(data as Object) : [];

        if (results.size() == 0) {
            // Nearby-bounded attempt found nothing local - retry globally
            // (biased, not restricted) exactly once before giving up, so
            // named landmarks still resolve from anywhere.
            if (!_triedGlobalFallback) {
                var current = PositionService.getLocation();
                _triedGlobalFallback = true;
                _view.setStatus("Searching...");
                fireSearch(current, false);
                return;
            }
            _view.setStatus(responseCode == 200 ? "No results found" : "Search failed, try again");
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
