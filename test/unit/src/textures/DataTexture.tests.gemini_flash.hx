import js.html.Image;
import js.html.Canvas;
import js.html.ImageData;
import js.html.CanvasRenderingContext2D;
import qunit.QUnit;

import three.textures.Texture;
import three.textures.DataTexture;

class DataTextureTest extends QUnit.Module {
  public function new() {
    super("Textures.DataTexture");
  }

  override function run(test:QUnit.Test) {
    test.module("DataTexture");

    // INHERITANCE
    test.test("Extending", (assert:QUnit.Assert) -> {
      var object = new DataTexture();
      assert.ok(object.isTexture, "DataTexture extends from Texture");
    });

    // INSTANCING
    test.test("Instancing", (assert:QUnit.Assert) -> {
      var object = new DataTexture();
      assert.ok(object, "Can instantiate a DataTexture.");
    });

    // PROPERTIES
    test.todo("image", (assert:QUnit.Assert) -> {
      assert.ok(false, "everything's gonna be alright");
    });

    test.todo("generateMipmaps", (assert:QUnit.Assert) -> {
      assert.ok(false, "everything's gonna be alright");
    });

    test.todo("flipY", (assert:QUnit.Assert) -> {
      assert.ok(false, "everything's gonna be alright");
    });

    test.todo("unpackAlignment", (assert:QUnit.Assert) -> {
      assert.ok(false, "everything's gonna be alright");
    });

    // PUBLIC
    test.test("isDataTexture", (assert:QUnit.Assert) -> {
      var object = new DataTexture();
      assert.ok(object.isDataTexture, "DataTexture.isDataTexture should be true");
    });
  }
}

var dataTextureTest = new DataTextureTest();