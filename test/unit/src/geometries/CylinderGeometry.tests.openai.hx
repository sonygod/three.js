package three.test.unit.src.geometries;

import three.geometries.CylinderGeometry;
import three.core.BufferGeometry;
import three.utils.QUnitUtils;

class CylinderGeometryTests {

    public function new() {}

    public static function main() {
        QUnit.module("Geometries", () -> {
            QUnit.module("CylinderGeometry", () -> {
                var geometries:Array<CylinderGeometry> = null;
                QUnit.beforeEach(() -> {
                    var parameters = {
                        radiusTop: 10,
                        radiusBottom: 20,
                        height: 30,
                        radialSegments: 20,
                        heightSegments: 30,
                        openEnded: true,
                        thetaStart: 0.1,
                        thetaLength: 2.0,
                    };

                    geometries = [
                        new CylinderGeometry(),
                        new CylinderGeometry(parameters.radiusTop),
                        new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom),
                        new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height),
                        new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments),
                        new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments, parameters.heightSegments),
                        new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments, parameters.heightSegments, parameters.openEnded),
                        new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments, parameters.heightSegments, parameters.openEnded, parameters.thetaStart),
                        new CylinderGeometry(parameters.radiusTop, parameters.radiusBottom, parameters.height, parameters.radialSegments, parameters.heightSegments, parameters.openEnded, parameters.thetaStart, parameters.thetaLength),
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object = new CylinderGeometry();
                    assert.ok(object instanceof BufferGeometry, 'CylinderGeometry extends from BufferGeometry');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new CylinderGeometry();
                    assert.ok(object, 'Can instantiate a CylinderGeometry.');
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object = new CylinderGeometry();
                    assert.ok(object.type == 'CylinderGeometry', 'CylinderGeometry.type should be CylinderGeometry');
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