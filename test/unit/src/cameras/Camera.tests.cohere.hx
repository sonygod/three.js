import js.QUnit;
import js.Three.cameras.Camera;
import js.Three.core.Object3D;
import js.Three.math.Vector3;

class CameraTest {
    static function main() {
        QUnit.module('Cameras', {
            beforeEach: function() {
                // ...
            },
            afterEach: function() {
                // ...
            }
        });

        QUnit.module('Camera', function() {
            QUnit.test('Extending', function(assert) {
                var object = new Camera();
                assert.strictEqual(object instanceof Object3D, true, 'Camera extends from Object3D');
            });

            QUnit.test('Instancing', function(assert) {
                var object = new Camera();
                assert.ok(object, 'Can instantiate a Camera');
            });

            QUnit.test('type', function(assert) {
                var object = new Camera();
                assert.ok(object.type == 'Camera', 'Camera.type should be Camera');
            });

            QUnit.test('isCamera', function(assert) {
                var object = new Camera();
                assert.ok(object.isCamera, 'Camera.isCamera should be true');
            });

            QUnit.test('clone', function(assert) {
                var cam = new Camera();
                cam.matrixWorldInverse.set(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
                cam.projectionMatrix.set(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);

                var clonedCam = cam.clone();

                assert.ok(cam.matrixWorldInverse.equals(clonedCam.matrixWorldInverse), 'matrixWorldInverse is equal');
                assert.ok(cam.projectionMatrix.equals(clonedCam.projectionMatrix), 'projectionMatrix is equal');
            });

            QUnit.test('lookAt', function(assert) {
                var cam = new Camera();
                cam.lookAt(new Vector3(0, 1, -1));

                assert.numEqual(cam.rotation.x * (180 / Math.PI), 45, 'x is equal');
            });
        });
    }
}

CameraTest.main();