import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;

class CairnApp extends Application.AppBase {

    // Selected search result, shared across SearchView -> NavMapView.
    var destination as Position.Location?;
    var destinationName as String?;

    // Single shared recorder instance so recording state survives view
    // pushes/pops within a session.
    var routeRecorder as RouteRecorder = new RouteRecorder();

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new SearchView();
        return [view, new SearchDelegate(view)];
    }

}

function getApp() as CairnApp {
    return Application.getApp() as CairnApp;
}
