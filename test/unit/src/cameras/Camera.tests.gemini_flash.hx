import qunit.QUnit;
import three.cameras.Camera;
import three.math.Vector3;
import three.core.Object3D;

class CameraTest {
  public static function main():Void {
    QUnit.module("Cameras", function() {
      QUnit.module("Camera", function() {
        // INHERITANCE
        QUnit.test("Extending", function(assert) {
          var object = new Camera();
          assert.strictEqual(object.is(Object3D), true, "Camera extends from Object3D");
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
          var object = new Camera();
          assert.ok(object, "Can instantiate a Camera.");
        });

        // PROPERTIES
        QUnit.test("type", function(assert) {
          var object = new Camera();
          assert.ok(object.type == "Camera", "Camera.type should be Camera");
        });

        QUnit.todo("matrixWorldInverse", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("projectionMatrix", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("projectionMatrixInverse", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test("isCamera", function(assert) {
          var object = new Camera();
          assert.ok(object.isCamera, "Camera.isCamera should be true");
        });

        QUnit.todo("copy", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getWorldDirection", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("updateMatrixWorld", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("updateWorldMatrix", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.test("clone", function(assert) {
          var cam = new Camera();

          // fill the matrices with any nonsense values just to see if they get copied
          cam.matrixWorldInverse.set(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
          cam.projectionMatrix.set(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);

          var clonedCam = cam.clone();

          // TODO: do not rely equality on object methods
          // TODO: What's append if matrix.equal is wrongly implemented
          // TODO: this MUST be check by assert
          assert.ok(cam.matrixWorldInverse.equals(clonedCam.matrixWorldInverse), "matrixWorldInverse is equal");
          assert.ok(cam.projectionMatrix.equals(clonedCam.projectionMatrix), "projectionMatrix is equal");
        });

        // OTHERS
        // TODO: this should not be here, Object3D related
        QUnit.test("lookAt", function(assert) {
          var cam = new Camera();
          cam.lookAt(new Vector3(0, 1, -1));

          assert.numEqual(cam.rotation.x * (180 / Math.PI), 45, "x is equal");
        });
      });
    });
  }
}