import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Two-item wheel for a coordinate's sign, e.g. "N"/"S" or "E"/"W", used as
// the first column of CoordinatePicker.
class HemisphereFactory extends WatchUi.PickerFactory {

    private var _positive as String;
    private var _negative as String;

    function initialize(positiveLabel as String, negativeLabel as String) {
        PickerFactory.initialize();
        _positive = positiveLabel;
        _negative = negativeLabel;
    }

    function getIndex(value as String) as Number {
        return value.equals(_negative) ? 1 : 0;
    }

    function getSize() as Number {
        return 2;
    }

    function getValue(index as Number) as Object? {
        return (index == 0) ? _positive : _negative;
    }

    function getDrawable(index as Number, selected as Boolean) as WatchUi.Drawable? {
        return new WatchUi.Text({
            :text => getValue(index) as String,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_NUMBER_MEDIUM,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER
        });
    }

}
