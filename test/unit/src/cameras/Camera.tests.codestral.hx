import qunit.QUnit;
import three.cameras.Camera;
import three.math.Vector3;
import three.core.Object3D;

class CameraTests {

    public static function main() {

        QUnit.module("Cameras", () -> {

            QUnit.module("Camera", () -> {

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {

                    var object: Camera = new Camera();
                    assert.strictEqual(Std.is(object, Object3D), true, 'Camera extends from Object3D');

                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {

                    var object: Camera = new Camera();
                    assert.ok(object, 'Can instantiate a Camera.');

                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {

                    var object: Camera = new Camera();
                    assert.ok(object.type == "Camera", 'Camera.type should be Camera');

                });

                // PUBLIC
                QUnit.test("isCamera", (assert) -> {

                    var object: Camera = new Camera();
                    assert.ok(object.isCamera, 'Camera.isCamera should be true');

                });

                QUnit.test("clone", (assert) -> {

                    var cam: Camera = new Camera();

                    // fill the matrices with any nonsense values just to see if they get copied
                    cam.matrixWorldInverse.set(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
                    cam.projectionMatrix.set(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);

                    var clonedCam: Camera = cam.clone();

                    assert.ok(cam.matrixWorldInverse.equals(clonedCam.matrixWorldInverse), 'matrixWorldInverse is equal');
                    assert.ok(cam.projectionMatrix.equals(clonedCam.projectionMatrix), 'projectionMatrix is equal');

                });

                // OTHERS
                QUnit.test("lookAt", (assert) -> {

                    var cam: Camera = new Camera();
                    cam.lookAt(new Vector3(0, 1, -1));

                    assert.numEqual(cam.rotation.x * (180 / Math.PI), 45, 'x is equal');

                });

            });

        });

    }
}