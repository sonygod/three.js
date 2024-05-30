import js.QUnit;

import js.three.AxesHelper;
import js.three.LineSegments;

class AxesHelperTest {
    static function extending() {
        var object = new AxesHelper();
        var isInstanceOfLineSegments = (object instanceof LineSegments);
        QUnit.strictEqual(isInstanceOfLineSegments, true, "AxesHelper extends from LineSegments");
    }

    static function instancing() {
        var object = new AxesHelper();
        QUnit.ok(object != null, "Can instantiate an AxesHelper.");
    }

    static function type() {
        var object = new AxesHelper();
        QUnit.ok(object.getType() == "AxesHelper", "AxesHelper.type should be AxesHelper");
    }

    static function setColors() {
        // TODO: Implement test for setColors method
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function dispose() {
        var object = new AxesHelper();
        object.dispose();
    }
}

QUnit.module("Helpers", {
    beforeEach: function() {},
    afterEach: function() {}
});

QUnit.module("AxesHelper", {
    beforeEach: function() {},
    afterEach: function() {}
});

QUnit.test("Extending", AxesHelperTest.extending);
QUnit.test("Instancing", AxesHelperTest.instancing);
QUnit.test("Type", AxesHelperTest.type);
QUnit.todo("SetColors", AxesHelperTest.setColors);
QUnit.test("Dispose", AxesHelperTest.dispose);