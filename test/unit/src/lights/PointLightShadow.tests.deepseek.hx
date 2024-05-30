package three.js.test.unit.src.lights;

import three.js.src.lights.PointLightShadow;
import three.js.src.lights.LightShadow;

class PointLightShadowTests {

    public static function main() {

        QUnit.module('Lights', () -> {

            QUnit.module('PointLightShadow', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new PointLightShadow();
                    assert.strictEqual(
                        Std.is(object, LightShadow), true,
                        'PointLightShadow extends from LightShadow'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new PointLightShadow();
                    assert.ok(object, 'Can instantiate a PointLightShadow.');

                });

                // PUBLIC
                QUnit.test('isPointLightShadow', (assert) -> {

                    var object = new PointLightShadow();
                    assert.ok(
                        object.isPointLightShadow,
                        'PointLightShadow.isPointLightShadow should be true'
                    );

                });

                QUnit.todo('updateMatrices', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}