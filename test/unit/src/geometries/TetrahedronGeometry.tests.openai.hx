package three.geometries;

import three.geometries.TetrahedronGeometry;
import three.geometries.PolyhedronGeometry;
import test.utils.QUnitUtils;

class TetrahedronGeometryTests {
    public static function main() {
        QUnit.module("Geometries", () => {
            QUnit.module("TetrahedronGeometry", (hooks) => {
                var geometries:Array<TetrahedronGeometry> = null;

                hooks.beforeEach(() => {
                    var parameters = {
                        radius: 10,
                        detail: null
                    };

                    geometries = [
                        new TetrahedronGeometry(),
                        new TetrahedronGeometry(parameters.radius),
                        new TetrahedronGeometry(parameters.radius, parameters.detail),
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var object = new TetrahedronGeometry();
                    assert.isTrue(object instanceof PolyhedronGeometry, 'TetrahedronGeometry extends from PolyhedronGeometry');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object = new TetrahedronGeometry();
                    assert.ok(object, 'Can instantiate a TetrahedronGeometry.');
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object = new TetrahedronGeometry();
                    assert.equal(object.type, 'TetrahedronGeometry', 'TetrahedronGeometry.type should be TetrahedronGeometry');
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