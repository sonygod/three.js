package three.test.unit.src.animation.tracks;

import haxe.unit.TestCase;
import three.animation.tracks.VectorKeyframeTrack;
import three.animation.KeyframeTrack;

class VectorKeyframeTrackTest {
    public function new() {}

    public function testExtending() {
        var parameters = {
            name: '.force',
            times: [0],
            values: [0.5, 0.5, 0.5],
            interpolation: VectorKeyframeTrack.DefaultInterpolation
        };

        var object = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values);
        assertTrue(object instanceof KeyframeTrack, 'VectorKeyframeTrack extends from KeyframeTrack');
    }

    public function testInstancing() {
        var parameters = {
            name: '.force',
            times: [0],
            values: [0.5, 0.5, 0.5],
            interpolation: VectorKeyframeTrack.DefaultInterpolation
        };

        var object = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values);
        assertNotNull(object, 'Can instantiate a VectorKeyframeTrack.');

        var object_all = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
        assertNotNull(object_all, 'Can instantiate a VectorKeyframeTrack with name, times, values, interpolation.');
    }
}