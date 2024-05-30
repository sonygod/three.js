import js.QUnit;

import js.Three.ArrowHelper;
import js.Three.Object3D;

class ArrowHelperTest {
    static function extending() {
        var object = new ArrowHelper();
        var isInstanceOfObject3D = (object instanceof Object3D);
        QUnit.strictEqual(isInstanceOfObject3D, true, "ArrowHelper extends from Object3D");
    }

    static function instancing() {
        var object = new ArrowHelper();
        QUnit.ok(object, "Can instantiate an ArrowHelper.");
    }

    static function type() {
        var object = new ArrowHelper();
        QUnit.ok(object.type == "ArrowHelper", "ArrowHelper.type should be ArrowHelper");
    }

    static function position() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function line() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function cone() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function setDirection() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function setLength() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function setColor() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function copy() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function dispose() {
        var object = new ArrowHelper();
        object.dispose();
    }
}

QUnit.module("Helpers", {
    beforeEach: function() {},
    afterEach: function() {}
});

QUnit.module("ArrowHelper", {
    beforeEach: function() {},
    afterEach: function() {}
});

QUnit.test("Extending", ArrowHelperTest.extending);
QUnit.test("Instancing", ArrowHelperTest.instancing);
QUnit.test("Type", ArrowHelperTest.type);
QUnit.test("Position", ArrowHelperTest.position);
QUnit.test("Line", ArrowHelperTest.line);
QUnit.test("Cone", ArrowHelperTest.cone);
QUnit.test("SetDirection", ArrowHelperTest.setDirection);
QUnit.test("SetLength", ArrowHelperTest.setLength);
QUnit.test("SetColor", ArrowHelperTest.setColor);
QUnit.test("Copy", ArrowHelperTest.copy);
QUnit.test("Dispose", ArrowHelperTest.dispose);