import qunit.QUnit;
import three.cameras.CubeCamera;
import three.core.Object3D;

class CamerasTest extends QUnit {
  static function main() {
    new CamerasTest().run();
  }

  public function new() {
    super();

    module("Cameras", () => {
      module("CubeCamera", () => {
        // INHERITANCE
        test("Extending", (assert) => {
          var object = new CubeCamera();
          assert.isTrue(object.is(Object3D), "CubeCamera extends from Object3D");
        });

        // INSTANCING
        test("Instancing", (assert) => {
          var object = new CubeCamera();
          assert.ok(object, "Can instantiate a CubeCamera.");
        });

        // PROPERTIES
        test("type", (assert) => {
          var object = new CubeCamera();
          assert.equal(object.type, "CubeCamera", "CubeCamera.type should be CubeCamera");
        });

        todo("renderTarget", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        todo("update", (assert) => {
          // update( renderer, scene )
          assert.ok(false, "everything's gonna be alright");
        });
      });
    });
  }
}

class todo extends QUnit.Test {
  public function new(name:String, callback:TestCallback) {
    super(name, callback);
  }

  override public function run(assert:Assert) {
    trace("TODO: " + name);
  }
}

CamerasTest.main();