package three.geom.tests;

import three.geom.IcosahedronGeometry;
import three.geom.PolyhedronGeometry;
import three.utils.QUnitUtils;

class IcosahedronGeometryTests {

    public static function main() {
        QUnit.module("Geometries", () => {
            QUnit.module("IcosahedronGeometry", (hooks) => {
                var geometries:Array<IcosahedronGeometry> = null;
                hooks.beforeEach(() => {
                    var parameters = {
                        radius: 10,
                        detail: null
                    };
                    geometries = [
                        new IcosahedronGeometry(),
                        new IcosahedronGeometry(parameters.radius),
                        new IcosahedronGeometry(parameters.radius, parameters.detail)
                    ];
                });

                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var object = new IcosahedronGeometry();
                    assert.ok(object instanceof PolyhedronGeometry, "IcosahedronGeometry extends from PolyhedronGeometry");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object = new IcosahedronGeometry();
                    assert.ok(object != null, "Can instantiate an IcosahedronGeometry.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object = new IcosahedronGeometry();
                    assert.ok(object.type == "IcosahedronGeometry", "IcosahedronGeometry.type should be IcosahedronGeometry");
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