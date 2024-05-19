Here is the equivalent Haxe code for the given JavaScript code:
```
package three.test.unit.src.renderers.webgl;

import js.QUnit;

class WebGLCapabilitiesTests {
  public function new() {}

  public static function main() {
    QUnit.module("Renderers", () -> {
      QUnit.module("WebGL", () -> {
        QUnit.module("WebGLCapabilities", () -> {
          // INSTANCING
          QUnit.todo("Instancing", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          // PUBLIC STUFF
          QUnit.todo("getMaxAnisotropy", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("getMaxPrecision", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("precision", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("logarithmicDepthBuffer", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("maxTextures", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("maxVertexTextures", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("maxTextureSize", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("maxCubemapSize", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("maxAttributes", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("maxVertexUniforms", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("maxVaryings", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("maxFragmentUniforms", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("vertexTextures", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("floatFragmentTextures", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("floatVertexTextures", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });
        });
      });
    });
  }
}
```
Note that I've assumed that the `QUnit` module is already imported and available in Haxe. If that's not the case, you'll need to add the necessary imports or setup to make `QUnit` available in your Haxe project.