import js.QUnit;
import js.three.cameras.CubeCamera;
import js.three.core.Object3D;

class _Main {
    static function main() {
        QUnit.module("Cameras", {
            setup: function() {},
            teardown: function() {}
        });

        QUnit.module("CubeCamera", {
            setup: function() {},
            teardown: function() {}
        });

        // INHERITANCE
        QUnit.test("Extending", function(assert) {
            var object = new CubeCamera();
            assert.strictEqual(
                Std.is(object, Object3D),
                true,
                "CubeCamera extends from Object3D"
            );
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
            var object = new CubeCamera();
            assert.ok(object, "Can instantiate a CubeCamera.");
        });

        // PROPERTIES
        QUnit.test("type", function(assert) {
            var object = new CubeCamera();
            assert.ok(
                object.type == "CubeCamera",
                "CubeCamera.type should be CubeCamera"
            );
        });

        QUnit.todo("renderTarget", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.todo("update", function(assert) {
            // update(renderer, scene)
            assert.ok(false, "everything's gonna be alright");
        });
    }
}