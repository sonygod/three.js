package;

import js.Lib;
import three.js.test.unit.src.cameras.ArrayCamera;
import three.js.test.unit.src.cameras.PerspectiveCamera;

class ArrayCameraTests {

    static function main() {
        QUnit.module('Cameras', () -> {
            QUnit.module('ArrayCamera', () -> {
                // INHERITANCE
                QUnit.test('Extending', (assert) -> {
                    var object = new ArrayCamera();
                    assert.strictEqual(
                        Std.instanceof(object, PerspectiveCamera), true,
                        'ArrayCamera extends from PerspectiveCamera'
                    );
                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {
                    var object = new ArrayCamera();
                    assert.ok(object, 'Can instantiate an ArrayCamera.');
                });

                // PROPERTIES
                QUnit.todo('cameras', (assert) -> {
                    // array
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isArrayCamera', (assert) -> {
                    var object = new ArrayCamera();
                    assert.ok(
                        object.isArrayCamera,
                        'ArrayCamera.isArrayCamera should be true'
                    );
                });
            });
        });
    }
}