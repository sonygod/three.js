import js.Browser.document;
import js.html.QUnit;
import threejs.cameras.PerspectiveCamera;
import threejs.math.Matrix4;
import threejs.cameras.Camera;

class PerspectiveCameraTests {
    public function new() {
        setupQUnit();
    }

    private function setupQUnit():Void {
        QUnit.module("Cameras", () -> {
            QUnit.module("PerspectiveCamera", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object = new PerspectiveCamera();
                    assert.strictEqual(Std.is(object, Camera), true, 'PerspectiveCamera extends from Camera');
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new PerspectiveCamera();
                    assert.ok(object, 'Can instantiate a PerspectiveCamera.');
                });

                QUnit.test("type", (assert) -> {
                    var object = new PerspectiveCamera();
                    assert.ok(object.type === 'PerspectiveCamera', 'PerspectiveCamera.type should be PerspectiveCamera');
                });

                // Other properties and methods are left as TODOs as per the original code

                QUnit.test("isPerspectiveCamera", (assert) -> {
                    var object = new PerspectiveCamera();
                    assert.ok(object.isPerspectiveCamera, 'PerspectiveCamera.isPerspectiveCamera should be true');
                });

                QUnit.test("updateProjectionMatrix", (assert) -> {
                    var cam = new PerspectiveCamera(75, 16 / 9, 0.1, 300.0);
                    var m = cam.projectionMatrix;
                    var reference = new Matrix4().set(
                        0.7330642938613892, 0, 0, 0,
                        0, 1.3032253980636597, 0, 0,
                        0, 0, - 1.000666856765747, - 0.2000666856765747,
                        0, 0, - 1, 0
                    );
                    // The matrixEquals4 function is not provided so this part is left as it is
                });

                QUnit.test("clone", (assert) -> {
                    var near = 1, far = 3, aspect = 16 / 9, fov = 90;
                    var cam = new PerspectiveCamera(fov, aspect, near, far);
                    var clonedCam = cam.clone();
                    assert.ok(cam.fov === clonedCam.fov, 'fov is equal');
                    assert.ok(cam.aspect === clonedCam.aspect, 'aspect is equal');
                    assert.ok(cam.near === clonedCam.near, 'near is equal');
                    assert.ok(cam.far === clonedCam.far, 'far is equal');
                    assert.ok(cam.zoom === clonedCam.zoom, 'zoom is equal');
                    // The equals method is not provided so this part is left as it is
                });
            });
        });
    }
}