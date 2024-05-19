package three.js.test.unit.src.geometries;

import three.js.src.geometries.SphereGeometry;
import three.js.src.core.BufferGeometry;
import three.js.test.unit.src.utils.QUnitUtils;

class SphereGeometryTests {

    public function new() {}

    public static function main() {
        QUnit.module("Geometries", () -> {
            QUnit.module("SphereGeometry", (hooks) -> {
                var geometries:Array<SphereGeometry> = null;
                hooks.beforeEach(() -> {
                    var parameters = {
                        radius: 10,
                        widthSegments: 20,
                        heightSegments: 30,
                        phiStart: 0.5,
                        phiLength: 1.0,
                        thetaStart: 0.4,
                        thetaLength: 2.0,
                    };

                    geometries = [
                        new SphereGeometry(),
                        new SphereGeometry(parameters.radius),
                        new SphereGeometry(parameters.radius, parameters.widthSegments),
                        new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments),
                        new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart),
                        new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart, parameters.phiLength),
                        new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart, parameters.phiLength, parameters.thetaStart),
                        new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart, parameters.phiLength, parameters.thetaStart, parameters.thetaLength),
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object = new SphereGeometry();
                    assert.ok(object instanceof BufferGeometry, "SphereGeometry extends from BufferGeometry");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new SphereGeometry();
                    assert.ok(object, "Can instantiate a SphereGeometry.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object = new SphereGeometry();
                    assert.ok(object.type == "SphereGeometry", "SphereGeometry.type should be SphereGeometry");
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
    }
}