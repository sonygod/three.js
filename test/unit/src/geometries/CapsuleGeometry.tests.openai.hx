package three.js.test.unit.src.geometries;

import three.js.src.geometries.CapsuleGeometry;
import three.js.src.geometries.LatheGeometry;
import three.js.test.unit.utils.QUnitUtil;

class CapsuleGeometryTests {
    public function new() {}

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
                        new CapsuleGeometry(parameters.radius, parameters.length, parameters.capSegments, parameters.radialSegments)
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object = new CapsuleGeometry();
                    assert.isTrue(object instanceof LatheGeometry, "CapsuleGeometry extends from LatheGeometry");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new CapsuleGeometry();
                    assert.ok(object != null, "Can instantiate a CapsuleGeometry.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object = new CapsuleGeometry();
                    assert.equal(object.type, "CapsuleGeometry", "CapsuleGeometry.type should be CapsuleGeometry");
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
                    QUnitUtil.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}