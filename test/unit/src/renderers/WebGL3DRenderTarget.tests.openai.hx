import three.WebGL3DRenderTarget;
import three.WebGLRenderTarget;
import.unitest.QUnit;

class WebGL3DRenderTargetTests {
  public static function main() {
    QUnit.module("Renderers", () => {
      QUnit.module("WebGL3DRenderTarget", () => {
        // INHERITANCE
        QUnit.test("Extending", (assert) => {
          var object = new WebGL3DRenderTarget();
          assert.isTrue(object instanceof WebGLRenderTarget, "WebGL3DRenderTarget extends from WebGLRenderTarget");
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) => {
          var object = new WebGL3DRenderTarget();
          assert.notNull(object, "Can instantiate a WebGL3DRenderTarget.");
        });

        // PROPERTIES
        QUnit.todo("depth", (assert) => {
          assert.fail("not implemented");
        });

        QUnit.todo("texture", (assert) => {
          // must be Data3DTexture
          assert.fail("not implemented");
        });

        // PUBLIC
        QUnit.todo("isWebGL3DRenderTarget", (assert) => {
          assert.fail("not implemented");
        });
      });
    });
  }
}