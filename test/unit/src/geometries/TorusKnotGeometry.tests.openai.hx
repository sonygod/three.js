package three.geom;

import three.geom.TorusKnotGeometry;
import three.core.BufferGeometry;
import qunit.QUnit;
import qunit.utils.runStdGeometryTests;

class TorusKnotGeometryTest {

  static function main() {
    QUnit.module("Geometries", () => {
      QUnit.module("TorusKnotGeometry", () => {
        var geometries:Array<TorusKnotGeometry> = null;
        QUnit.beforeEach(() => {
          var parameters = {
            radius: 10,
            tube: 20,
            tubularSegments: 30,
            radialSegments: 10,
            p: 3,
            q: 2
          };
          geometries = [
            new TorusKnotGeometry(),
            new TorusKnotGeometry(parameters.radius),
            new TorusKnotGeometry(parameters.radius, parameters.tube),
            new TorusKnotGeometry(parameters.radius, parameters.tube, parameters.tubularSegments),
            new TorusKnotGeometry(parameters.radius, parameters.tube, parameters.tubularSegments, parameters.radialSegments),
            new TorusKnotGeometry(parameters.radius, parameters.tube, parameters.tubularSegments, parameters.radialSegments, parameters.p, parameters.q)
          ];
        });

        // INHERITANCE
        QUnit.test("Extending", (assert) => {
          var object = new TorusKnotGeometry();
          assert.ok(object instanceof BufferGeometry, "TorusKnotGeometry extends from BufferGeometry");
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) => {
          var object = new TorusKnotGeometry();
          assert.ok(object != null, "Can instantiate a TorusKnotGeometry.");
        });

        // PROPERTIES
        QUnit.test("type", (assert) => {
          var object = new TorusKnotGeometry();
          assert.ok(object.type == "TorusKnotGeometry", "TorusKnotGeometry.type should be TorusKnotGeometry");
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
          runStdGeometryTests(assert, geometries);
        });
      });
    });
  }
}