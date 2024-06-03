import qunit.QUnit;
import three.geometries.CapsuleGeometry;
import three.geometries.LatheGeometry;
import utils.QUnitUtils;

class CapsuleGeometryTests {

    public static function main() {
        QUnit.module("Geometries", () -> {
            QUnit.module("CapsuleGeometry", (hooks) -> {
                var geometries:Array<CapsuleGeometry> = null;
                hooks.beforeEach(() -> {
                    var parameters = {
                        radius: 2,
                        length: 2,
                        capSegments: 20,
                        radialSegments: 20
                    };

                    geometries = [
                        new CapsuleGeometry(),
                        new CapsuleGeometry(parameters.radius),
                        new CapsuleGeometry(parameters.radius, parameters.length),
                        new CapsuleGeometry(parameters.radius, parameters.length, parameters.capSegments),
                        new CapsuleGeometry(parameters.radius, parameters.length, parameters.capSegments, parameters.radialSegments),
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object = new CapsuleGeometry();
                    assert.strictEqual(Std.is(object, LatheGeometry), true, "CapsuleGeometry extends from LatheGeometry");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new CapsuleGeometry();
                    assert.ok(object, "Can instantiate a CapsuleGeometry.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object = new CapsuleGeometry();
                    assert.ok(object.type == "CapsuleGeometry", "CapsuleGeometry.type should be CapsuleGeometry");
                });

                QUnit.todo("parameters", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // STATIC
                QUnit.todo("fromJSON", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // OTHERS
                QUnit.test("Standard geometry tests", (assert) -> {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });

        QUnit.load();
    }
}