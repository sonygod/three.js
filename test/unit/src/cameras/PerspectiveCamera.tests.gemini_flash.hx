import qunit.QUnit;
import three.cameras.PerspectiveCamera;
import three.cameras.Camera;
import three.math.Matrix4;

class MatrixEquals4 {
  public static function equals(a:Matrix4, b:Matrix4, tolerance:Float = 0.0001):Bool {
    if (a.elements.length != b.elements.length) {
      return false;
    }
    for (i in 0...a.elements.length) {
      var delta = a.elements[i] - b.elements[i];
      if (delta > tolerance) {
        return false;
      }
    }
    return true;
  }
}

class CamerasTest extends qunit.QUnit {
  static function main() {
    new CamerasTest().run();
  }

  override function run() {
    QUnit.module('Cameras', function() {
      QUnit.module('PerspectiveCamera', function() {
        // INHERITANCE
        QUnit.test('Extending', function(assert) {
          var object = new PerspectiveCamera();
          assert.strictEqual(object instanceof Camera, true, 'PerspectiveCamera extends from Camera');
        });

        // INSTANCING
        QUnit.test('Instancing', function(assert) {
          var object = new PerspectiveCamera();
          assert.ok(object, 'Can instantiate a PerspectiveCamera.');
        });

        // PROPERTIES
        QUnit.test('type', function(assert) {
          var object = new PerspectiveCamera();
          assert.ok(object.type == 'PerspectiveCamera', 'PerspectiveCamera.type should be PerspectiveCamera');
        });

        QUnit.todo('fov', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('zoom', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('near', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('far', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('focus', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('aspect', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('view', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('filmGauge', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('filmOffset', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        QUnit.test('isPerspectiveCamera', function(assert) {
          var object = new PerspectiveCamera();
          assert.ok(object.isPerspectiveCamera, 'PerspectiveCamera.isPerspectiveCamera should be true');
        });

        QUnit.todo('copy', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('setFocalLength', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('getFocalLength', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('getEffectiveFOV', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('getFilmWidth', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('getFilmHeight', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('setViewOffset', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('clearViewOffset', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('updateProjectionMatrix', function(assert) {
          var cam = new PerspectiveCamera(75, 16 / 9, 0.1, 300.0);

          // updateProjectionMatrix is called in constructor
          var m = cam.projectionMatrix;

          // perspective projection is given my the 4x4 Matrix
          // 2n/r-l		0			l+r/r-l				 0
          //   0		2n/t-b	t+b/t-b				 0
          //   0			0		-(f+n/f-n)	-(2fn/f-n)
          //   0			0				-1					 0

          // this matrix was calculated by hand via glMatrix.perspective(75, 16 / 9, 0.1, 300.0, pMatrix)
          // to get a reference matrix from plain WebGL
          var reference = new Matrix4().set(
            0.7330642938613892, 0, 0, 0,
            0, 1.3032253980636597, 0, 0,
            0, 0, -1.000666856765747, -0.2000666856765747,
            0, 0, -1, 0
          );

          // assert.ok( reference.equals(m) );
          assert.ok(MatrixEquals4.equals(reference, m, 0.000001));
        });

        QUnit.todo('toJSON', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        // OTHERS
        // TODO: clone is a camera methods that relied to copy method
        QUnit.test('clone', function(assert) {
          var near = 1;
          var far = 3;
          var aspect = 16 / 9;
          var fov = 90;

          var cam = new PerspectiveCamera(fov, aspect, near, far);

          var clonedCam = cam.clone();

          assert.ok(cam.fov == clonedCam.fov, 'fov is equal');
          assert.ok(cam.aspect == clonedCam.aspect, 'aspect is equal');
          assert.ok(cam.near == clonedCam.near, 'near is equal');
          assert.ok(cam.far == clonedCam.far, 'far is equal');
          assert.ok(cam.zoom == clonedCam.zoom, 'zoom is equal');
          assert.ok(cam.projectionMatrix.equals(clonedCam.projectionMatrix), 'projectionMatrix is equal');
        });
      });
    });
  }
}

class CamerasTest extends qunit.QUnit {
  static function main() {
    new CamerasTest().run();
  }

  override function run() {
    QUnit.module('Cameras', function() {
      QUnit.module('PerspectiveCamera', function() {
        // INHERITANCE
        QUnit.test('Extending', function(assert) {
          var object = new PerspectiveCamera();
          assert.strictEqual(object instanceof Camera, true, 'PerspectiveCamera extends from Camera');
        });

        // INSTANCING
        QUnit.test('Instancing', function(assert) {
          var object = new PerspectiveCamera();
          assert.ok(object, 'Can instantiate a PerspectiveCamera.');
        });

        // PROPERTIES
        QUnit.test('type', function(assert) {
          var object = new PerspectiveCamera();
          assert.ok(object.type == 'PerspectiveCamera', 'PerspectiveCamera.type should be PerspectiveCamera');
        });

        QUnit.todo('fov', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('zoom', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('near', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('far', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('focus', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('aspect', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('view', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('filmGauge', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('filmOffset', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        QUnit.test('isPerspectiveCamera', function(assert) {
          var object = new PerspectiveCamera();
          assert.ok(object.isPerspectiveCamera, 'PerspectiveCamera.isPerspectiveCamera should be true');
        });

        QUnit.todo('copy', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('setFocalLength', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('getFocalLength', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('getEffectiveFOV', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('getFilmWidth', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('getFilmHeight', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('setViewOffset', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('clearViewOffset', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.test('updateProjectionMatrix', function(assert) {
          var cam = new PerspectiveCamera(75, 16 / 9, 0.1, 300.0);

          // updateProjectionMatrix is called in constructor
          var m = cam.projectionMatrix;

          // perspective projection is given my the 4x4 Matrix
          // 2n/r-l		0			l+r/r-l				 0
          //   0		2n/t-b	t+b/t-b				 0
          //   0			0		-(f+n/f-n)	-(2fn/f-n)
          //   0			0				-1					 0

          // this matrix was calculated by hand via glMatrix.perspective(75, 16 / 9, 0.1, 300.0, pMatrix)
          // to get a reference matrix from plain WebGL
          var reference = new Matrix4().set(
            0.7330642938613892, 0, 0, 0,
            0, 1.3032253980636597, 0, 0,
            0, 0, -1.000666856765747, -0.2000666856765747,
            0, 0, -1, 0
          );

          // assert.ok( reference.equals(m) );
          assert.ok(MatrixEquals4.equals(reference, m, 0.000001));
        });

        QUnit.todo('toJSON', function(assert) {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        // OTHERS
        // TODO: clone is a camera methods that relied to copy method
        QUnit.test('clone', function(assert) {
          var near = 1;
          var far = 3;
          var aspect = 16 / 9;
          var fov = 90;

          var cam = new PerspectiveCamera(fov, aspect, near, far);

          var clonedCam = cam.clone();

          assert.ok(cam.fov == clonedCam.fov, 'fov is equal');
          assert.ok(cam.aspect == clonedCam.aspect, 'aspect is equal');
          assert.ok(cam.near == clonedCam.near, 'near is equal');
          assert.ok(cam.far == clonedCam.far, 'far is equal');
          assert.ok(cam.zoom == clonedCam.zoom, 'zoom is equal');
          assert.ok(cam.projectionMatrix.equals(clonedCam.projectionMatrix), 'projectionMatrix is equal');
        });
      });
    });
  }
}