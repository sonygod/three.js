import qunit.QUnit;
import three.textures.DepthTexture;
import three.textures.Texture;

class TexturesTest extends qunit.Test {
  public function new() {
    super();
    QUnit.module("Textures", this.texturesModule);
  }

  function texturesModule() {
    QUnit.module("DepthTexture", this.depthTextureModule);
  }

  function depthTextureModule() {
    // INHERITANCE
    QUnit.test("Extending", function(assert) {
      var object = new DepthTexture();
      assert.strictEqual(object.is(Texture), true, "DepthTexture extends from Texture");
    });

    // INSTANCING
    QUnit.test("Instancing", function(assert) {
      var object = new DepthTexture();
      assert.ok(object, "Can instantiate a DepthTexture.");
    });

    // PROPERTIES
    QUnit.todo("image", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("magFilter", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("minFilter", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("flipY", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    QUnit.todo("generateMipmaps", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    // PUBLIC
    QUnit.test("isDepthTexture", function(assert) {
      var object = new DepthTexture();
      assert.ok(object.isDepthTexture, "DepthTexture.isDepthTexture should be true");
    });
  }
}

var test = new TexturesTest();