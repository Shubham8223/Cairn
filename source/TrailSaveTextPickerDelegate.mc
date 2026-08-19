import Toybox.Lang;
import Toybox.WatchUi;

// Handles the trail name entered from NavMapView's "Save Trail" flow.
class TrailSaveTextPickerDelegate extends WatchUi.TextPickerDelegate {

    private var _view as NavMapView;

    function initialize(view as NavMapView) {
        TextPickerDelegate.initialize();
        _view = view;
    }

    function onTextEntered(text as String, changed as Boolean) as Boolean {
        var name = Utils.trimString(text);
        if (name.length() == 0) {
            _view.showToast("Trail needs a name");
            return true;
        }
        getApp().lastTrailName = name;

        var saved = TrailStorage.saveTrail(name, getApp().routeRecorder.waypoints);
        _view.showToast(saved ? "Trail Saved" : "Storage full");
        if (saved) {
            getApp().lastTrailName = "";
        }
        return true;
    }

    function onCancel() as Boolean {
        return true;
    }

}
