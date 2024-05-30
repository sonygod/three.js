package;

import three.js.test.unit.src.helpers.BoxHelper;
import three.js.test.unit.src.objects.LineSegments;
import three.js.test.unit.src.utils.qunit_utils.runStdGeometryTests;
import three.js.test.unit.src.geometries.BoxGeometry;
import three.js.test.unit.src.geometries.SphereGeometry;
import three.js.test.unit.src.objects.Mesh;

class BoxHelperTests {

    public static function main() {
        var module = new QUnitModule("Helpers", function() {
            var module = new QUnitModule("BoxHelper", function(hooks) {
                var geometries:Array<LineSegments>;

                hooks.beforeEach(function() {
                    var boxGeometry = new BoxGeometry();
                    var box = new Mesh(boxGeometry);
                    var boxHelper = new BoxHelper(box);

                    var sphereGeometry = new SphereGeometry();
                    var sphere = new Mesh(sphereGeometry);
                    var sphereBoxHelper = new BoxHelper(sphere);

                    geometries = [boxHelper.geometry, sphereBoxHelper.geometry];
                });

                QUnitTest.test("Extending", function(assert) {
                    var object = new BoxHelper();
                    assert.strictEqual(
                        Std.instance(object, LineSegments), true,
                        'BoxHelper extends from LineSegments'
                    );
                });

                QUnitTest.test("Instancing", function(assert) {
                    var object = new BoxHelper();
                    assert.ok(object, 'Can instantiate a BoxHelper.');
                });

                QUnitTest.test("type", function(assert) {
                    var object = new BoxHelper();
                    assert.ok(
                        object.type == 'BoxHelper',
                        'BoxHelper.type should be BoxHelper'
                    );
                });

                QUnitTest.todo("object", function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnitTest.todo("matrixAutoUpdate", function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnitTest.todo("update", function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnitTest.todo("setFromObject", function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnitTest.todo("copy", function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnitTest.test("dispose", function(assert) {
                    assert.expect(0);

                    var object = new BoxHelper();
                    object.dispose();
                });

                QUnitTest.test("Standard geometry tests", function(assert) {
                    runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}