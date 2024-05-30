package three.test.unit.src.renderers;

import three.renderers.WebGLRenderer;

class WebGLRendererTest {
  public function new() {}

  public static function main() {
    QUnit.module("Renderers", () -> {
      QUnit.module("WebGLRenderer-webonly", () -> {
        // INSTANCING
        QUnit.test("Instancing", (assert) -> {
          var renderer = new WebGLRenderer();
          assert.ok(renderer, "Can instantiate a WebGLRenderer.");
        });

        // PROPERTIES
        QUnit.todo("domElement", (assert) -> {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("debug", (assert) -> {
          assert.ok(false, "everything's gonna be alright");
        });

        // ... (rest of the todo tests)

        QUnit.test("dispose", (assert) -> {
          assert.expect(0);
          var object = new WebGLRenderer();
          object.dispose();
        });

        // ... (rest of the todo tests)
      });
    });
  }
}