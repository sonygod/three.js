package three.helpers;

import three.cameras.PerspectiveCamera;
import three.objects.LineSegments;
import three.helpers.CameraHelper;

class CameraHelperTests {
    public function new() {}

    public function testInheritance():Void {
        var camera:PerspectiveCamera = new PerspectiveCamera();
        var object:CameraHelper = new CameraHelper(camera);
        assertTrue(object instanceof LineSegments, 'CameraHelper extends from LineSegments');
    }

    public function testInstancing():Void {
        var camera:PerspectiveCamera = new PerspectiveCamera();
        var object:CameraHelper = new CameraHelper(camera);
        assertNotNull(object, 'Can instantiate a CameraHelper.');
    }

    public function testType():Void {
        var camera:PerspectiveCamera = new PerspectiveCamera();
        var object:CameraHelper = new CameraHelper(camera);
        assertEquals(object.type, 'CameraHelper', 'CameraHelper.type should be CameraHelper');
    }

    // TODO: implement these tests
    public function todoCamera():Void {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todoMatrix():Void {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todoMatrixAutoUpdate():Void {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todoPointMap():Void {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todoSetColors():Void {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todoUpdate():Void {
        assertTrue(false, "everything's gonna be alright");
    }

    public function testDispose():Void {
        var camera:PerspectiveCamera = new PerspectiveCamera();
        var object:CameraHelper = new CameraHelper(camera);
        object.dispose();
    }
}