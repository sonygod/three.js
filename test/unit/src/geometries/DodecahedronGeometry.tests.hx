package three.test.unit.src.geometries;

import three.geometries.DodecahedronGeometry;
import three.geometries.PolyhedronGeometry;
import three.test.unit.utils.QUnitUtils;

class DodecahedronGeometryTests {

    public function new() {}

    public static function main() {
        QUnit.module("Geometries", () -> {
            QUnit.module("DodecahedronGeometry", (hooks) -> {
                var geometries:Array<DodecahedronGeometry> = null;
                hooks.beforeEach(() -> {
                    var parameters = {
                        radius: 10,
                        detail: null
                    };
                    geometries = [
                        new DodecahedronGeometry(),
                        new DodecahedronGeometry(parameters.radius),
                        new DodecahedronGeometry(parameters.radius, parameters.detail),
                    ];
                });

                QUnit.test("Extending", (assert) -> {
                    var object:DodecahedronGeometry = new DodecahedronGeometry();
                    assert.ok(object instanceof PolyhedronGeometry, "DodecahedronGeometry extends from PolyhedronGeometry");
                });

                QUnit.test("Instancing", (assert) -> {
                    var object:DodecahedronGeometry = new DodecahedronGeometry();
                    assert.ok(object, "Can instantiate a DodecahedronGeometry.");
                });

                QUnit.test("type", (assert) -> {
                    var object:DodecahedronGeometry = new DodecahedronGeometry();
                    assert.ok(object.type == "DodecahedronGeometry", "DodecahedronGeometry.type should be DodecahedronGeometry");
                });

                QUnit.test("todo parameters", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.test("todo fromJSON", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.test("Standard geometry tests", (assert) -> {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}