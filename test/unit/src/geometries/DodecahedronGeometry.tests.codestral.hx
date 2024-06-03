import js.Browser.document;
import js.html.QUnit;
import three.geometries.DodecahedronGeometry;
import three.geometries.PolyhedronGeometry;
import utils.QUnitUtils;

class DodecahedronGeometryTests {
    public function new() {
        QUnit.module("Geometries", () -> {
            QUnit.module("DodecahedronGeometry", (hooks) -> {
                var geometries:Array<DodecahedronGeometry> = [];

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
                    var object = new DodecahedronGeometry();
                    assert.strictEqual(js.Boot.instanceof(object, PolyhedronGeometry), true, "DodecahedronGeometry extends from PolyhedronGeometry");
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new DodecahedronGeometry();
                    assert.ok(object, "Can instantiate a DodecahedronGeometry.");
                });

                QUnit.test("type", (assert) -> {
                    var object = new DodecahedronGeometry();
                    assert.ok(object.type == "DodecahedronGeometry", "DodecahedronGeometry.type should be DodecahedronGeometry");
                });

                QUnit.test("Standard geometry tests", (assert) -> {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}