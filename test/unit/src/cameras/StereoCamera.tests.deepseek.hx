package;

import js.Lib;
import js.Browser.window;
import three.js.cameras.StereoCamera;

class StereoCameraTest {

    static function main() {
        var qunit = Lib.unsafeCast(window.QUnit);

        qunit.module("Cameras");

        qunit.module("StereoCamera");

        // INSTANCING
        qunit.test("Instancing", function(assert) {
            var object = new StereoCamera();
            assert.ok(object != null, "Can instantiate a StereoCamera.");
        });

        // PROPERTIES
        qunit.test("type", function(assert) {
            var object = new StereoCamera();
            assert.ok(object.type == "StereoCamera", "StereoCamera.type should be StereoCamera");
        });

        qunit.todo("aspect", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunit.todo("eyeSep", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunit.todo("cameraL", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qunit.todo("cameraR", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        qunit.todo("update", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}