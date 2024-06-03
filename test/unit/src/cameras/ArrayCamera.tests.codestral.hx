import js.Browser.document;
import threejs.src.cameras.ArrayCamera;
import threejs.src.cameras.PerspectiveCamera;

class ArrayCameraTests {
    public function new() {
        testExtending();
        testInstancing();
        testIsArrayCamera();
    }

    private function testExtending(): Void {
        var object = new ArrayCamera();
        if (Std.is(object, PerspectiveCamera)) {
            trace("ArrayCamera extends from PerspectiveCamera");
        } else {
            trace("ArrayCamera does not extend from PerspectiveCamera");
        }
    }

    private function testInstancing(): Void {
        var object = new ArrayCamera();
        if (object != null) {
            trace("Can instantiate an ArrayCamera.");
        } else {
            trace("Cannot instantiate an ArrayCamera.");
        }
    }

    private function testIsArrayCamera(): Void {
        var object = new ArrayCamera();
        if (object.isArrayCamera) {
            trace("ArrayCamera.isArrayCamera should be true");
        } else {
            trace("ArrayCamera.isArrayCamera should be false");
        }
    }
}