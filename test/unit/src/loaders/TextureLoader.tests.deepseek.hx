package three.js.test.unit.src.loaders;

import three.js.src.loaders.TextureLoader;
import three.js.src.loaders.Loader;

class TextureLoaderTests {

    public static function main() {
        // INHERITANCE
        var object = new TextureLoader();
        unittest.assert(object instanceof Loader);

        // INSTANCING
        var object = new TextureLoader();
        unittest.assert(object != null);

        // PUBLIC
        unittest.todo("load");
    }
}