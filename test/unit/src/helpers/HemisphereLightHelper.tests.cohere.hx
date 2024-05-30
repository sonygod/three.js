import js.QUnit.*;
import js.three.*;

class HemisphereLightHelperTest {
    static function extending() {
        var light = new HemisphereLight(0xabc012);
        var object = new HemisphereLightHelper(light, 1, 0xabc012);
        assert.strictEqual(Std.is(object, Object3D), true, "HemisphereLightHelper extends from Object3D");
    }

    static function instancing() {
        var light = new HemisphereLight(0xabc012);
        var object = new HemisphereLightHelper(light, 1, 0xabc012);
        assert.ok(object != null, "Can instantiate a HemisphereLightHelper.");
    }

    static function type() {
        var light = new HemisphereLight(0xabc012);
        var object = new HemisphereLightHelper(light, 1, 0xabc012);
        assert.ok(object.getType() == "HemisphereLightHelper", "HemisphereLightHelper.type should be HemisphereLightHelper");
    }

    static function dispose() {
        var light = new HemisphereLight(0xabc012);
        var object = new HemisphereLightHelper(light, 1, 0xabc012);
        object.dispose();
    }
}

module(module, "Helpers", "HemisphereLightHelper");
test("Extending", HemisphereLightHelperTest.extending);
test("Instancing", HemisphereLightHelperTest.instancing);
test("Type", HemisphereLightHelperTest.type);
test("Dispose", HemisphereLightHelperTest.dispose);