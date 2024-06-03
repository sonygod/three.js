import qunit.QUnit;

class WebGLTexturesTests {
    public function new() {
        QUnit.module("Renderers", () -> {
            QUnit.module("WebGL", () -> {
                QUnit.module("WebGLTextures", () -> {
                    QUnit.todo("Instancing", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });

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

new WebGLTexturesTests();