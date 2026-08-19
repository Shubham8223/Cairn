import Toybox.Lang;
import Toybox.WatchUi;

// Input handling for NavMapView: SELECT toggles route recording on/off,
// BACK stops any recording in progress and returns to SearchView.
class NavMapDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
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

    function onBack() as Boolean {
        getApp().routeRecorder.stopRecording();
        var view = new SearchView();
        WatchUi.switchToView(view, new SearchDelegate(view), WatchUi.SLIDE_RIGHT);
        return true;
    }

}
