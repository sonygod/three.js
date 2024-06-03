import qunit.QUnit;

class WebGLShaderTests {
    public static function main() {
        QUnit.module("Renderers", () -> {
            QUnit.module("WebGL", () -> {
                QUnit.module("WebGLShader", () -> {
                    // INSTANCING
                    QUnit.todo("Instancing", (assert: QUnit.Assert) -> {
                        assert.ok(false, "everything's gonna be alright");
                    });
                });
            });
        });
    }
}