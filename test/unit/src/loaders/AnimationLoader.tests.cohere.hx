import js.QUnit;
import js.d.QUnit.QUnitModule;

import openfl.display.AnimationLoader;
import openfl.display.Loader;

class TestAnimationLoader {
    static function main() {
        var module = QUnit.module("Loaders");
        module.module("AnimationLoader", function () {
            QUnit.test("Extending", function () {
                var object = new AnimationLoader();
                var expected = true;
                var actual = Std.is(object, Loader);
                Js.console.log("expected: " + expected);
                Js.console.log("actual: " + actual);
                Js.console.log("equal: " + (expected == actual));
                QUnit.strictEqual(actual, expected, "AnimationLoader extends from Loader");
            });

            QUnit.test("Instancing", function () {
                var object = new AnimationLoader();
                QUnit.ok(object != null, "Can instantiate an AnimationLoader.");
            });

            QUnit.todo("load", function () {
                QUnit.ok(false, "everything's gonna be alright");
            });

            QUnit.todo("parse", function () {
                QUnit.ok(false, "everything's gonna be alright");
            });
        });
    }
}

TestAnimationLoader.main();