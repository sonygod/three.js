// Import necessary classes
import js.Browser.document;
import threejs.src.helpers.ArrowHelper;
import threejs.src.core.Object3D;

// Define test module
class ArrowHelperTests {
    public function new() {
        testExtending();
        testInstancing();
        testType();
        testDispose();
    }

    private function testExtending() {
        var object:ArrowHelper = new ArrowHelper();
        js.Boot.trace(Std.is(object, Object3D), "ArrowHelper extends from Object3D");
    }

    private function testInstancing() {
        var object:ArrowHelper = new ArrowHelper();
        js.Boot.trace(object != null, "Can instantiate an ArrowHelper.");
    }

    private function testType() {
        var object:ArrowHelper = new ArrowHelper();
        js.Boot.trace(object.type == "ArrowHelper", "ArrowHelper.type should be ArrowHelper");
    }

    private function testDispose() {
        var object:ArrowHelper = new ArrowHelper();
        object.dispose();
    }
}

// Run tests
var tests:ArrowHelperTests = new ArrowHelperTests();