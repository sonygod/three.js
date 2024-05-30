import js.QUnit;

import js.Three.PointLightHelper;
import js.Three.Mesh;
import js.Three.PointLight;

class PointLightHelperTest {
    static function extending() {
        var light = new PointLight(0xaaaaaa);
        var object = new PointLightHelper(light, 1, 0xaaaaaa);
        var assert = QUnit.test("Extending");
        assert.strictEqual(object instanceof Mesh, true, "PointLightHelper extends from Mesh");
    }

    static function instancing() {
        var light = new PointLight(0xaaaaaa);
        var object = new PointLightHelper(light, 1, 0xaaaaaa);
        var assert = QUnit.test("Instancing");
        assert.ok(object, "Can instantiate a PointLightHelper.");
    }

    static function type() {
        var light = new PointLight(0xaaaaaa);
        var object = new PointLightHelper(light, 1, 0xaaaaaa);
        var assert = QUnit.test("type");
        assert.ok(object.type == "PointLightHelper", "PointLightHelper.type should be PointLightHelper");
    }

    static function dispose() {
        var light = new PointLight(0xaaaaaa);
        var object = new PointLightHelper(light, 1, 0xaaaaaa);
        var assert = QUnit.test("dispose");
        object.dispose();
    }
}

class PointLightHelperTests {
    static function main() {
        QUnit.module('Helpers', function () {
            QUnit.module('PointLightHelper', function () {
                PointLightHelperTest.extending();
                PointLightHelperTest.instancing();
                PointLightHelperTest.type();
                PointLightHelperTest.dispose();
            });
        });
    }
}

PointLightHelperTests.main();