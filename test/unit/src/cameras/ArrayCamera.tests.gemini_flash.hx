import qunit.QUnit;
import three.cameras.PerspectiveCamera;
import three.cameras.ArrayCamera;

class CamerasTest extends QUnit.Module {
  override function test() {
    super.test();

    this.module("ArrayCamera", () => {
      // INHERITANCE
      this.test("Extending", (assert: qunit.Assert) => {
        var object = new ArrayCamera();
        assert.strictEqual(
          Std.is(object, PerspectiveCamera),
          true,
          "ArrayCamera extends from PerspectiveCamera"
        );
      });

      // INSTANCING
      this.test("Instancing", (assert: qunit.Assert) => {
        var object = new ArrayCamera();
        assert.ok(object, "Can instantiate an ArrayCamera.");
      });

      // PROPERTIES
      this.todo("cameras", (assert: qunit.Assert) => {
        // array
        assert.ok(false, "everything's gonna be alright");
      });

      // PUBLIC
      this.test("isArrayCamera", (assert: qunit.Assert) => {
        var object = new ArrayCamera();
        assert.ok(
          object.isArrayCamera,
          "ArrayCamera.isArrayCamera should be true"
        );
      });
    });
  }
}

var test = new CamerasTest();