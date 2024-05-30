package three.animation.tracks;

import haxe.unit.TestCase;
import three.animation.tracks.NumberKeyframeTrack;
import three.animation.tracks.KeyframeTrack;

class NumberKeyframeTrackTest {
    public function new() {}

    public function testInheritance():Void {
        var parameters = {
            name: '.material.opacity',
            times: [0, 1],
            values: [0, 0.5],
            interpolation: NumberKeyframeTrack.DefaultInterpolation
        };

        var object = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values);
        assertTrue(object instanceof KeyframeTrack, 'NumberKeyframeTrack extends from KeyframeTrack');
    }

    public function testInstancing():Void {
        var parameters = {
            name: '.material.opacity',
            times: [0, 1],
            values: [0, 0.5],
            interpolation: NumberKeyframeTrack.DefaultInterpolation
        };

        var object = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values);
        assertNotNull(object, 'Can instantiate a NumberKeyframeTrack.');

        var objectAll = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
        assertNotNull(objectAll, 'Can instantiate a NumberKeyframeTrack with name, times, values, interpolation.');
    }
}