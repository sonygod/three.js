package three.geom;

import three.core.BufferGeometry;
import three.geom.TorusGeometry;
import three.tests.qunit.QUnit;
import three.tests.utils.QUnitUtils;

class TorusGeometryTests {

    static public function main() {
        QUnit.module("Geometries", () -> {
            QUnit.module("TorusGeometry", (hooks) -> {
                var geometries:Array<TorusGeometry> = null;
                hooks.beforeEach(() -> {
                    var parameters = {
                        radius: 10,
                        tube: 20,
                        radialSegments: 30,
                        tubularSegments: 10,
                        arc: 2.0
                    };
                    geometries = [
                        new TorusGeometry(),
                        new TorusGeometry(parameters.radius),
                        new TorusGeometry(parameters.radius, parameters.tube),
                        new TorusGeometry(parameters.radius, parameters.tube, parameters.radialSegments),
                        new TorusGeometry(parameters.radius, parameters.tube, parameters.radialSegments, parameters.tubularSegments),
                        new TorusGeometry(parameters.radius, parameters.tube, parameters.radialSegments, parameters.tubularSegments, parameters.arc)
                    ];
                });

                QUnit.test("Extending", (assert) -> {
                    var object = new TorusGeometry();
                    assert.ok(object instanceof BufferGeometry, "TorusGeometry extends from BufferGeometry");
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new TorusGeometry();
                    assert.ok(object != null, "Can instantiate a TorusGeometry.");
                });

                QUnit.test("type", (assert) -> {
                    var object = new TorusGeometry();
                    assert.ok(object.type == "TorusGeometry", "TorusGeometry.type should be TorusGeometry");
                });

                QUnit.todo("parameters", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("fromJSON", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.test("Standard geometry tests", (assert) -> {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}