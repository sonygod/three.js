package three.test.unit.src.geometries;

import three.geometries.ConeGeometry;
import three.geometries.CylinderGeometry;
import three.utils.QUnitUtils;

class ConeGeometryTests {
  static function main() {
    QUnit.module("Geometries", () -> {
      QUnit.module("ConeGeometry", (hooks) -> {
        var geometries:Array<Geometry>;

        hooks.beforeEach(() -> {
          geometries = [new ConeGeometry()];
        });

        // INHERITANCE
        QUnit.test("Extending", (assert) -> {
          var object:ConeGeometry = new ConeGeometry();
          assert.isTrue(object instanceof CylinderGeometry, "ConeGeometry extends from CylinderGeometry");
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) -> {
          var object:ConeGeometry = new ConeGeometry();
          assert.ok(object != null, "Can instantiate a ConeGeometry.");
        });

        // PROPERTIES
        QUnit.test("type", (assert) -> {
          var object:ConeGeometry = new ConeGeometry();
          assert.ok(object.type == "ConeGeometry", "ConeGeometry.type should be ConeGeometry");
        });

        QUnit.todo("parameters", (assert) -> {
          assert.ok(false, "everything's gonna be alright");
        });

        // STATIC
        QUnit.todo("fromJSON", (assert) -> {
          assert.ok(false, "everything's gonna be alright");
        });

        // OTHERS
        QUnit.test("Standard geometry tests", (assert) -> {
          QUnitUtils.runStdGeometryTests(assert, geometries);
        });
      });
    });
  }
}