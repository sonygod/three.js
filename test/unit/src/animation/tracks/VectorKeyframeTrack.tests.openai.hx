import haxe.unit.TestCase;
import three.animation.tracks.VectorKeyframeTrack;
import three.animation.KeyframeTrack;

class VectorKeyframeTrackTests {
    public function new() {}

    public function testAll() {
        testExtending();
        testInstancing();
    }

    private function testExtending() {
        var parameters = {
            name: '.force',
            times: [0],
            values: [0.5, 0.5, 0.5],
            interpolation: VectorKeyframeTrack.DefaultInterpolation
        };

        var object = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values);
        TestCase.assertTrue(object instanceof KeyframeTrack, 'VectorKeyframeTrack extends from KeyframeTrack');
    }

    private function testInstancing() {
        var parameters = {
            name: '.force',
            times: [0],
            values: [0.5, 0.5, 0.5],
            interpolation: VectorKeyframeTrack.DefaultInterpolation
        };

        // name, times, values
        var object = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values);
        TestCase.assertNotNull(object, 'Can instantiate a VectorKeyframeTrack.');

        // name, times, values, interpolation
        var objectAll = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
        TestCase.assertNotNull(objectAll, 'Can instantiate a VectorKeyframeTrack with name, times, values, interpolation.');
    }
}