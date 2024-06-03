import js.Browser.document;
import js.html.QUnit;
import three.src.textures.CanvasTexture;
import three.src.textures.Texture;

class CanvasTextureTests {
  public function new() {
    QUnit.module("Textures", () -> {
      QUnit.module("CanvasTexture", () -> {
        // INHERITANCE
        QUnit.test("Extending", assert -> {
          var object = new CanvasTexture();
          assert.strictEqual(Std.is(object, Texture), true, "CanvasTexture extends from Texture");
        });

        // INSTANCING
        QUnit.test("Instancing", assert -> {
          var object = new CanvasTexture();
          assert.ok(object, "Can instantiate a CanvasTexture.");
        });

        // PUBLIC
        QUnit.test("isCanvasTexture", assert -> {
          var object = new CanvasTexture();
          assert.ok(object.isCanvasTexture, "CanvasTexture.isCanvasTexture should be true");
        });
      });
    });
  }
}

new CanvasTextureTests();