import qunit.QUnit;
import three.src.helpers.Box3Helper;
import three.src.objects.LineSegments;

class Box3HelperTests {
    public static function main() {
        QUnit.module("Helpers", () -> {
            QUnit.module("Box3Helper", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object:Box3Helper = new Box3Helper();
                    assert.strictEqual(Std.is(object, LineSegments), true, "Box3Helper extends from LineSegments");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object:Box3Helper = new Box3Helper();
                    assert.ok(object != null, "Can instantiate a Box3Helper.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object:Box3Helper = new Box3Helper();
                    assert.ok(object.type == "Box3Helper", "Box3Helper.type should be Box3Helper");
                });

                // PUBLIC
                QUnit.test("dispose", (assert) -> {
                    assert.expect(0);
                    var object:Box3Helper = new Box3Helper();
                    object.dispose();
                });
            });
        });
    }
}