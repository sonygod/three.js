import js.lib.QUnit;

import three.helpers.PlaneHelper;
import three.objects.Line;

class PlaneHelperTests {
  public static function main() {
    QUnit.module("Helpers", () => {
      QUnit.module("PlaneHelper", () => {
        // INHERITANCE
        QUnit.test("Extending", (assert) => {
          var object = new PlaneHelper();
          assert.isTrue(object instanceof Line, "PlaneHelper extends from Line");
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) => {
          var object = new PlaneHelper();
          assert.notNull(object, "Can instantiate a PlaneHelper.");
        });

        // PROPERTIES
        QUnit.test("type", (assert) => {
          var object = new PlaneHelper();
          assert.equal(object.type, "PlaneHelper", "PlaneHelper.type should be PlaneHelper");
        });

        QUnit.todo("plane", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("size", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.todo("updateMatrixWorld", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.test("dispose", (assert) => {
          assert.expect(0);
          var object = new PlaneHelper();
          object.dispose();
        });
      });
    });
  }
}