import qunit.QUnit;
import three.cameras.StereoCamera;

class CamerasTest extends QUnit.Test {
  public function new() {
    super();
    this.addModule("Cameras", this.cameras);
  }

  public function cameras():Void {
    this.addModule("StereoCamera", this.stereoCamera);
  }

  public function stereoCamera():Void {
    // INSTANCING
    this.test("Instancing", function(assert:QUnit.Assert) {
      var object = new StereoCamera();
      assert.ok(object, "Can instantiate a StereoCamera.");
    });

    // PROPERTIES
    this.test("type", function(assert:QUnit.Assert) {
      var object = new StereoCamera();
      assert.ok(
        object.type == "StereoCamera",
        "StereoCamera.type should be StereoCamera"
      );
    });

    this.todo("aspect", function(assert:QUnit.Assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    this.todo("eyeSep", function(assert:QUnit.Assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    this.todo("cameraL", function(assert:QUnit.Assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    this.todo("cameraR", function(assert:QUnit.Assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    // PUBLIC
    this.todo("update", function(assert:QUnit.Assert) {
      assert.ok(false, "everything's gonna be alright");
    });
  }
}

class Main {
  static function main() {
    new CamerasTest();
    QUnit.run();
  }
}