import Toybox.Lang;
import Toybox.WatchUi;

// Input handling for NavMapView: SELECT opens "Map Options" (start/stop
// recording, save trail) - matching the same "press the button, see
// labeled choices" pattern as every other screen in the app, rather than
// silently toggling recording with no menu. UP/DOWN (next/previous page
// behavior) zoom the map in/out. BACK stops any recording in progress and
// returns to SearchView.
class NavMapDelegate extends WatchUi.BehaviorDelegate {

    private var _view as NavMapView;

    function initialize(view as NavMapView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        showMapOptions();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.zoomIn();
        return true;
    }

    function onNextPage() as Boolean {
        _view.zoomOut();
        return true;
    }

    function onMenu() as Boolean {
        showMapOptions();
        return true;
    }

    function showMapOptions() as Void {
        var recorder = getApp().routeRecorder;
        var menu = new WatchUi.Menu2({ :title => "Map Options" });
        menu.addItem(new WatchUi.MenuItem(
            recorder.recording ? "Stop Recording" : "Start Recording",
            null,
            :toggleRecording,
            {}
        ));
        if (recorder.hasSavableTrail()) {
            menu.addItem(new WatchUi.MenuItem("Save Trail", null, :saveTrail, {}));
        }
        WatchUi.pushView(menu, new NavMenuDelegate(_view), WatchUi.SLIDE_UP);
    }

    function onBack() as Boolean {
        getApp().routeRecorder.stopRecording();
        var view = new SearchView();
        WatchUi.switchToView(view, new SearchDelegate(view), WatchUi.SLIDE_RIGHT);
        return true;
    }

}
