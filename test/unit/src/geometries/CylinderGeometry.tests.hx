package three.geom;

import haxe.unit.TestCase;
import three.geom.BufferGeometry;
import three.geom.CylinderGeometry;
import three.utils.QUnitUtils;

class CylinderGeometryTests {
    static function main() {
        TestCase.createSuite("Geometries", function(testCase:TestCase) {
            testCase.addTest("CylinderGeometry", function(testCase:TestCase) {
                var geometries:Array<CylinderGeometry> = null;

                testCase.beforeEach(function() {
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
                testCase.test("Extending", function(assert) {
                    var object = new CylinderGeometry();
                    assert.isTrue(object instanceof BufferGeometry, "CylinderGeometry extends from BufferGeometry");
                });

                // INSTANCING
                testCase.test("Instancing", function(assert) {
                    var object = new CylinderGeometry();
                    assert.notNull(object, "Can instantiate a CylinderGeometry.");
                });

                // PROPERTIES
                testCase.test("type", function(assert) {
                    var object = new CylinderGeometry();
                    assert.equals(object.type, "CylinderGeometry", "CylinderGeometry.type should be CylinderGeometry");
                });

                // TODO: implement these tests
                testCase.test("parameters", function(assert) {
                    assert.fail("Not implemented");
                });

                testCase.test("fromJSON", function(assert) {
                    assert.fail("Not implemented");
                });

                // OTHERS
                testCase.test("Standard geometry tests", function(assert) {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}