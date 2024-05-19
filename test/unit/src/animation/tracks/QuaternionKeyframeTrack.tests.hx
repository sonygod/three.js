package three.animation.tracks;

import haxe.unit.TestCase;
import three.animation.tracks.QuaternionKeyframeTrack;
import three.animation.KeyframeTrack;

class QuaternionKeyframeTrackTest {

    public function new() {}

    public function testQuaternionKeyframeTrack() {
        var parameters = {
            name: '.rotation',
            times: [0],
            values: [0.5, 0.5, 0.5, 1],
            interpolation: QuaternionKeyframeTrack.DefaultInterpolation
        };

        // INHERITANCE
        testCase("Extending", function(assert) {
            var object = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values);
            assert.isTrue(Std.is(object, KeyframeTrack), 'QuaternionKeyframeTrack extends from KeyframeTrack');
        });

        // INSTANCING
        testCase("Instancing", function(assert) {
            // name, times, values
            var object = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values);
            assert.isTrue(object != null, 'Can instantiate a QuaternionKeyframeTrack.');

            // name, times, values, interpolation
            var object_all = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
            assert.isTrue(object_all != null, 'Can instantiate a QuaternionKeyframeTrack with name, times, values, interpolation.');
        });
    }
}