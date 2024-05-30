// 导入必要的模块
import js.Browser.window;
import js.Lib.QUnit;
import three.js.src.helpers.HemisphereLightHelper;
import three.js.src.core.Object3D;
import three.js.src.lights.HemisphereLight;

class HemisphereLightHelperTest {
    static function main() {
        var module = QUnit.module("Helpers");
        module.module("HemisphereLightHelper");

        var parameters = {
            size: 1,
            color: 0xabc012,
            skyColor: 0x123456,
            groundColor: 0xabc012,
            intensity: 0.6
        };

        // INHERITANCE
        QUnit.test("Extending", function(assert) {
            var light = new HemisphereLight(parameters.skyColor);
            var object = new HemisphereLightHelper(light, parameters.size, parameters.color);
            assert.strictEqual(object instanceof Object3D, true, 'HemisphereLightHelper extends from Object3D');
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
            var light = new HemisphereLight(parameters.skyColor);
            var object = new HemisphereLightHelper(light, parameters.size, parameters.color);
            assert.ok(object, 'Can instantiate a HemisphereLightHelper.');
        });

        // PROPERTIES
        QUnit.test("type", function(assert) {
            var light = new HemisphereLight(parameters.skyColor);
            var object = new HemisphereLightHelper(light, parameters.size, parameters.color);
            assert.ok(object.type === 'HemisphereLightHelper', 'HemisphereLightHelper.type should be HemisphereLightHelper');
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

        QUnit.todo("material", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        QUnit.test("dispose", function(assert) {
            assert.expect(0);
            var light = new HemisphereLight(parameters.skyColor);
            var object = new HemisphereLightHelper(light, parameters.size, parameters.color);
            object.dispose();
        });

        QUnit.todo("update", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}

class TestMain {
    static function main() {
        HemisphereLightHelperTest.main();
    }
}

window.onload = TestMain.main;