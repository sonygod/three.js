import three.cameras.OrthographicCamera;
import three.cameras.Camera;

class OrthographicCameraTests {
    public static function main() {
        testExtending();
        testInstancing();
        testType();
        testIsOrthographicCamera();
        testUpdateProjectionMatrix();
        testClone();
    }

    private static function testExtending() {
        var object:OrthographicCamera = new OrthographicCamera();
        trace("OrthographicCamera extends from Camera: " + (object is Camera));
    }

    private static function testInstancing() {
        var object:OrthographicCamera = new OrthographicCamera();
        trace("Can instantiate an OrthographicCamera: " + (object != null));
    }

    private static function testType() {
        var object:OrthographicCamera = new OrthographicCamera();
        trace("OrthographicCamera.type should be OrthographicCamera: " + (object.type == "OrthographicCamera"));
    }

    private static function testIsOrthographicCamera() {
        var object:OrthographicCamera = new OrthographicCamera();
        trace("OrthographicCamera.isOrthographicCamera should be true: " + object.isOrthographicCamera);
    }

    private static function testUpdateProjectionMatrix() {
        var left:Float = -1;
        var right:Float = 1;
        var top:Float = 1;
        var bottom:Float = -1;
        var near:Float = 1;
        var far:Float = 3;
        var cam:OrthographicCamera = new OrthographicCamera(left, right, top, bottom, near, far);

        var pMatrix:Array<Float> = cam.projectionMatrix.elements;

        trace("m[0,0] === 2 / (r - l): " + (pMatrix[0] == 2 / (right - left)));
        trace("m[1,1] === 2 / (t - b): " + (pMatrix[5] == 2 / (top - bottom)));
        trace("m[2,2] === -2 / (f - n): " + (pMatrix[10] == -2 / (far - near)));
        trace("m[3,0] === -(r+l/r-l): " + (pMatrix[12] == - (right + left) / (right - left)));
        trace("m[3,1] === -(t+b/b-t): " + (pMatrix[13] == - (top + bottom) / (top - bottom)));
        trace("m[3,2] === -(f+n/f-n): " + (pMatrix[14] == - (far + near) / (far - near)));
    }

    private static function testClone() {
        var left:Float = -1.5;
        var right:Float = 1.5;
        var top:Float = 1;
        var bottom:Float = -1;
        var near:Float = 0.1;
        var far:Float = 42;
        var cam:OrthographicCamera = new OrthographicCamera(left, right, top, bottom, near, far);

        var clonedCam:OrthographicCamera = cam.clone();

        trace("left is equal: " + (cam.left == clonedCam.left));
        trace("right is equal: " + (cam.right == clonedCam.right));
        trace("top is equal: " + (cam.top == clonedCam.top));
        trace("bottom is equal: " + (cam.bottom == clonedCam.bottom));
        trace("near is equal: " + (cam.near == clonedCam.near));
        trace("far is equal: " + (cam.far == clonedCam.far));
        trace("zoom is equal: " + (cam.zoom == clonedCam.zoom));
    }
}