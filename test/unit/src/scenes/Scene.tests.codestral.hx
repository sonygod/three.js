import qunit.QUnit;
import three.scenes.Scene;
import three.core.Object3D;

class SceneTests {
    public function new() {
        QUnit.module("Scenes", () -> {
            QUnit.module("Scene", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object = new Scene();
                    assert.strictEqual(Std.is(object, Object3D), true, "Scene extends from Object3D");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new Scene();
                    assert.ok(object, "Can instantiate a Scene.");
                });

                // PROPERTIES
                QUnit.todo("type", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("background", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                //...continue with other QUnit.todo functions

                // PUBLIC
                QUnit.test("isScene", (assert) -> {
                    var object = new Scene();
                    assert.ok(object.isScene, "Scene.isScene should be true");
                });

                QUnit.todo("copy", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("toJSON", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}