package three.test.unit.src.cameras;

import three.cameras.OrthographicCamera;
import three.cameras.Camera;

class OrthographicCameraTest {

    public function new() {}

    public static function main() {
        QUnit.module("Cameras", () => {
            QUnit.module("OrthographicCamera", () => {
                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var object = new OrthographicCamera();
                    assert.ok(object instanceof Camera, "OrthographicCamera extends from Camera");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object = new OrthographicCamera();
                    assert.ok(object, "Can instantiate an OrthographicCamera.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object = new OrthographicCamera();
                    assert.ok(object.type == "OrthographicCamera", "OrthographicCamera.type should be OrthographicCamera");
                });

                QUnit.todo("zoom", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("view", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("left", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("right", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("top", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("bottom", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("near", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("far", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.test("isOrthographicCamera", (assert) => {
                    var object = new OrthographicCamera();
                    assert.ok(object.isOrthographicCamera, "OrthographicCamera.isOrthographicCamera should be true");
                });

                QUnit.todo("copy", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setViewOffset", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("clearViewOffset", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.test("updateProjectionMatrix", (assert) => {
                    var left = -1;
                    var right = 1;
                    var top = 1;
                    var bottom = -1;
                    var near = 1;
                    var far = 3;
                    var cam = new OrthographicCamera(left, right, top, bottom, near, far);

                    // updateProjectionMatrix is called in constructor
                    var pMatrix = cam.projectionMatrix.elements;

                    // orthographic projection is given by the 4x4 Matrix
                    // 2/r-l      0               0        -(l+r/r-l)
                    //   0        2/t-b           0        -(t+b/t-b)
                    //   0         0             -2/f-n   -(f+n/f-n)
                    //   0         0               0             1

                    assert.ok(pMatrix[0] == 2 / (right - left), "m[0,0] === 2 / (r - l)");
                    assert.ok(pMatrix[5] == 2 / (top - bottom), "m[1,1] === 2 / (t - b)");
                    assert.ok(pMatrix[10] == -2 / (far - near), "m[2,2] === -2 / (f - n)");
                    assert.ok(pMatrix[12] == -((right + left) / (right - left)), "m[3,0] === -(r+l/r-l)");
                    assert.ok(pMatrix[13] == -((top + bottom) / (top - bottom)), "m[3,1] === -(t+b/b-t)");
                    assert.ok(pMatrix[14] == -((far + near) / (far - near)), "m[3,2] === -(f+n/f-n)");
                });

                QUnit.todo("toJSON", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // OTHERS
                // TODO: clone is a camera methods that relied to copy method
                QUnit.test("clone", (assert) => {
                    var left = -1.5;
                    var right = 1.5;
                    var top = 1;
                    var bottom = -1;
                    var near = 0.1;
                    var far = 42;
                    var cam = new OrthographicCamera(left, right, top, bottom, near, far);

                    var clonedCam = cam.clone();

                    assert.ok(cam.left == clonedCam.left, "left is equal");
                    assert.ok(cam.right == clonedCam.right, "right is equal");
                    assert.ok(cam.top == clonedCam.top, "top is equal");
                    assert.ok(cam.bottom == clonedCam.bottom, "bottom is equal");
                    assert.ok(cam.near == clonedCam.near, "near is equal");
                    assert.ok(cam.far == clonedCam.far, "far is equal");
                    assert.ok(cam.zoom == clonedCam.zoom, "zoom is equal");
                });
            });
        });
    }
}