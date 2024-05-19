import haxe.unit.TestCase;
import three.animation.tracks.StringKeyframeTrack;
import three.animation.KeyframeTrack;

class StringKeyframeTrackTests {
    public function new() {}

    public function testExtending():Void {
        var parameters = {
            name: '.name',
            times: [0, 1],
            values: ['foo', 'bar']
        };

        var object = new StringKeyframeTrack(parameters.name, parameters.times, parameters.values);
        assertTrue(object instanceof KeyframeTrack, 'StringKeyframeTrack extends from KeyframeTrack');
    }

    public function testInstancing():Void {
        var parameters = {
            name: '.name',
            times: [0, 1],
            values: ['foo', 'bar']
        };

        var object = new StringKeyframeTrack(parameters.name, parameters.times, parameters.values);
        assertNotNull(object, 'Can instantiate a StringKeyframeTrack.');
    }
}