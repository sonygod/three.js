package three.js.test.unit.src.animation.tracks;

import haxe.unit.TestCase;
import three.animation.tracks.BooleanKeyframeTrack;
import three.animation.KeyframeTrack;

class BooleanKeyframeTrackTest {
    public function new() {}

    public function testExtending() {
        var parameters = {
            name: '.visible',
            times: [0, 1],
            values: [true, false]
        };
        var object = new BooleanKeyframeTrack(parameters.name, parameters.times, parameters.values);
        assertTrue(object instanceof KeyframeTrack, 'BooleanKeyframeTrack extends from KeyframeTrack');
    }

    public function testInstancing() {
        var parameters = {
            name: '.visible',
            times: [0, 1],
            values: [true, false]
        };
        var object = new BooleanKeyframeTrack(parameters.name, parameters.times, parameters.values);
        assertNotNull(object, 'Can instantiate a BooleanKeyframeTrack.');
    }
}