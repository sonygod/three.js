package three.geom.tests;

import three.geom.WireframeGeometry;
import three.core.BufferGeometry;

class WireframeGeometryTests {
  static function main() {
    QUnit.module("Geometries", () => {
      QUnit.module("WireframeGeometry", (hooks) => {
        var geometries:Array<WireframeGeometry> = [];
        hooks-beforeEach(() => {
          geometries = [new WireframeGeometry()];
        });

        // INHERITANCE
        QUnit.test("Extending", (assert) => {
          var object:WireframeGeometry = new WireframeGeometry();
          assert.ok(object instanceof BufferGeometry, "WireframeGeometry extends from BufferGeometry");
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) => {
          var object:WireframeGeometry = new WireframeGeometry();
          assert.ok(object != null, "Can instantiate a WireframeGeometry.");
        });

        // PROPERTIES
        QUnit.test("type", (assert) => {
          var object:WireframeGeometry = new WireframeGeometry();
          assert.ok(object.type == "WireframeGeometry", "WireframeGeometry.type should be WireframeGeometry");
        });

        QUnit.todo("parameters", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        // OTHERS
        QUnit.todo("Standard geometry tests", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });
      });
    });
  }
}