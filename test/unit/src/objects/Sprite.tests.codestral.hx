import qunit.QUnit;
import three.core.Object3D;
import three.objects.Sprite;

class SpriteTests {
    public static function main() {
        QUnit.module("Objects", () -> {
            QUnit.module("Sprite", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var sprite:Sprite = new Sprite();
                    assert.strictEqual(Std.is(sprite, Object3D), true, "Sprite extends from Object3D");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object:Sprite = new Sprite();
                    assert.ok(object, "Can instantiate a Sprite.");
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object:Sprite = new Sprite();
                    assert.ok(object.type == "Sprite", "Sprite.type should be Sprite");
                });

                // PUBLIC
                QUnit.test("isSprite", (assert) -> {
                    var object:Sprite = new Sprite();
                    assert.ok(object.isSprite, "Sprite.isSprite should be true");
                });
            });
        });
    }
}