import js.QUnit;

import js.three.Box3Helper;
import js.three.LineSegments;

class Box3HelperTest {
    static function extending() {
        var object = new Box3Helper();
        var isInstanceOfLineSegments = (object instanceof LineSegments);
        QUnit.strictEqual(isInstanceOfLineSegments, true, "Box3Helper extends from LineSegments");
    }

    static function instancing() {
        var object = new Box3Helper();
        QUnit.ok(object != null, "Can instantiate a Box3Helper.");
    }

    static function type() {
        var object = new Box3Helper();
        QUnit.ok(object.type == "Box3Helper", "Box3Helper.type should be Box3Helper");
    }

    static function box() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function updateMatrixWorld() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function dispose() {
        QUnit.expect(0);
        var object = new Box3Helper();
        object.dispose();
    }

    public static function main() {
        QUnit.module("Helpers", {
            beforeEach: function() {},
            afterEach: function() {}
        });

        QUnit.module("Box3Helper", {
            beforeEach: function() {},
            afterEach: function() {}
        });

        extending();
        instancing();
        type();
        box();
        updateMatrixWorld();
        dispose();
    }
}

Box3HelperTest.main();