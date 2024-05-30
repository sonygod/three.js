package three.js.test.unit.src.cameras;

import three.cameras.ArrayCamera;
import three.cameras.PerspectiveCamera;

class ArrayCameraTests {

    public function new() {}

    public static function main() {
        hut.TestSuite.run(new ArrayCameraTests());
    }

    public function testExtending() {
        var object = new ArrayCamera();
        hut.Assert.isTrue(object instanceof PerspectiveCamera, 'ArrayCamera extends from PerspectiveCamera');
    }

    public function testInstancing() {
        var object = new ArrayCamera();
        hut.Assert.notNull(object, 'Can instantiate an ArrayCamera.');
    }

    public function testCameras() {
        // TODO: implement test
        hut.Assert.fail('not implemented');
    }

    public function testIsArrayCamera() {
        var object = new ArrayCamera();
        hut.Assert.isTrue(object.isArrayCamera, 'ArrayCamera.isArrayCamera should be true');
    }
}