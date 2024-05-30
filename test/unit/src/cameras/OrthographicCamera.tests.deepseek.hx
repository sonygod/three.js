import js.Browser.window;

class OrthographicCameraTest {
    static function main() {
        var test = new OrthographicCameraTest();
        test.run();
    }

    function run() {
        // INHERITANCE
        this.extending();

        // INSTANCING
        this.instancing();

        // PROPERTIES
        this.type();

        // PUBLIC
        this.isOrthographicCamera();

        // OTHERS
        this.clone();
    }

    function extending() {
        var object = new OrthographicCamera();
        assert(object instanceof Camera, "OrthographicCamera extends from Camera");
    }

    function instancing() {
        var object = new OrthographicCamera();
        assert(object != null, "Can instantiate an OrthographicCamera.");
    }

    function type() {
        var object = new OrthographicCamera();
        assert(object.type == "OrthographicCamera", "OrthographicCamera.type should be OrthographicCamera");
    }

    function isOrthographicCamera() {
        var object = new OrthographicCamera();
        assert(object.isOrthographicCamera, "OrthographicCamera.isOrthographicCamera should be true");
    }

    function clone() {
        var left = -1.5, right = 1.5, top = 1, bottom = -1, near = 0.1, far = 42;
        var cam = new OrthographicCamera(left, right, top, bottom, near, far);

        var clonedCam = cam.clone();

        assert(cam.left == clonedCam.left, "left is equal");
        assert(cam.right == clonedCam.right, "right is equal");
        assert(cam.top == clonedCam.top, "top is equal");
        assert(cam.bottom == clonedCam.bottom, "bottom is equal");
        assert(cam.near == clonedCam.near, "near is equal");
        assert(cam.far == clonedCam.far, "far is equal");
        assert(cam.zoom == clonedCam.zoom, "zoom is equal");
    }

    function assert(condition:Bool, message:String) {
        if (!condition) {
            trace("Assertion failed: " + message);
        }
    }
}

class OrthographicCamera {
    public var left:Float;
    public var right:Float;
    public var top:Float;
    public var bottom:Float;
    public var near:Float;
    public var far:Float;
    public var zoom:Float;
    public var isOrthographicCamera:Bool;

    public function new(left:Float, right:Float, top:Float, bottom:Float, near:Float, far:Float) {
        this.left = left;
        this.right = right;
        this.top = top;
        this.bottom = bottom;
        this.near = near;
        this.far = far;
        this.zoom = 1;
        this.isOrthographicCamera = true;
    }

    public function clone():OrthographicCamera {
        return new OrthographicCamera(this.left, this.right, this.top, this.bottom, this.near, this.far);
    }
}

class Camera {
}

class Test {
    static function main() {
        OrthographicCameraTest.main();
    }
}

window.onload = function() {
    Test.main();
};