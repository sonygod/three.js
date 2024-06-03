import qunit.QUnit;
import three.geometries.LatheGeometry;
import three.core.BufferGeometry;
import utils.QUnitUtils;

class LatheGeometryTests {
    static function main() {
        QUnit.module("Geometries", () -> {
            QUnit.module("LatheGeometry", (hooks) -> {
                var geometries:Array<LatheGeometry> = null;
                hooks.beforeEach(() -> {
                    var parameters = {
                        points: Array<Dynamic>(),
                        segments: 0,
                        phiStart: 0,
                        phiLength: 0
                    };

                    geometries = [
                        new LatheGeometry(parameters.points)
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object = new LatheGeometry();
                    assert.strictEqual(Std.is(object, BufferGeometry), true, 'LatheGeometry extends from BufferGeometry');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new LatheGeometry();
                    assert.ok(object != null, 'Can instantiate a LatheGeometry.');
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object = new LatheGeometry();
                    assert.ok(object.type == "LatheGeometry", 'LatheGeometry.type should be LatheGeometry');
                });

                QUnit.todo("parameters", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // STATIC
                QUnit.todo("fromJSON", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // OTHERS
                QUnit.test("Standard geometry tests", (assert) -> {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}