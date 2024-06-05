import qunit.QUnit;
import three.textures.Data3DTexture;
import three.textures.Texture;

class TexturesTest extends QUnit {
  static function main() {
    new TexturesTest().run();
  }

  function run() {
    module("Textures", () => {
      module("Data3DTexture", () => {
        test("Extending", (assert) => {
          var object = new Data3DTexture();
          assert.ok(Std.is(object, Texture), "Data3DTexture extends from Texture");
        });

        test("Instancing", (assert) => {
          var object = new Data3DTexture();
          assert.ok(object, "Can instantiate a Data3DTexture.");
        });

        todo("image", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        todo("magFilter", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        todo("minFilter", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        todo("wrapR", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        todo("generateMipmaps", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        todo("flipY", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        todo("unpackAlignment", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        test("isData3DTexture", (assert) => {
          var object = new Data3DTexture();
          assert.ok(
            object.isData3DTexture,
            "Data3DTexture.isData3DTexture should be true"
          );
        });
      });
    });
  }
}

class todo {
  public function new(f:Dynamic->Void) {
  }
}

class module {
  public function new(name:String, f:Dynamic->Void) {
  }
}

class test {
  public function new(name:String, f:Dynamic->Void) {
  }
}

class assert {
  public function ok(value:Bool, message:String) {
  }

  public function strictEqual(value:Dynamic, expected:Dynamic, message:String) {
  }
}

class Std {
  static function is(v:Dynamic, t:Dynamic):Bool {
    return false;
  }
}

TexturesTest.main();