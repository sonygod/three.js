package three.test.unit.src.geometries;

import three.geometries.LatheGeometry;
import three.core.BufferGeometry;
import three.utils.QUnitUtils;

class LatheGeometryTests {
  public function new() {}

  public static function main() {
    QUnit.module("Geometries", function() {
      QUnit.module("LatheGeometry", function(hooks) {
        var geometries:Array<LatheGeometry> = null;

        hooks.beforeEach(function() {
          var parameters = {
            points: new Array(),
            segments: 0,
            phiStart: 0,
            phiLength: 0
          };

          geometries = [new LatheGeometry(parameters.points)];
        });

        // INHERITANCE
        QUnit.test("Extending", function(assert) {
          var object = new LatheGeometry();
          assert.ok(object instanceof BufferGeometry, "LatheGeometry extends from BufferGeometry");
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
          var object = new LatheGeometry();
          assert.ok(object != null, "Can instantiate a LatheGeometry.");
        });

        // PROPERTIES
        QUnit.test("type", function(assert) {
          var object = new LatheGeometry();
          assert.ok(object.type == "LatheGeometry", "LatheGeometry.type should be LatheGeometry");
        });

        QUnit.todo("parameters", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        // STATIC
        QUnit.todo("fromJSON", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        // OTHERS
        QUnit.test("Standard geometry tests", function(assert) {
          QUnitUtils.runStdGeometryTests(assert, geometries);
        });
      });
    });
  }
}