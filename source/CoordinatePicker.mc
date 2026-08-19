import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Native scrolling-wheel numeric entry for one coordinate (latitude or
// longitude), reused for both via constructor params. A dedicated wheel
// picker is a much better fit for digits than the free-text TextPicker
// character wheel - same widget family as the system's own date/time
// pickers, so it works on button-only devices too, not just touch.
//
// Columns: [hemisphere N/S or E/W] [whole degrees] "." [thousandths].
// Thousandths give ~110m precision at the equator, well inside a trail
// waypoint's useful accuracy.
class CoordinatePicker extends WatchUi.Picker {

    function initialize(titleText as String, positiveLabel as String, negativeLabel as String, maxDegrees as Number) {
        var title = new WatchUi.Text({
            :text => titleText,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM,
            :color => Graphics.COLOR_WHITE
        });
        var separator = new WatchUi.Text({
            :text => ".",
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER,
            :color => Graphics.COLOR_WHITE
        });

        var pattern = [
            new HemisphereFactory(positiveLabel, negativeLabel),
            new NumberFactory(0, maxDegrees, {}),
            separator,
            new NumberFactory(0, 999, { :format => "%03d" })
        ];

        Picker.initialize({ :title => title, :pattern => pattern });
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

}
