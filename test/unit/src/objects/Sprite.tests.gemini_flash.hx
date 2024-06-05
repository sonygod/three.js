import qunit.QUnit;
import three.core.Object3D;
import three.objects.Sprite;

class SpriteTest extends QUnit {

    static function main() {
        new SpriteTest().run();
    }

    public function new() {
        super();
        module("Objects", () -> {
            module("Sprite", () -> {
                test("Extending", (assert) -> {
                    var sprite = new Sprite();
                    assert.strictEqual(sprite.is(Object3D), true, "Sprite extends from Object3D");
                });

                test("Instancing", (assert) -> {
                    var object = new Sprite();
                    assert.ok(object, "Can instantiate a Sprite.");
                });

                test("type", (assert) -> {
                    var object = new Sprite();
                    assert.ok(object.type == "Sprite", "Sprite.type should be Sprite");
                });

                todo("geometry", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                todo("material", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                todo("center", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                test("isSprite", (assert) -> {
                    var object = new Sprite();
                    assert.ok(object.isSprite, "Sprite.isSprite should be true");
                });

                todo("raycast", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                todo("copy", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}

SpriteTest.main();