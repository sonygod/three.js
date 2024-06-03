import js.Browser.document;
import js.html.LIElement;
import js.html.InputElement;
import js.html.Html;

import three.animation.KeyframeTrack;
import three.animation.tracks.NumberKeyframeTrack;

class NumberKeyframeTrackTests {

    static function main() {
        var parameters = {
            name: '.material.opacity',
            times: [0, 1],
            values: [0, 0.5],
            interpolation: NumberKeyframeTrack.DefaultInterpolation
        };

        // INSTANCING
        var object = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values);
        js.Boot.trace("Can instantiate a NumberKeyframeTrack.", js.Boot.getObjectClass(object));

        var object_all = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
        js.Boot.trace("Can instantiate a NumberKeyframeTrack with name, times, values, interpolation.", js.Boot.getObjectClass(object_all));

        // INHERITANCE
        if (Std.is(object, KeyframeTrack)) {
            js.Boot.trace("NumberKeyframeTrack extends from KeyframeTrack");
        }
    }
}