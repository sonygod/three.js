import js.QUnit;

import openfl.loaders.CompressedTextureLoader;
import openfl.loaders.Loader;

class TestCompressedTextureLoader {
    static function main() {
        var module = QUnit.module("Loaders");
        module.module("CompressedTextureLoader", function() {
            module.test("Extending", function(assert) {
                var object = new CompressedTextureLoader();
                assert.strictEqual(Std.is(object, Loader), true, "CompressedTextureLoader extends from Loader");
            });

            module.test("Instancing", function(assert) {
                var object = new CompressedTextureLoader();
                assert.ok(object, "Can instantiate a CompressedTextureLoader.");
            });

            module.test("load", function(assert) {
                assert.ok(false, "TODO: Implement load test");
            });
        });
    }
}

TestCompressedTextureLoader.main();