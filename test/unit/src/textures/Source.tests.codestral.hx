import js.Browser.document;
import js.html.QUnit;
import js.html.QUnit.Assert;
import three.src.textures.Source;

class SourceTests {
    public function new() {
        QUnit.module("Textures", () -> {
            QUnit.module("Source", () -> {
                // INSTANCING
                QUnit.test("Instancing", (assert: Assert) -> {
                    var object = new Source();
                    assert.ok(object != null, "Can instantiate a Source.");
                });

                // PUBLIC
                QUnit.test("isSource", (assert: Assert) -> {
                    var object = new Source();
                    assert.ok(object.isSource, "Source.isSource should be true");
                });
            });
        });
    }
}