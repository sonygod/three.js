package;

import js.Browser.window;
import js.Lib.QUnit;
import three.js.src.lights.AmbientLight;
import three.js.src.lights.Light;
import three.js.test.utils.qunitUtils.runStdLightTests;

class AmbientLightTests {

    static function main() {
        var module = QUnit.module('Lights');
        module.module('AmbientLight', (hooks) -> {
            var lights:Array<AmbientLight>;
            hooks.beforeEach(() -> {
                var parameters = {
                    color: 0xaaaaaa,
                    intensity: 0.5
                };
                lights = [
                    new AmbientLight(),
                    new AmbientLight(parameters.color),
                    new AmbientLight(parameters.color, parameters.intensity)
                ];
            });

            // INHERITANCE
            QUnit.test('Extending', (assert) -> {
                var object = new AmbientLight();
                assert.strictEqual(
                    Std.is(object, Light), true,
                    'AmbientLight extends from Light'
                );
            });

            // INSTANCING
            QUnit.test('Instancing', (assert) -> {
                var object = new AmbientLight();
                assert.ok(object, 'Can instantiate an AmbientLight.');
            });

            // PROPERTIES
            QUnit.test('type', (assert) -> {
                var object = new AmbientLight();
                assert.ok(
                    object.type == 'AmbientLight',
                    'AmbientLight.type should be AmbientLight'
                );
            });

            // PUBLIC
            QUnit.test('isAmbientLight', (assert) -> {
                var object = new AmbientLight();
                assert.ok(
                    object.isAmbientLight,
                    'AmbientLight.isAmbientLight should be true'
                );
            });

            // OTHERS
            QUnit.test('Standard light tests', (assert) -> {
                runStdLightTests(assert, lights);
            });
        });
    }
}

class TestRunner {
    static function main() {
        AmbientLightTests.main();
        QUnit.start();
    }
}

window.onload = TestRunner.main;