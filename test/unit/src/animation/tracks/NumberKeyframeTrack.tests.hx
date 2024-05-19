package three.test.unit.src.animation.tracks;

import haxe.unit.TestCase;
import three.animation.tracks.NumberKeyframeTrack;
import three.animation.KeyframeTrack;

class NumberKeyframeTrackTests {

    public function new() { }

    public function testExtending():Void {
        var parameters = {
            name: '.material.opacity',
            times: [0, 1],
            values: [0, 0.5],
            interpolation: NumberKeyframeTrack.DefaultInterpolation
        };

        var object = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values);
        assertEquals(true, Std.is(object, KeyframeTrack), 'NumberKeyframeTrack extends from KeyframeTrack');
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

        var object_all = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
        assertNotNull(object_all, 'Can instantiate a NumberKeyframeTrack with name, times, values, interpolation.');
    }
}