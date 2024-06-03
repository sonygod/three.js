import qunit.QUnit;
import three.geometries.OctahedronGeometry;
import three.geometries.PolyhedronGeometry;
import utils.QUnitUtils;

class OctahedronGeometryTests {

    public static function main() {
        QUnit.module("Geometries", () -> {

            QUnit.module("OctahedronGeometry", (hooks) -> {

                var geometries: Array<OctahedronGeometry>;
                hooks.beforeEach(function() {

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
                QUnit.test("Extending", (assert) -> {

                    var object = new OctahedronGeometry();
                    assert.strictEqual(
                        Std.is(object, PolyhedronGeometry), true,
                        "OctahedronGeometry extends from PolyhedronGeometry"
                    );

                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {

                    var object = new OctahedronGeometry();
                    assert.notEqual(object, null, "Can instantiate an OctahedronGeometry.");

                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {

                    var object = new OctahedronGeometry();
                    assert.equal(
                        object.type, "OctahedronGeometry",
                        "OctahedronGeometry.type should be OctahedronGeometry"
                    );

                });

                QUnit.todo("parameters", (assert) -> {

                    assert.fail("Not implemented");

                });

                // STATIC
                QUnit.todo("fromJSON", (assert) -> {

                    assert.fail("Not implemented");

                });

                // OTHERS
                QUnit.test("Standard geometry tests", (assert) -> {

                    QUnitUtils.runStdGeometryTests(assert, geometries);

                });

            });

        });
    }

}