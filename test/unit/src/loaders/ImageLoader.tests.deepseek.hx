package three.js.test.unit.src.loaders;

import three.js.src.loaders.ImageLoader;
import three.js.src.loaders.Loader;

class ImageLoaderTests {

    static function main() {
        // INHERITANCE
        var object = new ImageLoader();
        unittest.assert(object instanceof Loader);

        // INSTANCING
        var object = new ImageLoader();
        unittest.assert(object != null);

        // PUBLIC
        unittest.todo("load");
    }
}