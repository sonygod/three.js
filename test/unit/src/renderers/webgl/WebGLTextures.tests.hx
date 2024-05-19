package three.test.unit.src.renderers.webgl;

import three.renderers.webgl.WebGLTextures;

class WebGLTexturesTest {
    public function new() {}

    public static function main() {
        QUnit.module("Renderers", () -> {
            QUnit.module("WebGL", () -> {
                QUnit.module("WebGLTextures", () -> {
                    // INSTANCING
                    QUnit.todo("Instancing", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    // PUBLIC STUFF
                    QUnit.todo("setTexture2D", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });
                    QUnit.todo("setTextureCube", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });
                    QUnit.todo("setTextureCubeDynamic", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });
                    QUnit.todo("setupRenderTarget", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });
                    QUnit.todo("updateRenderTargetMipmap", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });
                });
            });
        });
    }
}