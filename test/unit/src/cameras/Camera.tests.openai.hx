package three.js.test.unit.src.cameras;

import three.js.cameras.Camera;
import three.js.math.Vector3;
import three.js.core.Object3D;

class CameraTests {
    public function new() {}

    public static function testCameras() {
        QUnit.module("Cameras", () => {
            QUnit.module("Camera", () => {
                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var object = new Camera();
                    assert.isTrue(object instanceof Object3D, 'Camera extends from Object3D');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object = new Camera();
                    assert.ok(object, 'Can instantiate a Camera.');
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object = new Camera();
                    assert.equals(object.type, 'Camera', 'Camera.type should be Camera');
                });

                QUnit.todo("matrixWorldInverse", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("projectionMatrix", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("projectionMatrixInverse", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test("isCamera", (assert) => {
                    var object = new Camera();
                    assert.ok(object.isCamera, 'Camera.isCamera should be true');
                });

                QUnit.todo("copy", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("getWorldDirection", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("updateMatrixWorld", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("updateWorldMatrix", (assert) => {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test("clone", (assert) => {
                    var cam = new Camera();

                    // fill the matrices with any nonsense values just to see if they get copied
                    cam.matrixWorldInverse.set(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
                    cam.projectionMatrix.set(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);

                    var clonedCam = cam.clone();

                    // TODO: do not rely equality on object methods
                    // TODO: What's append if matrix.equal is wrongly implemented
                    // TODO: this MUST be check by assert
                    assert.ok(cam.matrixWorldInverse.equals(clonedCam.matrixWorldInverse), 'matrixWorldInverse is equal');
                    assert.ok(cam.projectionMatrix.equals(clonedCam.projectionMatrix), 'projectionMatrix is equal');
                });

                // OTHERS
                // TODO: this should not be here, Object3D related
                QUnit.test("lookAt", (assert) => {
                    var cam = new Camera();
                    cam.lookAt(new Vector3(0, 1, -1));

                    assert.numEquals(cam.rotation.x * (180 / Math.PI), 45, 'x is equal');
                });
            });
        });
    }
}