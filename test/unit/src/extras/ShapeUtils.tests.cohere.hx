package;

import js.QUnit;

class TestExtras {
    static public function test() {
        QUnit.module("Extras");

        QUnit.module("ShapeUtils");

        // STATIC
        QUnit.todo("area", fun(assert:QUnitAssert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("isClockWise", fun(assert:QUnitAssert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("triangulateShape", fun(assert:QUnitAssert) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}