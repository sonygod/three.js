package three.test.unit.src.loaders;

import three.loaders.CompressedTextureLoader;
import three.loaders.Loader;

class CompressedTextureLoaderTests {
    public function new() {}

    public static function main():Void {
        QUnit.module("Loaders", () -> {
            QUnit.module("CompressedTextureLoader", () -> {
                QUnit.test("Extending", (assert:QUnitAssert) -> {
                    var object:CompressedTextureLoader = new CompressedTextureLoader();
                    assert.ok(object instanceof Loader, "CompressedTextureLoader extends from Loader");
                });

                QUnit.test("Instancing", (assert:QUnitAssert) -> {
                    var object:CompressedTextureLoader = new CompressedTextureLoader();
                    assert.ok(object != null, "Can instantiate a CompressedTextureLoader.");
                });

                QUnit.todo("load", (assert:QUnitAssert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}