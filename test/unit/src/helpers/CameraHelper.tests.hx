Here is the converted Haxe code:
```
package three.helpers;

import haxe.unit.TestCase;
import three.cameras.PerspectiveCamera;
import three.helpers.CameraHelper;
import three.objects.LineSegments;

class CameraHelperTest {
    public function new() {}

    public function testExtending():Void {
        var camera = new PerspectiveCamera();
        var object = new CameraHelper(camera);
        assertEquals(true, Std.is(object, LineSegments), 'CameraHelper extends from LineSegments');
    }

    public function testInstancing():Void {
        var camera = new PerspectiveCamera();
        var object = new CameraHelper(camera);
        assertNotNull(object, 'Can instantiate a CameraHelper.');
    }

    public function testType():Void {
        var camera = new PerspectiveCamera();
        var object = new CameraHelper(camera);
        assertEquals('CameraHelper', object.type, 'CameraHelper.type should be CameraHelper');
    }

    public function testCamera():Void {
        // todo: implement me
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testMatrix():Void {
        // todo: implement me
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testMatrixAutoUpdate():Void {
        // todo: implement me
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testPointMap():Void {
        // todo: implement me
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testSetColors():Void {
        // todo: implement me
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testUpdate():Void {
        // todo: implement me
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testDispose():Void {
        var camera = new PerspectiveCamera();
        var object = new CameraHelper(camera);
        object.dispose();
    }
}
```
Note that I've used the Haxe unit testing framework, which is similar to QUnit. I've also removed the `export default` statement, as it's not necessary in Haxe. Additionally, I've used the `haxe.unit` package for the test framework, and `Std.is` to replace the `instanceof` operator.