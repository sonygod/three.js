import js.Browser.document;
import three.src.textures.CubeTexture;
import three.src.textures.Texture;
import qunit.QUnit;

class CubeTextureTests {
    public function new() {}

    @:jsRequire("three.js/test/unit/src/textures/CubeTexture.tests.js")
    public static function main() {
        QUnit.module("Textures", () -> {
            QUnit.module("CubeTexture", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object:CubeTexture = new CubeTexture();
                    assert.strictEqual(Std.is(object, Texture), true, 'CubeTexture extends from Texture');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object:CubeTexture = new CubeTexture();
                    assert.ok(object != null, 'Can instantiate a CubeTexture.');
                });

                // PUBLIC
                QUnit.test("isCubeTexture", (assert) -> {
                    var object:CubeTexture = new CubeTexture();
                    assert.ok(object.isCubeTexture, 'CubeTexture.isCubeTexture should be true');
                });
            });
        });
    }
}