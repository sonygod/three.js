package three.tests.unit.cameras;

import three.cameras.Camera;
import three.math.Vector3;
import three.core.Object3D;

class CameraTests {

  public function new() {}

  public function testAll() {
    utest.TestSuite.run([
      new CameraTest(),
    ]);
  }
}

class CameraTest extends utest.Test {

  public function new() {
    super();
  }

  public function testExtending() {
    var object = new Camera();
    assertTrue(object instanceof Object3D, 'Camera extends from Object3D');
  }

  public function testInstancing() {
    var object = new Camera();
    assertTrue(object != null, 'Can instantiate a Camera.');
  }

  public function testType() {
    var object = new Camera();
    assertEquals(object.type, 'Camera', 'Camera.type should be Camera');
  }

  public function todoMatrixWorldInverse() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoProjectionMatrix() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoProjectionMatrixInverse() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function testIsCamera() {
    var object = new Camera();
    assertTrue(object.isCamera, 'Camera.isCamera should be true');
  }

  public function todoCopy() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoGetWorldDirection() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoUpdateMatrixWorld() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoUpdateWorldMatrix() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function testClone() {
    var cam = new Camera();

    // fill the matrices with any nonsense values just to see if they get copied
    cam.matrixWorldInverse.set(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
    cam.projectionMatrix.set(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);

    var clonedCam = cam.clone();

    // TODO: do not rely equality on object methods
    // TODO: What's append if matrix.equal is wrongly implemented
    // TODO: this MUST be check by assert
    assertTrue(cam.matrixWorldInverse.equals(clonedCam.matrixWorldInverse), 'matrixWorldInverse is equal');
    assertTrue(cam.projectionMatrix.equals(clonedCam.projectionMatrix), 'projectionMatrix is equal');
  }

  public function testLookAt() {
    var cam = new Camera();
    cam.lookAt(new Vector3(0, 1, -1));

    assertEquals(cam.rotation.x * (180 / Math.PI), 45, 'x is equal');
  }
}