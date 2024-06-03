import three.geometries.BoxGeometry;
import three.geometries.SphereGeometry;
import three.helpers.BoxHelper;
import three.objects.LineSegments;
import three.objects.Mesh;
import qunit.QUnit;
import utils.QUnitUtils;

class BoxHelperTests {

    static function main() {

        QUnit.module("Helpers", () -> {

            QUnit.module("BoxHelper", (hooks) -> {

                var geometries:Array<three.core.Geometry> = [];

                hooks.beforeEach(() -> {

                    // Test with a normal cube and a box helper
                    var boxGeometry = new BoxGeometry();
                    var box = new Mesh(boxGeometry);
                    var boxHelper = new BoxHelper(box);

                    // The same should happen with a comparable sphere
                    var sphereGeometry = new SphereGeometry();
                    var sphere = new Mesh(sphereGeometry);
                    var sphereBoxHelper = new BoxHelper(sphere);

                    geometries = [boxHelper.geometry, sphereBoxHelper.geometry];

                });

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {

                    var object = new BoxHelper();
                    assert.strictEqual(Std.is(object, LineSegments), true, 'BoxHelper extends from LineSegments');

                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {

                    var object = new BoxHelper();
                    assert.ok(object != null, 'Can instantiate a BoxHelper.');

                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {

                    var object = new BoxHelper();
                    assert.ok(object.type == "BoxHelper", 'BoxHelper.type should be BoxHelper');

                });

                QUnit.todo("object", (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo("matrixAutoUpdate", (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC
                QUnit.todo("update", (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo("setFromObject", (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo("copy", (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.test("dispose", (assert) -> {

                    assert.expect(0);

                    var object = new BoxHelper();
                    object.dispose();

                });

                // OTHERS
                QUnit.test("Standard geometry tests", (assert) -> {

                    QUnitUtils.runStdGeometryTests(assert, geometries);

                });

            });

        });

    }

}