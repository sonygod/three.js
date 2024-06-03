import three.animation.KeyframeTrack;
import three.animation.tracks.QuaternionKeyframeTrack;

class QuaternionKeyframeTrackTests {

    public static function main() {

        var parameters = {
            name: ".rotation",
            times: [0.0],
            values: [0.5, 0.5, 0.5, 1.0],
            interpolation: QuaternionKeyframeTrack.DefaultInterpolation
        };

        testExtending(parameters);
        testInstancing(parameters);
    }

    private static function testExtending(parameters:Dynamic) {
        var object = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values);
        // Replace the following line with your assertion library
        trace(Std.is(object, KeyframeTrack), 'QuaternionKeyframeTrack extends from KeyframeTrack');
    }

    private static function testInstancing(parameters:Dynamic) {
        var object = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values);
        // Replace the following line with your assertion library
        trace(object != null, 'Can instantiate a QuaternionKeyframeTrack.');

        var object_all = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
        // Replace the following line with your assertion library
        trace(object_all != null, 'Can instantiate a QuaternionKeyframeTrack with name, times, values, interpolation.');
    }
}