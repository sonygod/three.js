package three.js.test.unit.src.cameras;

import three.js.src.cameras.CubeCamera;
import three.js.src.core.Object3D;
import js.Lib.QUnit;

class CubeCameraTests {

    public static function main() {

        QUnit.module('Cameras', () -> {

            QUnit.module('CubeCamera', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var object = new CubeCamera();
                    assert.strictEqual(
                        Std.is(object, Object3D), true,
                        'CubeCamera extends from Object3D'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var object = new CubeCamera();
                    assert.ok(object, 'Can instantiate a CubeCamera.');

                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {

                    var object = new CubeCamera();
                    assert.ok(
                        object.type == 'CubeCamera',
                        'CubeCamera.type should be CubeCamera'
                    );

                });

                QUnit.todo('renderTarget', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.todo('update', (assert) -> {

                    // update( renderer, scene )
                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}