package;

import js.Lib;
import js.Browser.window;
import three.js.test.unit.src.lights.DirectionalLight;
import three.js.test.unit.src.lights.Light;
import three.js.test.unit.src.utils.qunit_utils.runStdLightTests;

class Main {
    static function main() {
        var QUnit = Lib.require('qunit');

        QUnit.module('Lights', function() {
            QUnit.module('DirectionalLight', function(hooks) {
                var lights:Array<DirectionalLight>;
                hooks.beforeEach(function() {
                    var parameters = {
                        color: 0xaaaaaa,
                        intensity: 0.8
                    };

                    lights = [
                        new DirectionalLight(),
                        new DirectionalLight(parameters.color),
                        new DirectionalLight(parameters.color, parameters.intensity)
                    ];
                });

                // INHERITANCE
                QUnit.test('Extending', function(assert) {
                    var object = new DirectionalLight();
                    assert.strictEqual(
                        Std.is(object, Light), true,
                        'DirectionalLight extends from Light'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {
                    var object = new DirectionalLight();
                    assert.ok(object, 'Can instantiate a DirectionalLight.');
                });

                // PROPERTIES
                QUnit.test('type', function(assert) {
                    var object = new DirectionalLight();
                    assert.ok(
                        object.type == 'DirectionalLight',
                        'DirectionalLight.type should be DirectionalLight'
                    );
                });

                QUnit.todo('position', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('target', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('shadow', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isDirectionalLight', function(assert) {
                    var object = new DirectionalLight();
                    assert.ok(
                        object.isDirectionalLight,
                        'DirectionalLight.isDirectionalLight should be true'
                    );
                });

                QUnit.test('dispose', function(assert) {
                    assert.expect(0);

                    var object = new DirectionalLight();
                    object.dispose();

                    // ensure calls dispose() on shadow
                });

                QUnit.todo('copy', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // OTHERS
                QUnit.test('Standard light tests', function(assert) {
                    runStdLightTests(assert, lights);
                });
            });
        });
    }
}