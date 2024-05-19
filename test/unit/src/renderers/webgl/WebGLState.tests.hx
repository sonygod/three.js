Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.test.unit.src.renderers.webgl;

import js.Browser;
import QUnit;

class WebGLStateTests {
  public function new() {}

  public static function main() {
    QUnit.module("Renderers", () => {
      QUnit.module("WebGL", () => {
        QUnit.module("WebGLState", () => {
          // INSTANCING
          QUnit.todo("Instancing", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          // PUBLIC STUFF
          QUnit.todo("buffers", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("initAttributes", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("enableAttribute", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("enableAttributeAndDivisor", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("disableUnusedAttributes", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("enable", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("disable", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("getCompressedTextureFormats", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("useProgram", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("setBlending", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("setMaterial", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("setFlipSided", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("setCullFace", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("setLineWidth", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("setPolygonOffset", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("setScissorTest", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("activeTexture", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("bindTexture", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("compressedTexImage2D", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("texImage2D", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("scissor", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("viewport", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("reset", (assert) => {
            assert.ok(false, "everything's gonna be alright");
          });
        });
      });
    });
  }
}
```
Note that I've replaced the JavaScript module imports with Haxe imports, and converted the JavaScript code to Haxe syntax. I've also removed the `/* global QUnit */` comment, as it's not necessary in Haxe.