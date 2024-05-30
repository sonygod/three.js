package three.helpers;

import haxe.unit.TestCase;
import three.geometries.BoxGeometry;
import three.geometries.SphereGeometry;
import three.helpers.BoxHelper;
import three.objects.LineSegments;
import three.objects.Mesh;

class BoxHelperTest {
    var geometries:Array<three.geometries.Geometry>;

    public function new() {}

    @Before
    public function setup():Void {
        // Test with a normal cube and a box helper
        var boxGeometry = new BoxGeometry();
        var box = new Mesh(boxGeometry);
        var boxHelper = new BoxHelper(box);

        // The same should happen with a comparable sphere
        var sphereGeometry = new SphereGeometry();
        var sphere = new Mesh(sphereGeometry);
        var sphereBoxHelper = new BoxHelper(sphere);

        geometries = [boxHelper.geometry, sphereBoxHelper.geometry];
    }

    @Test
    public function inheritanceTest():Void {
        var object = new BoxHelper();
        assertEquals(object instanceof LineSegments, true, 'BoxHelper extends from LineSegments');
    }

    @Test
    public function instancingTest():Void {
        var object = new BoxHelper();
        assertTrue(object != null, 'Can instantiate a BoxHelper.');
    }

    @Test
    public function typeTest():Void {
        var object = new BoxHelper();
        assertEquals(object.type, 'BoxHelper', 'BoxHelper.type should be BoxHelper');
    }

    @Test
    public function todoObjectTest():Void {
        // todo: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

    @Test
    public function todoMatrixAutoUpdateTest():Void {
        // todo: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

    @Test
    public function todoUpdateTest():Void {
        // todo: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

    @Test
    public function todoSetFromObjectTest():Void {
        // todo: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

    @Test
    public function todoCopyTest():Void {
        // todo: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

    @Test
    public function disposeTest():Void {
        var object = new BoxHelper();
        object.dispose();
    }

    @Test
    public function standardGeometryTests():Void {
        runStdGeometryTests(this, geometries);
    }
}