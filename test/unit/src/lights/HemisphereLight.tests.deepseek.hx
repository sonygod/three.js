package;

import js.Lib;
import js.Browser.window;
import three.js.test.unit.src.lights.HemisphereLight;
import three.js.test.unit.src.lights.Light;
import three.js.test.unit.utils.qunitUtils;

class HemisphereLightTests {

    static function main() {
        var QUnit = Lib.require('qunit');

        QUnit.module('Lights', function() {

            QUnit.module('HemisphereLight', function(hooks) {

                var lights:Array<HemisphereLight>;
                hooks.beforeEach(function() {

                    var parameters = {
                        skyColor: 0x123456,
                        groundColor: 0xabc012,
                        intensity: 0.6
                    };

                    lights = [
                        new HemisphereLight(),
                        new HemisphereLight(parameters.skyColor),
                        new HemisphereLight(parameters.skyColor, parameters.groundColor),
                        new HemisphereLight(parameters.skyColor, parameters.groundColor, parameters.intensity),
                    ];

                });

                // INHERITANCE
                QUnit.test('Extending', function(assert) {

                    var object = new HemisphereLight();
                    assert.strictEqual(
                        Std.is(object, Light), true,
                        'HemisphereLight extends from Light'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {

                    var object = new HemisphereLight();
                    assert.ok(object, 'Can instantiate a HemisphereLight.');

                });

                // PROPERTIES
                QUnit.test('type', function(assert) {

                    var object = new HemisphereLight();
                    assert.ok(
                        object.type == 'HemisphereLight',
                        'HemisphereLight.type should be HemisphereLight'
                    );

                });

                QUnit.todo('position', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('groundColor', function(assert) {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.test('isHemisphereLight', function(assert) {

                    var object = new HemisphereLight();
                    assert.ok(
                        object.isHemisphereLight,
                        'HemisphereLight.isHemisphereLight should be true'
                    );

                });

                QUnit.todo('copy', function(assert) {

                    // copy( source, recursive )
                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // OTHERS
                QUnit.test('Standard light tests', function(assert) {

                    qunitUtils.runStdLightTests(assert, lights);

                });

            });

        });
    }
}