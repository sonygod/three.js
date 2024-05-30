package three.js.test.unit.src.textures;

import three.js.src.textures.CompressedArrayTexture;
import three.js.src.textures.CompressedTexture;

class CompressedArrayTextureTest {

    static function main() {
        var module = new QUnit.Module("Textures");
        module.module("CompressedArrayTexture");

        // INHERITANCE
        var test = new QUnit.Test("Extending");
        test.assertTrue(
            new CompressedArrayTexture() instanceof CompressedTexture,
            'CompressedArrayTexture extends from CompressedTexture'
        );

        // INSTANCING
        test = new QUnit.Test("Instancing");
        test.assertNotNull(
            new CompressedArrayTexture(),
            'Can instantiate a CompressedArrayTexture.'
        );

        // PROPERTIES
        test = new QUnit.Test("image.depth");
        test.assertTrue(false, 'everything\'s gonna be alright');

        test = new QUnit.Test("wrapR");
        test.assertTrue(false, 'everything\'s gonna be alright');

        // PUBLIC
        test = new QUnit.Test("isCompressedArrayTexture");
        test.assertTrue(
            (new CompressedArrayTexture()).isCompressedArrayTexture,
            'CompressedArrayTexture.isCompressedArrayTexture should be true'
        );
    }
}