import qunit.QUnit;
import three.CameraHelper;
import three.LineSegments;
import three.PerspectiveCamera;

@:jsDoc("@global QUnit")
class CameraHelperTests {
    public static function main() {
        QUnit.module("Helpers", () -> {
            QUnit.module("CameraHelper", () -> {

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var camera = new PerspectiveCamera();
                    var obj = new CameraHelper(camera);
                    assert.strictEqual(Std.is(obj, LineSegments), true, "CameraHelper extends from LineSegments");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var camera = new PerspectiveCamera();
                    var obj = new CameraHelper(camera);
                    assert.ok(obj, "Can instantiate a CameraHelper.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var camera = new PerspectiveCamera();
                    var obj = new CameraHelper(camera);
                    assert.ok(obj.type == "CameraHelper", "CameraHelper.type should be CameraHelper");
                });

                // PUBLIC
                QUnit.test("dispose", (assert) -> {
                    var camera = new PerspectiveCamera();
                    var obj = new CameraHelper(camera);
                    obj.dispose();
                });
            });
        });
    }
}