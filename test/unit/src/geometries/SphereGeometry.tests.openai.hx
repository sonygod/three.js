package three.test.unit.src.geometries;

import three.geometries.SphereGeometry;
import three.core.BufferGeometry;
import three.test.utils.QUnitUtils;

class SphereGeometryTests {

    public static function main() {
        QUnit.module("Geometries", () => {
            QUnit.module("SphereGeometry", (hooks) => {
                var geometries:Array<SphereGeometry> = null;
                hooks.beforeEach(() => {
                    var parameters = {
                        radius: 10,
                        widthSegments: 20,
                        heightSegments: 30,
                        phiStart: 0.5,
                        phiLength: 1.0,
                        thetaStart: 0.4,
                        thetaLength: 2.0
                    };
                    geometries = [
                        new SphereGeometry(),
                        new SphereGeometry(parameters.radius),
                        new SphereGeometry(parameters.radius, parameters.widthSegments),
                        new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments),
                        new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart),
                        new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart, parameters.phiLength),
                        new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart, parameters.phiLength, parameters.thetaStart),
                        new SphereGeometry(parameters.radius, parameters.widthSegments, parameters.heightSegments, parameters.phiStart, parameters.phiLength, parameters.thetaStart, parameters.thetaLength)
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var object = new SphereGeometry();
                    assert.ok(Std.is(object, BufferGeometry), "SphereGeometry extends from BufferGeometry");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object = new SphereGeometry();
                    assert.ok(object != null, "Can instantiate a SphereGeometry.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object = new SphereGeometry();
                    assert.ok(object.type == "SphereGeometry", "SphereGeometry.type should be SphereGeometry");
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
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}