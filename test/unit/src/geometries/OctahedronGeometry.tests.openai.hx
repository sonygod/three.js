package three.js.test.unit.src.geometries;

import three.js.geometries.OctahedronGeometry;
import three.js.geometries.PolyhedronGeometry;
import three.js.utils.QUnitUtils;

class OctahedronGeometryTests {
  public static function main() {
    QUnit.module("Geometries", () => {
      QUnit.module("OctahedronGeometry", () => {
        var geometries:Array<OctahedronGeometry> = null;

        QUnit.beforeEach(() => {
          var parameters = {
            radius: 10,
            detail: null
          };

          geometries = [
            new OctahedronGeometry(),
            new OctahedronGeometry(parameters.radius),
            new OctahedronGeometry(parameters.radius, parameters.detail)
          ];
        });

        // INHERITANCE
        QUnit.test("Extending", (assert) => {
          var object = new OctahedronGeometry();
          assert.ok(object instanceof PolyhedronGeometry, 'OctahedronGeometry extends from PolyhedronGeometry');
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) => {
          var object = new OctahedronGeometry();
          assert.ok(object != null, 'Can instantiate an OctahedronGeometry.');
        });

        // PROPERTIES
        QUnit.test("type", (assert) => {
          var object = new OctahedronGeometry();
          assert.ok(object.type == 'OctahedronGeometry', 'OctahedronGeometry.type should be OctahedronGeometry');
        });

        QUnit.test("parameters", (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        // STATIC
        QUnit.test("fromJSON", (assert) => {
          assert.ok(false, 'everything\'s gonna be alright');
        });

        // OTHERS
        QUnit.test("Standard geometry tests", (assert) => {
          QUnitUtils.runStdGeometryTests(assert, geometries);
        });
      });
    });
  }
}