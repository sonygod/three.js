package three.test.unit.src.helpers;

import three.helpers.BoxHelper;
import three.objects.LineSegments;
import three.geometries.BoxGeometry;
import three.geometries.SphereGeometry;
import three.objects.Mesh;

class BoxHelperTests {

    public function new() {}

    public function test() {
        // INHERITANCE
        testCase("Extending", function(assert) {
            var object = new BoxHelper();
            assert.isTrue(Std.is(object, LineSegments), 'BoxHelper extends from LineSegments');
        });

        // INSTANCING
        testCase("Instancing", function(assert) {
            var object = new BoxHelper();
            assert.notNull(object, 'Can instantiate a BoxHelper.');
        });

        // PROPERTIES
        testCase("type", function(assert) {
            var object = new BoxHelper();
            assert.equal(object.type, 'BoxHelper', 'BoxHelper.type should be BoxHelper');
        });

        // todo: implement these tests
        todoCase("object", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        todoCase("matrixAutoUpdate", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        // PUBLIC
        todoCase("update", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        todoCase("setFromObject", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        todoCase("copy", function(assert) {
            assert.fail('everything\'s gonna be alright');
        });

        // DISPOSING
        testCase("dispose", function(assert) {
            var object = new BoxHelper();
            object.dispose();
            assert.pass();
        });

        // OTHERS
        testCase("Standard geometry tests", function(assert) {
            runStdGeometryTests(assert, getGeometries());
        });
    }

    private function getGeometries():Array<three.core.Geometry> {
        var boxGeometry = new BoxGeometry();
        var box = new Mesh(boxGeometry);
        var boxHelper = new BoxHelper(box);

        var sphereGeometry = new SphereGeometry();
        var sphere = new Mesh(sphereGeometry);
        var sphereBoxHelper = new BoxHelper(sphere);

        return [boxHelper.geometry, sphereBoxHelper.geometry];
    }

    private function runStdGeometryTests(assert:Assert, geometries:Array<three.core.Geometry>) {
        // implement the runStdGeometryTests function
    }
}