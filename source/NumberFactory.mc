import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Generic scrollable number wheel for WatchUi.Picker, e.g. degrees or
// thousandths-of-a-degree columns in CoordinatePicker. Mirrors the pattern
// Garmin's own Picker sample uses for its DatePicker/TimePicker.
class NumberFactory extends WatchUi.PickerFactory {

    private var _start as Number;
    private var _stop as Number;
    private var _formatString as String;

    function initialize(start as Number, stop as Number, options as { :format as String }) {
        PickerFactory.initialize();
        _start = start;
        _stop = stop;

        var format = options.get(:format);
        _formatString = (format != null) ? format : "%d";
    }

    function getIndex(value as Number) as Number {
        return value - _start;
    }

    function getSize() as Number {
        return (_stop - _start) + 1;
    }

    function getValue(index as Number) as Object? {
        return _start + index;
    }

    function getDrawable(index as Number, selected as Boolean) as WatchUi.Drawable? {
        var value = getValue(index) as Number;
        return new WatchUi.Text({
            :text => value.format(_formatString),
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_NUMBER_MEDIUM,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER
        });
    }

}
