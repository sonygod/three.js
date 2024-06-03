import js.Browser.document;
import js.html.QUnit;
import three.src.cameras.StereoCamera;

class StereoCameraTests {
    public function new() {
        QUnit.module("Cameras", () -> {
            QUnit.module("StereoCamera", () -> {
                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new StereoCamera();
                    assert.ok(object, "Can instantiate a StereoCamera.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object = new StereoCamera();
                    assert.ok(object.type == "StereoCamera", "StereoCamera.type should be StereoCamera");
                });

                QUnit.skip("aspect", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.skip("eyeSep", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.skip("cameraL", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.skip("cameraR", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.skip("update", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}

new StereoCameraTests();