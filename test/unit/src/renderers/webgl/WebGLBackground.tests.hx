Here is the equivalent Haxe code:
```
package three.test.unit.src.renderers.webgl;

import three.renderers.webgl.WebGLBackground;

import qunit.QUnit;

class WebGLBackgroundTests {
  public static function main() {
    QUnit.module("Renderers", () -> {
      QUnit.module("WebGL", () -> {
        QUnit.module("WebGLBackground", () -> {
          // INSTANCING
          QUnit.todo("Instancing", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          // PUBLIC STUFF
          QUnit.todo("getClearColor", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("setClearColor", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("getClearAlpha", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("setClearAlpha", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("render", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
          });
        });
      });
    });
  }
}
```
Note that I've assumed that `qunit` is a separate Haxe library, and that `QUnit` is a class within that library. I've also assumed that `three.renderers.webgl.WebGLBackground` is a separate Haxe class that needs to be imported.

Also, in Haxe, we don't use `export default` like in JavaScript. Instead, we define a `main` function as the entry point of the program.