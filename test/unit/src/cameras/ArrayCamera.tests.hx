package three.test.unit.src.cameras;

import haxe.unit.TestCase;

import three.cameras.ArrayCamera;
import three.cameras.PerspectiveCamera;

class ArrayCameraTests {
    public function new() {}

    public function testExtending():Void {
        var object:ArrayCamera = new ArrayCamera();
        assertTrue(object instanceof PerspectiveCamera, 'ArrayCamera extends from PerspectiveCamera');
    }

    public function testInstancing():Void {
        var object:ArrayCamera = new ArrayCamera();
        assertNotNull(object, 'Can instantiate an ArrayCamera.');
    }

    public function testCameras():Void {
        // todo: implement this test
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsArrayCamera():Void {
        var object:ArrayCamera = new ArrayCamera();
        assertTrue(object.isArrayCamera, 'ArrayCamera.isArrayCamera should be true');
    }
}