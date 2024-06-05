import qunit.QUnit;
import three.textures.CanvasTexture;
import three.textures.Texture;

class TexturesTest extends QUnit {

    public static function main() {
        QUnit.module("Textures", function() {
            QUnit.module("CanvasTexture", function() {
                // INHERITANCE
                QUnit.test("Extending", function(assert) {
                    var object = new CanvasTexture();
                    assert.strictEqual(object.is(Texture), true, "CanvasTexture extends from Texture");
                });

                // INSTANCING
                QUnit.test("Instancing", function(assert) {
                    var object = new CanvasTexture();
                    assert.ok(object, "Can instantiate a CanvasTexture.");
                });

                // PROPERTIES
                QUnit.todo("needsUpdate", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.test("isCanvasTexture", function(assert) {
                    var object = new CanvasTexture();
                    assert.ok(object.isCanvasTexture, "CanvasTexture.isCanvasTexture should be true");
                });
            });
        });
    }
}

class CanvasTexture {
    public var isCanvasTexture : Bool;

    public function new() {
        this.isCanvasTexture = true;
    }
}

class Texture {
    public function is(t:Dynamic) : Bool {
        return Std.is(t, this);
    }
}

class QUnit {
    public static function module(name:String, callback:Dynamic) : Void {
        // Implement QUnit.module logic here, if needed.
    }

    public static function test(name:String, callback:Dynamic) : Void {
        // Implement QUnit.test logic here, if needed.
    }

    public static function todo(name:String, callback:Dynamic) : Void {
        // Implement QUnit.todo logic here, if needed.
    }
}

TexturesTest.main();