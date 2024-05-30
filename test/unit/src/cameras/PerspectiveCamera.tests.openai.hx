package three.js.test.unit.src.cameras;

import three.js.cameras.PerspectiveCamera;
import three.js.math.Matrix4;
import three.js.cameras.Camera;

class PerspectiveCameraTests {
  public static function main() {
    QUnit.module("Cameras", () => {
      QUnit.module("PerspectiveCamera", () => {
        // INHERITANCE
        QUnit.test("Extending", (assert) => {
          var object:PerspectiveCamera = new PerspectiveCamera();
          assert.isTrue(object instanceof Camera, "PerspectiveCamera extends from Camera");
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) => {
          var object:PerspectiveCamera = new PerspectiveCamera();
          assert.ok(object != null, "Can instantiate a PerspectiveCamera.");
        });

        // PROPERTIES
        QUnit.test("type", (assert) => {
          var object:PerspectiveCamera = new PerspectiveCamera();
          assert.equal(object.type, "PerspectiveCamera", "PerspectiveCamera.type should be PerspectiveCamera");
        });

        QUnit.todo("fov", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("zoom", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("near", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("far", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("focus", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("aspect", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("view", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("filmGauge", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("filmOffset", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test("isPerspectiveCamera", (assert) => {
          var object:PerspectiveCamera = new PerspectiveCamera();
          assert.ok(object.isPerspectiveCamera, "PerspectiveCamera.isPerspectiveCamera should be true");
        });

        QUnit.todo("copy", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setFocalLength", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getFocalLength", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getEffectiveFOV", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getFilmWidth", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getFilmHeight", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setViewOffset", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("clearViewOffset", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.test("updateProjectionMatrix", (assert) => {
          var cam:PerspectiveCamera = new PerspectiveCamera(75, 16 / 9, 0.1, 300.0);
          var m:Matrix4 = cam.projectionMatrix;

          // perspective projection is given by the 4x4 Matrix
          // 2n/r-l		0			l+r/r-l				 0
          //   0		2n/t-b	t+b/t-b				 0
          //   0			0		-(f+n/f-n)	-(2fn/f-n)
          //   0			0				-1					 0

          // this matrix was calculated by hand via glMatrix.perspective(75, 16 / 9, 0.1, 300.0, pMatrix)
          // to get a reference matrix from plain WebGL
          var reference:Matrix4 = new Matrix4();
          reference.set(
            0.7330642938613892, 0, 0, 0,
            0, 1.3032253980636597, 0, 0,
            0, 0, -1.000666856765747, -0.2000666856765747,
            0, 0, -1, 0
          );

          assert.ok(matrixEquals4(reference, m, 0.000001));
        });

        QUnit.todo("toJSON", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        // OTHERS
        // TODO: clone is a camera methods that relied to copy method
        QUnit.test("clone", (assert) => {
          var near:Float = 1;
          var far:Float = 3;
          var aspect:Float = 16 / 9;
          var fov:Float = 90;

          var cam:PerspectiveCamera = new PerspectiveCamera(fov, aspect, near, far);
          var clonedCam:PerspectiveCamera = cam.clone();

          assert.ok(cam.fov == clonedCam.fov, "fov is equal");
          assert.ok(cam.aspect == clonedCam.aspect, "aspect is equal");
          assert.ok(cam.near == clonedCam.near, "near is equal");
          assert.ok(cam.far == clonedCam.far, "far is equal");
          assert.ok(cam.zoom == clonedCam.zoom, "zoom is equal");
          assert.ok(cam.projectionMatrix.equals(clonedCam.projectionMatrix), "projectionMatrix is equal");
        });
      });
    });
  }

  static function matrixEquals4(a:Matrix4, b:Matrix4, tolerance:Float) {
    tolerance = Math.isNaN(tolerance) ? 0.0001 : tolerance;
    if (a.elements.length != b.elements.length) {
      return false;
    }

    for (i in 0...a.elements.length) {
      var delta:Float = a.elements[i] - b.elements[i];
      if (Math.abs(delta) > tolerance) {
        return false;
      }
    }

    return true;
  }
}