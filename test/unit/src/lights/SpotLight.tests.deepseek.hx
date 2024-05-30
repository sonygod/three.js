package three.js.test.unit.src.lights;

import three.js.src.lights.SpotLight;
import three.js.src.lights.Light;
import three.js.utils.qunit_utils.QUnit;
import three.js.utils.qunit_utils.runStdLightTests;

class SpotLightTests {

    public static function main():Void {
        QUnit.module('Lights', function() {
            QUnit.module('SpotLight', function(hooks) {
                var lights:Array<SpotLight>;
                hooks.beforeEach(function() {
                    var parameters = {
                        color: 0xaaaaaa,
                        intensity: 0.5,
                        distance: 100,
                        angle: 0.8,
                        penumbra: 8,
                        decay: 2
                    };
                    lights = [
                        new SpotLight(parameters.color),
                        new SpotLight(parameters.color, parameters.intensity),
                        new SpotLight(parameters.color, parameters.intensity, parameters.distance),
                        new SpotLight(parameters.color, parameters.intensity, parameters.distance, parameters.angle),
                        new SpotLight(parameters.color, parameters.intensity, parameters.distance, parameters.angle, parameters.penumbra),
                        new SpotLight(parameters.color, parameters.intensity, parameters.distance, parameters.angle, parameters.penumbra, parameters.decay)
                    ];
                });

                // INHERITANCE
                QUnit.test('Extending', function(assert) {
                    var object = new SpotLight();
                    assert.strictEqual(
                        Std.is(object, Light), true,
                        'SpotLight extends from Light'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {
                    var object = new SpotLight();
                    assert.ok(object, 'Can instantiate a SpotLight.');
                });

                // PROPERTIES
                QUnit.test('type', function(assert) {
                    var object = new SpotLight();
                    assert.ok(
                        object.type == 'SpotLight',
                        'SpotLight.type should be SpotLight'
                    );
                });

                QUnit.todo('position', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('target', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('distance', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('angle', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('penumbra', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('decay', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('map', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('shadow', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test('power', function(assert) {
                    var a = new SpotLight(0xaaaaaa);
                    a.intensity = 100;
                    assert.numEqual(a.power, 100 * Math.PI, 'Correct power for an intensity of 100');
                    a.intensity = 40;
                    assert.numEqual(a.power, 40 * Math.PI, 'Correct power for an intensity of 40');
                    a.power = 100;
                    assert.numEqual(a.intensity, 100 / Math.PI, 'Correct intensity for a power of 100');
                });

                // PUBLIC
                QUnit.test('isSpotLight', function(assert) {
                    var object = new SpotLight();
                    assert.ok(
                        object.isSpotLight,
                        'SpotLight.isSpotLight should be true'
                    );
                });

                QUnit.test('dispose', function(assert) {
                    assert.expect(0);
                    var object = new SpotLight();
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