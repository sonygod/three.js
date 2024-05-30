package three.js.test.unit.src.lights;

import three.js.src.lights.PointLight;
import three.js.src.lights.Light;
import three.js.utils.qunit_utils.runStdLightTests;

class PointLightTests {

    static function main() {

        QUnit.module('Lights', () -> {

            QUnit.module('PointLight', (hooks) -> {

                var lights:Array<PointLight>;
                hooks.beforeEach(() -> {

                    var parameters = {
                        color: 0xaaaaaa,
                        intensity: 0.5,
                        distance: 100,
                        decay: 2
                    };

                    lights = [
                        new PointLight(),
                        new PointLight(parameters.color),
                        new PointLight(parameters.color, parameters.intensity),
                        new PointLight(parameters.color, parameters.intensity, parameters.distance),
                        new PointLight(parameters.color, parameters.intensity, parameters.distance, parameters.decay)
                    ];

                });

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new PointLight();
                    assert.strictEqual(
                        Std.instance(object, Light), true,
                        'PointLight extends from Light'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new PointLight();
                    assert.ok(object, 'Can instantiate a PointLight.');

                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {

                    var object = new PointLight();
                    assert.ok(
                        object.type == 'PointLight',
                        'PointLight.type should be PointLight'
                    );

                });

                QUnit.todo('distance', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('decay', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('shadow', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.test('power', (assert) -> {

                    var a = new PointLight(0xaaaaaa);

                    a.intensity = 100;
                    assert.numEqual(a.power, 100 * Math.PI * 4, 'Correct power for an intensity of 100');

                    a.intensity = 40;
                    assert.numEqual(a.power, 40 * Math.PI * 4, 'Correct power for an intensity of 40');

                    a.power = 100;
                    assert.numEqual(a.intensity, 100 / (4 * Math.PI), 'Correct intensity for a power of 100');

                });

                // PUBLIC
                QUnit.test('isPointLight', (assert) -> {

                    var object = new PointLight();
                    assert.ok(
                        object.isPointLight,
                        'PointLight.isPointLight should be true'
                    );

                });

                QUnit.test('dispose', (assert) -> {

                    assert.expect(0);

                    var object = new PointLight();
                    object.dispose();

                    // ensure calls dispose() on shadow

                });

                QUnit.todo('copy', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // OTHERS
                QUnit.test('Standard light tests', (assert) -> {

                    runStdLightTests(assert, lights);

                });

            });

        });

    }

}