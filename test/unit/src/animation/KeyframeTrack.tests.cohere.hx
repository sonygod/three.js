package;

import js.QUnit;

import js.animation.NumberKeyframeTrack;
import js.animation.KeyframeTrack;
import js.animation.Interpolation;
import js.utils.console.ConsoleWrapper;

class AnimationTest {
    static function keyframeTrack() {
        var parameters = {
            name: ".material.opacity",
            times: [0, 1],
            values: [0, 0.5],
            interpolation: NumberKeyframeTrack.DefaultInterpolation
        };

        // INHERITANCE
        QUnit.test("Extending", function() {
            var object = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values);
            QUnit.strictEqual(Std.is(object, KeyframeTrack), true, "NumberKeyframeTrack extends from KeyframeTrack");
        });

        // INSTANCING
        QUnit.test("Instancing", function() {
            // name, times, values
            var object = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values);
            QUnit.ok(object, "Can instantiate a NumberKeyframeTrack.");

            // name, times, values, interpolation
            var object_all = new NumberKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
            QUnit.ok(object_all, "Can instantiate a NumberKeyframeTrack with name, times, values, interpolation.");
        });

        // PROPERTIES
        QUnit.todo("name", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("times", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("values", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        // PROPERTIES - PROTOTYPE
        QUnit.todo("TimeBufferType", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("ValueBufferType", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("DefaultInterpolation", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        // STATIC
        QUnit.todo("toJSON", function() {
            // static method toJSON
            QUnit.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.todo("InterpolantFactoryMethodDiscrete", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("InterpolantFactoryMethodLinear", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("InterpolantFactoryMethodSmooth", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setInterpolation", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getInterpolation", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getValueSize", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("shift", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("scale", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("trim", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.test("validate", function() {
            var validTrack = new NumberKeyframeTrack(".material.opacity", [0, 1], [0, 0.5]);
            var invalidTrack = new NumberKeyframeTrack(".material.opacity", [0, 1], [0, NaN]);

            QUnit.ok(validTrack.validate());

            ConsoleWrapper.console.level = ConsoleWrapper.CONSOLE_LEVEL.OFF;
            QUnit.notOk(invalidTrack.validate());
            ConsoleWrapper.console.level = ConsoleWrapper.CONSOLE_LEVEL.DEFAULT;
        });

        QUnit.test("optimize", function() {
            var track = new NumberKeyframeTrack(".material.opacity", [0, 1, 2, 3, 4], [0, 0, 0, 0, 1]);

            QUnit.equal(track.values.length, 5);

            track.optimize();

            QUnit.smartEqual(track.times.toArray(), [0, 3, 4]);
            QUnit.smartEqual(track.values.toArray(), [0, 0, 1]);
        });

        QUnit.todo("clone", function() {
            QUnit.ok(false, "everything's gonna be alright");
        });
    }
}

QUnit.module("Animation", function() {
    QUnit.module("KeyframeTrack", function() {
        AnimationTest.keyframeTrack();
    });
});