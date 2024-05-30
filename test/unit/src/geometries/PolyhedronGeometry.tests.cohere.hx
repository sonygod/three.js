import js.QUnit;
import js.PolyhedronGeometry.PolyhedronGeometry_Impl_;
import js.BufferGeometry.BufferGeometry_Impl_;
import js.qunitUtils.qunitUtils_Impl_.runStdGeometryTests;

class _Main {
    static function main() {
        var geometries:Array<PolyhedronGeometry> = [];
        var vertices = [1, 1, 1, -1, -1, 1, -1, 1, -1, 1, -1, -1];
        var indices = [2, 1, 0, 0, 3, 2, 1, 3, 0, 2, 3, 1];

        QUnit.module("Geometries", function (hooks) {
            QUnit.module("PolyhedronGeometry", function (hooks) {
                hooks.beforeEach(function () {
                    geometries = [new PolyhedronGeometry(vertices, indices)];
                });

                QUnit.test("Extending", function (assert) {
                    var object = new PolyhedronGeometry();
                    assert.strictEqual(
                        Std.is(object, BufferGeometry),
                        true,
                        "PolyhedronGeometry extends from BufferGeometry"
                    );
                });

                QUnit.test("Instancing", function (assert) {
                    var object = new PolyhedronGeometry();
                    assert.ok(object, "Can instantiate a PolyhedronGeometry.");
                });

                QUnit.test("type", function (assert) {
                    var object = new PolyhedronGeometry();
                    assert.ok(
                        object.type == "PolyhedronGeometry",
                        "PolyhedronGeometry.type should be PolyhedronGeometry"
                    );
                });

                QUnit.test("Standard geometry tests", function (assert) {
                    runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}