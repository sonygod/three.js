package three.test.unit.src.geometries;

import three.geometries.PolyhedronGeometry;
import three.core.BufferGeometry;
import three.test.utils.QUnitUtils;

class PolyhedronGeometryTests {
  public function new() {}

  public function test() {
    QUnit.module("Geometries", () => {
      QUnit.module("PolyhedronGeometry", (hooks) => {
        var geometries:Array<PolyhedronGeometry> = null;
        hooks.beforeEach(() => {
          var vertices:Array<Float> = [
            1, 1, 1,
            -1, -1, 1,
            -1, 1, -1,
            1, -1, -1
          ];

          var indices:Array<Int> = [
            2, 1, 0,
            0, 3, 2,
            1, 3, 0,
            2, 3, 1
          ];

          geometries = [new PolyhedronGeometry(vertices, indices)];
        });

        // INHERITANCE
        QUnit.test("Extending", (assert) => {
          var object:PolyhedronGeometry = new PolyhedronGeometry();
          assert.ok(object instanceof BufferGeometry, "PolyhedronGeometry extends from BufferGeometry");
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) => {
          var object:PolyhedronGeometry = new PolyhedronGeometry();
          assert.ok(object != null, "Can instantiate a PolyhedronGeometry.");
        });

        // PROPERTIES
        QUnit.test("type", (assert) => {
          var object:PolyhedronGeometry = new PolyhedronGeometry();
          assert.ok(object.type == "PolyhedronGeometry", "PolyhedronGeometry.type should be PolyhedronGeometry");
        });

        QUnit.todo("parameters", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        // STATIC
        QUnit.todo("fromJSON", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        // OTHERS
        QUnit.test("Standard geometry tests", (assert) => {
          QUnitUtils.runStdGeometryTests(assert, geometries);
        });
      });
    });
  }
}