import js.Browser.document;
import js.Browser.window;

class WebGLClippingTests {
    public static function main() {
        // Create a div for QUnit
        var qunitDiv = document.createElement("div");
        qunitDiv.id = "qunit-fixture";
        document.body.appendChild(qunitDiv);

        // Import QUnit
        var QUnit = window.QUnit;

        QUnit.module("Renderers", () => {
            QUnit.module("WebGL", () => {
                QUnit.module("WebGLClipping", () => {
                    // INSTANCING
                    QUnit.test("Instancing", (assert) => {
                        assert.expect(1);
                        assert.ok(false, "everything's gonna be alright");
                    });

                    // PUBLIC STUFF
                    QUnit.test("init", (assert) => {
                        assert.expect(1);
                        assert.ok(false, "everything's gonna be alright");
                    });

                    QUnit.test("beginShadows", (assert) => {
                        assert.expect(1);
                        assert.ok(false, "everything's gonna be alright");
                    });

                    QUnit.test("endShadows", (assert) => {
                        assert.expect(1);
                        assert.ok(false, "everything's gonna be alright");
                    });

                    QUnit.test("setState", (assert) => {
                        assert.expect(1);
                        assert.ok(false, "everything's gonna be alright");
                    });
                });
            });
        });
    }
}