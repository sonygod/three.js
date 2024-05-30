import js.QUnit;

import js.Three.helpers.SpotLightHelper;
import js.Three.core.Object3D;
import js.Three.lights.SpotLight;

class SpotLightHelperTest {
    static function extending() {
        var light = new SpotLight(0xaaaaaa);
        var object = new SpotLightHelper(light, 0xaaaaaa);
        var isInstanceOfObject3D = (object as Object3D) != null;
        QUnit.strictEqual(isInstanceOfObject3D, true, 'SpotLightHelper extends from Object3D');
    }

    static function instancing() {
        var light = new SpotLight(0xaaaaaa);
        var object = new SpotLightHelper(light, 0xaaaaaa);
        QUnit.ok(object != null, 'Can instantiate a SpotLightHelper.');
    }

    static function type() {
        var light = new SpotLight(0xaaaaaa);
        var object = new SpotLightHelper(light, 0xaaaaaa);
        QUnit.ok(object.type == 'SpotLightHelper', 'SpotLightHelper.type should be SpotLightHelper');
    }

    static function dispose() {
        var light = new SpotLight(0xaaaaaa);
        var object = new SpotLightHelper(light, 0xaaaaaa);
        object.dispose();
    }
}

QUnit.module('Helpers', function () {
    QUnit.module('SpotLightHelper', function () {
        QUnit.test('Extending', SpotLightHelperTest.extending);
        QUnit.test('Instancing', SpotLightHelperTest.instancing);
        QUnit.test('type', SpotLightHelperTest.type);
        QUnit.test('dispose', SpotLightHelperTest.dispose);
    });
});