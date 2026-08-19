import Toybox.Lang;
import Toybox.WatchUi;

// Input handling for NavMapView: SELECT toggles route recording on/off,
// UP/DOWN (next/previous page behavior) zoom the map in/out, BACK stops
// any recording in progress and returns to SearchView.
class NavMapDelegate extends WatchUi.BehaviorDelegate {

    private var _view as NavMapView;

    function initialize(view as NavMapView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        var recorder = getApp().routeRecorder;
        if (recorder.recording) {
            recorder.stopRecording();
        } else {
            recorder.startRecording();
        }
        WatchUi.requestUpdate();
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

    function onBack() as Boolean {
        getApp().routeRecorder.stopRecording();
        var view = new SearchView();
        WatchUi.switchToView(view, new SearchDelegate(view), WatchUi.SLIDE_RIGHT);
        return true;
    }

}
