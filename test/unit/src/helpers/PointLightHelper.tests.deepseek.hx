package;

import js.Lib;
import three.js.test.unit.src.helpers.PointLightHelper;
import three.js.test.unit.src.objects.Mesh;
import three.js.test.unit.src.lights.PointLight;

class TestPointLightHelper {

    static function main() {
        var parameters = {
            sphereSize: 1,
            color: 0xaaaaaa,
            intensity: 0.5,
            distance: 100,
            decay: 2
        };

        // INHERITANCE
        QUnit.test("Extending", function(assert) {
            var light = new PointLight(parameters.color);
            var object = new PointLightHelper(light, parameters.sphereSize, parameters.color);
            assert.strictEqual(
                Std.is(object, Mesh), true,
                'PointLightHelper extends from Mesh'
            );
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
            var light = new PointLight(parameters.color);
            var object = new PointLightHelper(light, parameters.sphereSize, parameters.color);
            assert.ok(object != null, 'Can instantiate a PointLightHelper.');
        });

        // PROPERTIES
        QUnit.test("type", function(assert) {
            var light = new PointLight(parameters.color);
            var object = new PointLightHelper(light, parameters.sphereSize, parameters.color);
            assert.ok(
                object.type == 'PointLightHelper',
                'PointLightHelper.type should be PointLightHelper'
            );
        });

        QUnit.todo("light", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo("color", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo("matrix", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo("matrixAutoUpdate", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        QUnit.test("dispose", function(assert) {
            assert.expect(0);
            var light = new PointLight(parameters.color);
            var object = new PointLightHelper(light, parameters.sphereSize, parameters.color);
            object.dispose();
        });

        QUnit.todo("update", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}