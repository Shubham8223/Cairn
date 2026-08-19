import Toybox.Communications;
import Toybox.Lang;
import Toybox.PersistedContent;
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
            _view.setStatus("No results found");
            return true;
        }

        _view.setStatus("Searching...");

        var params = {
            "q" => text,
            "format" => "json",
            "limit" => Constants.SEARCH_RESULT_LIMIT
        };
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

        _view.setStatus("SELECT: search\nMENU: skip to map");

        var menu = new WatchUi.Menu2({ :title => "Results" });
        for (var i = 0; i < results.size(); i++) {
            var r = results[i];
            menu.addItem(new WatchUi.MenuItem(r.get(:name), r.get(:country), i, {}));
        }
        WatchUi.pushView(menu, new ResultsDelegate(results), WatchUi.SLIDE_UP);
    }

}
