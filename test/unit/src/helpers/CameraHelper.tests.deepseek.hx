package;

import three.js.test.unit.src.helpers.CameraHelper;
import three.js.test.unit.src.objects.LineSegments;
import three.js.test.unit.src.cameras.PerspectiveCamera;

class CameraHelperTest {

    static function main() {

        QUnit.module('Helpers', () -> {

            QUnit.module('CameraHelper', () -> {

                // INHERITANCE
                QUnit.test('Extending', (assert) -> {

                    var camera = new PerspectiveCamera();
                    var object = new CameraHelper(camera);
                    assert.strictEqual(
                        Std.is(object, LineSegments), true,
                        'CameraHelper extends from LineSegments'
                    );

                });

                // INSTANCING
                QUnit.test('Instancing', (assert) -> {

                    var camera = new PerspectiveCamera();
                    var object = new CameraHelper(camera);
                    assert.ok(object, 'Can instantiate a CameraHelper.');

                });

                // PROPERTIES
                QUnit.test('type', (assert) -> {

                    var camera = new PerspectiveCamera();
                    var object = new CameraHelper(camera);
                    assert.ok(
                        object.type == 'CameraHelper',
                        'CameraHelper.type should be CameraHelper'
                    );

                });

                QUnit.todo('camera', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('matrix', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('matrixAutoUpdate', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('pointMap', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.todo('setColors', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo('update', (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.test('dispose', (assert) -> {

                    assert.expect(0);

                    var camera = new PerspectiveCamera();
                    var object = new CameraHelper(camera);
                    object.dispose();

                });

            });

        });

    }

}