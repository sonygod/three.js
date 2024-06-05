import qunit.QUnit;
import three.cameras.Camera;
import three.cameras.OrthographicCamera;

class OrthographicCameraTest extends qunit.TestCase {
  public function new() {
    super();
  }

  @qunit.test
  public function extending(assert:qunit.Assert) {
    var object = new OrthographicCamera();
    assert.isTrue(cast(Camera, object) != null, "OrthographicCamera extends from Camera");
  }

  @qunit.test
  public function instancing(assert:qunit.Assert) {
    var object = new OrthographicCamera();
    assert.ok(object, "Can instantiate an OrthographicCamera.");
  }

  @qunit.test
  public function type(assert:qunit.Assert) {
    var object = new OrthographicCamera();
    assert.strictEqual(object.type, "OrthographicCamera", "OrthographicCamera.type should be OrthographicCamera");
  }

  @qunit.todo("zoom", function(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  });

  @qunit.todo("view", function(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  });

  @qunit.todo("left", function(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  });

  @qunit.todo("right", function(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  });

  @qunit.todo("top", function(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  });

  @qunit.todo("bottom", function(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  });

  @qunit.todo("near", function(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  });

  @qunit.todo("far", function(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  });

  @qunit.test
  public function isOrthographicCamera(assert:qunit.Assert) {
    var object = new OrthographicCamera();
    assert.isTrue(object.isOrthographicCamera, "OrthographicCamera.isOrthographicCamera should be true");
  }

  @qunit.todo("copy", function(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  });

  @qunit.todo("setViewOffset", function(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  });

  @qunit.todo("clearViewOffset", function(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  });

  @qunit.test
  public function updateProjectionMatrix(assert:qunit.Assert) {
    var left = -1;
    var right = 1;
    var top = 1;
    var bottom = -1;
    var near = 1;
    var far = 3;
    var cam = new OrthographicCamera(left, right, top, bottom, near, far);

    // updateProjectionMatrix is called in constructor
    var pMatrix = cam.projectionMatrix.elements;

    // orthographic projection is given my the 4x4 Matrix
    // 2/r-l		0			 0		-(l+r/r-l)
    //   0		2/t-b		 0		-(t+b/t-b)
    //   0			0		-2/f-n	-(f+n/f-n)
    //   0			0			 0				1

    assert.ok(pMatrix[0] == 2 / (right - left), "m[0,0] === 2 / (r - l)");
    assert.ok(pMatrix[5] == 2 / (top - bottom), "m[1,1] === 2 / (t - b)");
    assert.ok(pMatrix[10] == -2 / (far - near), "m[2,2] === -2 / (f - n)");
    assert.ok(pMatrix[12] == -((right + left) / (right - left)), "m[3,0] === -(r+l/r-l)");
    assert.ok(pMatrix[13] == -((top + bottom) / (top - bottom)), "m[3,1] === -(t+b/b-t)");
    assert.ok(pMatrix[14] == -((far + near) / (far - near)), "m[3,2] === -(f+n/f-n)");
  }

  @qunit.todo("toJSON", function(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  });

  @qunit.test
  public function clone(assert:qunit.Assert) {
    var left = -1.5;
    var right = 1.5;
    var top = 1;
    var bottom = -1;
    var near = 0.1;
    var far = 42;
    var cam = new OrthographicCamera(left, right, top, bottom, near, far);

    var clonedCam = cam.clone();

    assert.ok(cam.left == clonedCam.left, "left is equal");
    assert.ok(cam.right == clonedCam.right, "right is equal");
    assert.ok(cam.top == clonedCam.top, "top is equal");
    assert.ok(cam.bottom == clonedCam.bottom, "bottom is equal");
    assert.ok(cam.near == clonedCam.near, "near is equal");
    assert.ok(cam.far == clonedCam.far, "far is equal");
    assert.ok(cam.zoom == clonedCam.zoom, "zoom is equal");
  }
}

class CamerasTest extends qunit.Module {
  public function new() {
    super("Cameras");
  }

  override function setup(assert:qunit.Assert) {
  }

  override function teardown(assert:qunit.Assert) {
  }

  public function getTests():Array<qunit.TestCase> {
    return [new OrthographicCameraTest()];
  }
}

class Main {
  static function main() {
    QUnit.run(new CamerasTest());
  }
}