import three.animation.tracks.NumberKeyframeTrack;
import three.animation.KeyframeTrack;
import three.utils.ConsoleWrapper;

class KeyframeTrackTests {
    static function main() {
        var parameters = {
            name: ".material.opacity",
            times: [0, 1],
            values: [0, 0.5],
            interpolation: NumberKeyframeTrack.DefaultInterpolation
        };

        var object = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values);
        haxe.Log.trace("NumberKeyframeTrack extends from KeyframeTrack: " + Std.is(object, KeyframeTrack));

        var object_all = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
        haxe.Log.trace("Can instantiate a NumberKeyframeTrack with name, times, values, interpolation: " + (object_all != null));

        var validTrack = new NumberKeyframeTrack(".material.opacity", [0, 1], [0, 0.5]);
        var invalidTrack = new NumberKeyframeTrack(".material.opacity", [0, 1], [0, js.NaN]);

        haxe.Log.trace("Valid track validation result: " + validTrack.validate());

        ConsoleWrapper.level = ConsoleWrapper.CONSOLE_LEVEL.OFF;
        haxe.Log.trace("Invalid track validation result: " + invalidTrack.validate());
        ConsoleWrapper.level = ConsoleWrapper.CONSOLE_LEVEL.DEFAULT;

        var track = new NumberKeyframeTrack(".material.opacity", [0, 1, 2, 3, 4], [0, 0, 0, 0, 1]);

        haxe.Log.trace("Track values length before optimization: " + track.values.length);

        track.optimize();

        haxe.Log.trace("Track times after optimization: " + track.times);
        haxe.Log.trace("Track values after optimization: " + track.values);
    }
}