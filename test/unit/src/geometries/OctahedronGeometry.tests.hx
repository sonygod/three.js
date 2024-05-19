package three.geom;

import haxe.unit.TestCase;
import three.geom.OctahedronGeometry;
import three.geom.PolyhedronGeometry;
import three.utils.QUnitUtils;

class OctahedronGeometryTests {
    public static function main() {
        var testCase = new TestCase();
        testCase.test("Geometries", () => {
            testCase.test("OctahedronGeometry", () => {
                var geometries:Array<OctahedronGeometry> = null;
                testCase.beforeEach(() => {
                    var parameters = {
                        radius: 10,
                        detail: null
                    };
                    geometries = [
                        new OctahedronGeometry(),
                        new OctahedronGeometry(parameters.radius),
                        new OctahedronGeometry(parameters.radius, parameters.detail),
                    ];
                });

                // INHERITANCE
                testCase.test("Extending", (assert) => {
                    var object = new OctahedronGeometry();
                    assert.isTrue(object instanceof PolyhedronGeometry, "OctahedronGeometry extends from PolyhedronGeometry");
                });

                // INSTANCING
                testCase.test("Instancing", (assert) => {
                    var object = new OctahedronGeometry();
                    assert.notNull(object, "Can instantiate an OctahedronGeometry.");
                });

                // PROPERTIES
                testCase.test("type", (assert) => {
                    var object = new OctahedronGeometry();
                    assert.equal(object.type, "OctahedronGeometry", "OctahedronGeometry.type should be OctahedronGeometry");
                });

                testCase.todo("parameters", (assert) => {
                    assert.fail("everything's gonna be alright");
                });

                // STATIC
                testCase.todo("fromJSON", (assert) => {
                    assert.fail("everything's gonna be alright");
                });

                // OTHERS
                testCase.test("Standard geometry tests", (assert) => {
                    QUnitUtils.runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}