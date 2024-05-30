package three.format;

import three.geom.DodecahedronGeometry;
import three.geom.PolyhedronGeometry;
import qunit.QUnit;
import qunit.utils.runStdGeometryTests;

class GeometriesTest {

    public function new() {}

    public static function main() {
        QUnit.module("Geometries", () => {
            QUnit.module("DodecahedronGeometry", (hooks) => {
                var geometries:Array<DodecahedronGeometry> = null;
                hooks.beforeEach(() => {
                    var parameters = {
                        radius: 10,
                        detail: null
                    };
                    geometries = [
                        new DodecahedronGeometry(),
                        new DodecahedronGeometry(parameters.radius),
                        new DodecahedronGeometry(parameters.radius, parameters.detail)
                    ];
                });

                QUnit.test("Extending", (assert) => {
                    var object = new DodecahedronGeometry();
                    assert.ok(object instanceof PolyhedronGeometry, "DodecahedronGeometry extends from PolyhedronGeometry");
                });

                QUnit.test("Instancing", (assert) => {
                    var object = new DodecahedronGeometry();
                    assert.ok(object, "Can instantiate a DodecahedronGeometry.");
                });

                QUnit.test("type", (assert) => {
                    var object = new DodecahedronGeometry();
                    assert.equal(object.type, "DodecahedronGeometry", "DodecahedronGeometry.type should be DodecahedronGeometry");
                });

                QUnit.todo("parameters", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("fromJSON", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.test("Standard geometry tests", (assert) => {
                    runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}