import qunit.QUnit;

class WebGLBufferRendererTests {
    public static function main() {
        var module = QUnit.module("Renderers", () -> {
            var webglModule = QUnit.module("WebGL", () -> {
                var webglBufferRendererModule = QUnit.module("WebGLBufferRenderer", () -> {
                    QUnit.todo("Instancing", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    QUnit.todo("setMode", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    QUnit.todo("render", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    QUnit.todo("renderInstances", (assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });
                });
            });
        });
    }
}