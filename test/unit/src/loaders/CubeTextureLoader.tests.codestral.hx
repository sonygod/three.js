import qunit.QUnit;
import three.loaders.CubeTextureLoader;
import three.loaders.Loader;

class CubeTextureLoaderTests {
    public static function main() {
        QUnit.module("Loaders", () -> {
            QUnit.module("CubeTextureLoader", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object:CubeTextureLoader = new CubeTextureLoader();
                    assert.strictEqual(Std.is(object, Loader), true, "CubeTextureLoader extends from Loader");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object:CubeTextureLoader = new CubeTextureLoader();
                    assert.ok(object != null, "Can instantiate a CubeTextureLoader.");
                });

                // PUBLIC
                QUnit.todo("load", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}