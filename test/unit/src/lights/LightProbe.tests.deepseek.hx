package three.js.test.unit.src.lights;

import three.js.src.lights.LightProbe;
import three.js.src.lights.Light;
import js.Lib;

class LightProbeTests {

    static function main() {
        QUnit.module('Lights', () -> {
            QUnit.module('LightProbe', () -> {
                // INHERITANCE
                QUnit.test('Extending', (assert) -> {
                    var object = new LightProbe();
                    assert.strictEqual(
                        Std.instanceof(object, Light), true,
                        'LightProbe extends from Light'
                    );
                });

                // INSTANCING
                QUnit.todo('Instancing', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PROPERTIES
                QUnit.todo('sh', (assert) -> {
                    // SphericalHarmonics3 if not supplied
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isLightProbe', (assert) -> {
                    var object = new LightProbe();
                    assert.ok(
                        object.isLightProbe,
                        'LightProbe.isLightProbe should be true'
                    );
                });

                QUnit.todo('copy', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('fromJSON', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('toJSON', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}