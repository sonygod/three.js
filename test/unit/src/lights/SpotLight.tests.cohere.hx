import js.QUnit.*;
import js.WebGL.*;

import js.Three.Light;
import js.Three.SpotLight;
import js.Three.SpotLightParameters;

import js.Three.tests.qunit.qunitUtils.runStdLightTests;

class SpotLightTest {
    static function main() {
        module('Lights', () -> {
            module('SpotLight', () -> {
                var lights:Array<SpotLight>;

                beforeEach(() -> {
                    var parameters = new SpotLightParameters();
                    parameters.color = 0xaaaaaa;
                    parameters.intensity = 0.5;
                    parameters.distance = 100;
                    parameters.angle = 0.8;
                    parameters.penumbra = 8;
                    parameters.decay = 2;

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
                test('Extending', function(assert) {
                    var object = new SpotLight();
                    assert.strictEqual(
                        Std.is(object, Light), true,
                        'SpotLight extends from Light'
                    );
                });

                // INSTANCING
                test('Instancing', function(assert) {
                    var object = new SpotLight();
                    assert.ok(object, 'Can instantiate a SpotLight.');
                });

                // PROPERTIES
                test('type', function(assert) {
                    var object = new SpotLight();
                    assert.ok(
                        object.type == 'SpotLight',
                        'SpotLight.type should be SpotLight'
                    );
                });

                todo('position', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                todo('target', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                todo('distance', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                todo('angle', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                todo('penumbra', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                todo('decay', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                todo('map', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                todo('shadow', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                test('power', function(assert) {
                    var a = new SpotLight(0xaaaaaa);

                    a.intensity = 100;
                    assert.numEqual(a.power, 100 * Math.PI, 'Correct power for an intensity of 100');

                    a.intensity = 40;
                    assert.numEqual(a.power, 40 * Math.PI, 'Correct power for an intensity of 40');

                    a.power = 100;
                    assert.numEqual(a.intensity, 100 / Math.PI, 'Correct intensity for a power of 100');
                });

                // PUBLIC
                test('isSpotLight', function(assert) {
                    var object = new SpotLight();
                    assert.ok(
                        object.isSpotLight,
                        'SpotLight.isSpotLight should be true'
                    );
                });

                test('dispose', function(assert) {
                    assert.expect(0);

                    var object = new SpotLight();
                    object.dispose();

                    // ensure calls dispose() on shadow
                });

                todo('copy', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // OTHERS
                test('Standard light tests', function(assert) {
                    runStdLightTests(assert, lights);
                });
            });
        });
    }
}

SpotLightTest.main();