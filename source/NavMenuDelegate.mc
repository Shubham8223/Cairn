import Toybox.Lang;
import Toybox.WatchUi;

// Handles the "Map Options" menu opened from NavMapView (SELECT/MENU):
// start/stop recording, and save the current trail once there's something
// worth saving.
class NavMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _view as NavMapView;

    function initialize(view as NavMapView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :toggleRecording) {
            toggleRecording();
        } else if (id == :saveTrail) {
            WatchUi.pushView(
                new WatchUi.TextPicker(getApp().lastTrailName),
                new TrailSaveTextPickerDelegate(_view),
                WatchUi.SLIDE_UP
            );
        }
    }

    function toggleRecording() as Void {
        var recorder = getApp().routeRecorder;
        if (recorder.recording) {
            recorder.stopRecording();
            _view.showToast("Recording Stopped");
        } else {
            recorder.startRecording();
            _view.showToast("Recording Started");
        }
    }

}
