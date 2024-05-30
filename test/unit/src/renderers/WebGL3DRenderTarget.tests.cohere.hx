import js.QUnit;

import openfl.display3D.textures.WebGL3DRenderTarget;
import openfl.display3D.textures.WebGLRenderTarget;

class TestWebGL3DRenderTarget {
    public static function main() {
        QUnit.module( "Renderers", function() {
            QUnit.module( "WebGL3DRenderTarget", function() {
                // INHERITANCE
                QUnit.test("Extending", function(assert) {
                    var object = new WebGL3DRenderTarget();
                    assert.strictEqual(
                        Std.is(object, WebGLRenderTarget),
                        true,
                        "WebGL3DRenderTarget extends from WebGLRenderTarget"
                    );
                });

                // INSTANCING
                QUnit.test("Instancing", function(assert) {
                    var object = new WebGL3DRenderTarget();
                    assert.ok(object, "Can instantiate a WebGL3DRenderTarget.");
                });

                // PROPERTIES
                QUnit.todo("depth", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("texture", function(assert) {
                    // must be Data3DTexture
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.todo("isWebGL3DRenderTarget", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}

TestWebGL3DRenderTarget.main();