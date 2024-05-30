import js.QUnit;

import js.Three.DirectionalLightHelper;
import js.Three.Object3D;
import js.Three.DirectionalLight;

class DirectionalLightHelperTest {
    static function extending() {
        var light = new DirectionalLight(0xaaaaaa);
        var object = new DirectionalLightHelper(light, 1, 0xaaaaaa);
        QUnit.strictEqual(Std.is(object, Object3D), true, "DirectionalLightHelper extends from Object3D");
    }

    static function instancing() {
        var light = new DirectionalLight(0xaaaaaa);
        var object = new DirectionalLightHelper(light, 1, 0xaaaaaa);
        QUnit.ok(object != null, "Can instantiate a DirectionalLightHelper.");
    }

    static function type() {
        var light = new DirectionalLight(0xaaaaaa);
        var object = new DirectionalLightHelper(light, 1, 0xaaaaaa);
        QUnit.ok(object.type == "DirectionalLightHelper", "DirectionalLightHelper.type should be DirectionalLightHelper");
    }

    static function dispose() {
        var light = new DirectionalLight(0xaaaaaa);
        var object = new DirectionalLightHelper(light, 1, 0xaaaaaa);
        object.dispose();
    }
}

class DirectionalLightHelperTests {
    static function main() {
        QUnit.module("Helpers", {
            beforeEach: function() {
                // ...
            },
            afterEach: function() {
                // ...
            }
        });

        QUnit.module("DirectionalLightHelper", {
            beforeEach: function() {
                // ...
            },
            afterEach: function() {
                // ...
            }
        });

        DirectionalLightHelperTest.extending();
        DirectionalLightHelperTest.instancing();
        DirectionalLightHelperTest.type();
        DirectionalLightHelperTest.dispose();
    }
}

DirectionalLightHelperTests.main();