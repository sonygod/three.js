import qunit.QUnit;
import threejs.geometries.ConeGeometry;
import threejs.geometries.CylinderGeometry;
import threejs.test.utils.QUnitUtils;

class ConeGeometryTests {
    public static function main() {
        QUnit.module("Geometries", () -> {
            QUnit.module("ConeGeometry", (hooks) -> {
                var geometries:Array<ConeGeometry> = [];

                hooks.beforeEach(function() {
                    geometries = [new ConeGeometry()];
                });

                QUnit.test("Extending", (assert) -> {
                    var object = new ConeGeometry();
                    assert.strictEqual(Std.is(object, CylinderGeometry), true, "ConeGeometry extends from CylinderGeometry");
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new ConeGeometry();
                    assert.ok(object, "Can instantiate a ConeGeometry.");
                });

                QUnit.test("type", (assert) -> {
                    var object = new ConeGeometry();
                    assert.ok(object.type == "ConeGeometry", "ConeGeometry.type should be ConeGeometry");
                });

                QUnit.test("Standard geometry tests", (assert) -> {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}