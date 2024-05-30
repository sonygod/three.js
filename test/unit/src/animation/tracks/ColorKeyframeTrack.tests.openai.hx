package three.animation.tracks;

import three.animation.tracks.ColorKeyframeTrack;
import three.animation.KeyframeTrack;
import qunit.framework.TestCase;

class ColorKeyframeTrackTests extends TestCase {

    function new() {
        super();
    }

    override public function setup() {}

    function testExtending():Void {
        var parameters = {
            name: '.material.diffuse',
            times: [0, 1],
            values: [0, 0.5, 1.0],
            interpolation: ColorKeyframeTrack.DefaultInterpolation
        };

        var object = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values);
        Assert.isTrue(Std.is(object, KeyframeTrack), 'ColorKeyframeTrack extends from KeyframeTrack');
    }

    function testInstancing():Void {
        var parameters = {
            name: '.material.diffuse',
            times: [0, 1],
            values: [0, 0.5, 1.0],
            interpolation: ColorKeyframeTrack.DefaultInterpolation
        };

        var object = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values);
        Assert.notNull(object, 'Can instantiate a ColorKeyframeTrack.');

        var object_all = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
        Assert.notNull(object_all, 'Can instantiate a ColorKeyframeTrack with name, times, values, interpolation.');
    }
}