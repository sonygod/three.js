import js.Browser.document;
import js.html.InputElement;
import js.html.HTMLInputElement;
import js.html.HTMLSelectElement;
import js.html.HTMLUListElement;
import js.html.HTMLLIElement;
import js.html.HTMLDivElement;
import js.html.HTMLButtonElement;
import js.html.HTMLAnchorElement;
import js.html.CanvasElement;

import three.animation.tracks.ColorKeyframeTrack;
import three.animation.KeyframeTrack;

class ColorKeyframeTrackTests {

    public function new() {
        var parameters = {
            name: ".material.diffuse",
            times: [0, 1],
            values: [0, 0.5, 1.0],
            interpolation: ColorKeyframeTrack.DefaultInterpolation
        };

        // INHERITANCE
        trace("Extending");
        var object = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values);
        trace(Std.is(object, KeyframeTrack), "ColorKeyframeTrack extends from KeyframeTrack");

        // INSTANCING
        trace("Instancing");
        // name, times, values
        var object = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values);
        trace(object != null, "Can instantiate a ColorKeyframeTrack.");

        // name, times, values, interpolation
        var object_all = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
        trace(object_all != null, "Can instantiate a ColorKeyframeTrack with name, times, values, interpolation.");
    }
}

new ColorKeyframeTrackTests();