import js.QUnit;

import js.CompressedArrayTexture from "../../../../src/textures/CompressedArrayTexture.js";
import js.CompressedTexture from "../../../../src/textures/CompressedTexture.js";

class Test {
    static function main() {
        QUnit.module("Textures", {
            beforeEach: function() {},
            afterEach: function() {}
        });

        QUnit.module("CompressedArrayTexture", {
            beforeEach: function() {},
            afterEach: function() {}
        });

        // INHERITANCE
        QUnit.test("Extending", function(assert) {
            var object = new CompressedArrayTexture();
            assert.strictEqual(
                Std.is(object, CompressedTexture),
                true,
                "CompressedArrayTexture extends from CompressedTexture"
            );
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
            var object = new CompressedArrayTexture();
            assert.ok(object, "Can instantiate a CompressedArrayTexture.");
        });

        // PROPERTIES
        QUnit.todo("image.depth", function(assert) {
            // { width: width, height: height, depth: depth }
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("wrapR", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test("isCompressedArrayTexture", function(assert) {
            var object = new CompressedArrayTexture();
            assert.ok(
                object.isCompressedArrayTexture,
                "CompressedArrayTexture.isCompressedArrayTexture should be true"
            );
        });
    }
}

Test.main();