package three.js.test.unit.src.helpers;

import three.js.src.helpers.DirectionalLightHelper;
import three.js.src.core.Object3D;
import three.js.src.lights.DirectionalLight;

class DirectionalLightHelperTests {

    static function main() {
        var parameters = {
            size: 1,
            color: 0xaaaaaa,
            intensity: 0.8
        };

        // INHERITANCE
        QUnit.test("Extending", function(assert) {
            var light = new DirectionalLight(parameters.color);
            var object = new DirectionalLightHelper(light, parameters.size, parameters.color);
            assert.strictEqual(
                Std.is(object, Object3D), true,
                'DirectionalLightHelper extends from Object3D'
            );
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
            var light = new DirectionalLight(parameters.color);
            var object = new DirectionalLightHelper(light, parameters.size, parameters.color);
            assert.ok(object, 'Can instantiate a DirectionalLightHelper.');
        });

        // PROPERTIES
        QUnit.test("type", function(assert) {
            var light = new DirectionalLight(parameters.color);
            var object = new DirectionalLightHelper(light, parameters.size, parameters.color);
            assert.ok(
                object.type == 'DirectionalLightHelper',
                'DirectionalLightHelper.type should be DirectionalLightHelper'
            );
        });

        QUnit.todo("light", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo("matrix", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo("matrixAutoUpdate", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo("color", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        QUnit.test("dispose", function(assert) {
            assert.expect(0);
            var light = new DirectionalLight(parameters.color);
            var object = new DirectionalLightHelper(light, parameters.size, parameters.color);
            object.dispose();
        });

        QUnit.todo("update", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}