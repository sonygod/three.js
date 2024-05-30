package;

import js.QUnit;

class TestExtras {
    public static function test() {
        var module = QUnit.module("Extras");

        module.module("Core").module("Interpolations", function() {
            // PUBLIC
            QUnit.todo("CatmullRom", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            QUnit.todo("QuadraticBezier", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            QUnit.todo("CubicBezier", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });
        });
    }
}