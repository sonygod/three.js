package three.test.unit.src.animation.tracks;

import haxe.unit.TestCase;
import three.animation.tracks.ColorKeyframeTrack;
import three.animation.KeyframeTrack;

class ColorKeyframeTrackTest {
    public static function main() {
        var testCase = new TestCase();
        testCase.test('Animation', () => {
            testCase.test('Tracks', () => {
                testCase.test('ColorKeyframeTrack', () => {
                    var parameters = {
                        name: '.material.diffuse',
                        times: [0, 1],
                        values: [0, 0.5, 1.0],
                        interpolation: ColorKeyframeTrack.DefaultInterpolation
                    };

                    // INHERITANCE
                    testCase.test('Extending', () => {
                        var object = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        testCase.assertEquals(Type.enumEq(object, KeyframeTrack), true, 'ColorKeyframeTrack extends from KeyframeTrack');
                    });

                    // INSTANCING
                    testCase.test('Instancing', () => {
                        // name, times, values
                        var object = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values);
                        testCase.assertNotNull(object, 'Can instantiate a ColorKeyframeTrack.');

                        // name, times, values, interpolation
                        var object_all = new ColorKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
                        testCase.assertNotNull(object_all, 'Can instantiate a ColorKeyframeTrack with name, times, values, interpolation.');
                    });
                });
            });
        });
    }
}