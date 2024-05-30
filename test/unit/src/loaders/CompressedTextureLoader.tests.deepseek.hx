package three.js.test.unit.src.loaders;

import three.js.src.loaders.CompressedTextureLoader;
import three.js.src.loaders.Loader;

class CompressedTextureLoaderTests {

    public static function main() {
        // INHERITANCE
        var object = new CompressedTextureLoader();
        unittest.assertTrue(object instanceof Loader, "CompressedTextureLoader extends from Loader");

        // INSTANCING
        var object = new CompressedTextureLoader();
        unittest.assertNotNull(object, "Can instantiate a CompressedTextureLoader.");

        // PUBLIC
        unittest.todo("load", "everything's gonna be alright");
    }
}