package three.animation;

import three.animation.tracks.NumberKeyframeTrack;
import three.animation.KeyframeTrack;
import three.utils.ConsoleWrapper.CONSOLE_LEVEL;

class KeyframeTrackTests {
    public static function main() {
        // INHERITANCE
        QTest.test("Extending", function(assert) {
            var object = new NumberKeyframeTrack(".material.opacity", [0, 1], [0, 0.5]);
            assert.isTrue(object instanceof KeyframeTrack, 'NumberKeyframeTrack extends from KeyframeTrack');
        });

        // INSTANCING
        QTest.test("Instancing", function(assert) {
            // name, times, values
            var object = new NumberKeyframeTrack(".material.opacity", [0, 1], [0, 0.5]);
            assert.notNull(object, 'Can instantiate a NumberKeyframeTrack.');

            // name, times, values, interpolation
            var object_all = new NumberKeyframeTrack(".material.opacity", [0, 1], [0, 0.5], NumberKeyframeTrack.DefaultInterpolation);
            assert.notNull(object_all, 'Can instantiate a NumberKeyframeTrack with name, times, values, interpolation.');
        });

        // PROPERTIES
        QTest.todo("name", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        QTest.todo("times", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        QTest.todo("values", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        // PROPERTIES - PROTOTYPE
        QTest.todo("TimeBufferType", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        QTest.todo("ValueBufferType", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        QTest.todo("DefaultInterpolation", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        // STATIC
        QTest.todo("toJSON", function(assert) {
            // static method toJSON
            assert.fail('everything\'s gonna be alright');
        });

        // PUBLIC
        QTest.todo("InterpolantFactoryMethodDiscrete", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        QTest.todo("InterpolantFactoryMethodLinear", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        QTest.todo("InterpolantFactoryMethodSmooth", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        QTest.todo("setInterpolation", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        QTest.todo("getInterpolation", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        QTest.todo("getValueSize", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        QTest.todo("shift", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        QTest.todo("scale", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        QTest.todo("trim", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        QTest.test("validate", function(assert) {
            var validTrack = new NumberKeyframeTrack(".material.opacity", [0, 1], [0, 0.5]);
            var invalidTrack = new NumberKeyframeTrack(".material.opacity", [0, 1], [0, Math.NaN]);

            assert.isTrue(validTrack.validate());

            ConsoleWrapper.setLevel(CONSOLE_LEVEL.OFF);
            assert.isFalse(invalidTrack.validate());
            ConsoleWrapper.setLevel(CONSOLE_LEVEL.DEFAULT);
        });

        QTest.test("optimize", function(assert) {
            var track = new NumberKeyframeTrack(".material.opacity", [0, 1, 2, 3, 4], [0, 0, 0, 0, 1]);

            assert.equals(track.values.length, 5);

            track.optimize();

            assert.smartEquals(track.times, [0, 3, 4]);
            assert.smartEquals(track.values, [0, 0, 1]);
        });

        QTest.todo("clone", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });
    }
}