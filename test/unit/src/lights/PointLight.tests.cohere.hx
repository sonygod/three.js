import js.QUnit;
import js.PointLight;
import js.Light;
import js.runStdLightTests;

class PointLightTest {
    static function main() {
        var lights = [];
        var parameters = { color: 0xaaaaaa, intensity: 0.5, distance: 100, decay: 2 };

        lights.push(new PointLight());
        lights.push(new PointLight(parameters.color));
        lights.push(new PointLight(parameters.color, parameters.intensity));
        lights.push(new PointLight(parameters.color, parameters.intensity, parameters.distance));
        lights.push(new PointLight(parameters.color, parameters.intensity, parameters.distance, parameters.decay));

        QUnit.module('Lights', function() {
            QUnit.module('PointLight', function(hooks) {
                hooks.beforeEach(function() {
                    // ...
                });

                // INHERITANCE
                QUnit.test('Extending', function(assert) {
                    var object = new PointLight();
                    assert.strictEqual(object instanceof Light, true, 'PointLight extends from Light');
                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {
                    var object = new PointLight();
                    assert.ok(object, 'Can instantiate a PointLight.');
                });

                // PROPERTIES
                QUnit.test('type', function(assert) {
                    var object = new PointLight();
                    assert.ok(object.type == 'PointLight', 'PointLight.type should be PointLight');
                });

                QUnit.test('power', function(assert) {
                    var a = new PointLight(0xaaaaaa);

                    a.intensity = 100;
                    assert.numEqual(a.power, 100 * Math.PI * 4, 'Correct power for an intensity of 100');

                    a.intensity = 40;
                    assert.numEqual(a.power, 40 * Math.PI * 4, 'Correct power for an intensity of 40');

                    a.power = 100;
                    assert.numEqual(a.intensity, 100 / (4 * Math.PI), 'Correct intensity for a power of 100');
                });

                // PUBLIC
                QUnit.test('isPointLight', function(assert) {
                    var object = new PointLight();
                    assert.ok(object.isPointLight, 'PointLight.isPointLight should be true');
                });

                QUnit.test('dispose', function(assert) {
                    assert.expect(0);

                    var object = new PointLight();
                    object.dispose();
                });

                // OTHERS
                QUnit.test('Standard light tests', function(assert) {
                    runStdLightTests(assert, lights);
                });
            });
        });
    }
}

PointLightTest.main();