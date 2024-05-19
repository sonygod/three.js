package three.test.unit.src.cameras;

import haxe.unit.TestCase;
import three.cameras.PerspectiveCamera;
import three.math.Matrix4;
import three.cameras.Camera;

class PerspectiveCameraTest extends TestCase {
    // see e.g. math/Matrix4.js
    private function matrixEquals4(a:Matrix4, b:Matrix4, tolerance:Float = 0.0001):Bool {
        if (a.elements.length != b.elements.length) {
            return false;
        }
        for (i in 0...a.elements.length) {
            var delta = a.elements[i] - b.elements[i];
            if (delta > tolerance) {
                return false;
            }
        }
        return true;
    }

    public function testExtending():Void {
        var object = new PerspectiveCamera();
        assertTrue(object instanceof Camera, 'PerspectiveCamera extends from Camera');
    }

    public function testInstancing():Void {
        var object = new PerspectiveCamera();
        assertNotNull(object, 'Can instantiate a PerspectiveCamera.');
    }

    public function testType():Void {
        var object = new PerspectiveCamera();
        assertEquals(object.type, 'PerspectiveCamera', 'PerspectiveCamera.type should be PerspectiveCamera');
    }

    public function testUpdateProjectionMatrix():Void {
        var cam = new PerspectiveCamera(75, 16 / 9, 0.1, 300.0);
        var m = cam.projectionMatrix;

        // perspective projection is given my the 4x4 Matrix
        // 2n/r-l		0			l+r/r-l				 0
        //   0		2n/t-b	t+b/t-b				 0
        //   0			0		-(f+n/f-n)	-(2fn/f-n)
        //   0			0				-1					 0

        // this matrix was calculated by hand via glMatrix.perspective(75, 16 / 9, 0.1, 300.0, pMatrix)
        // to get a reference matrix from plain WebGL
        var reference = new Matrix4().set(
            0.7330642938613892, 0, 0, 0,
            0, 1.3032253980636597, 0, 0,
            0, 0, -1.000666856765747, -0.2000666856765747,
            0, 0, -1, 0
        );

        assertTrue(matrixEquals4(reference, m, 0.000001));
    }

    public function testClone():Void {
        var near = 1.0;
        var far = 3.0;
        var aspect = 16 / 9;
        var fov = 90.0;

        var cam = new PerspectiveCamera(fov, aspect, near, far);
        var clonedCam = cam.clone();

        assertEquals(cam.fov, clonedCam.fov, 'fov is equal');
        assertEquals(cam.aspect, clonedCam.aspect, 'aspect is equal');
        assertEquals(cam.near, clonedCam.near, 'near is equal');
        assertEquals(cam.far, clonedCam.far, 'far is equal');
        assertEquals(cam.zoom, clonedCam.zoom, 'zoom is equal');
        assertTrue(cam.projectionMatrix.equals(clonedCam.projectionMatrix), 'projectionMatrix is equal');
    }
}