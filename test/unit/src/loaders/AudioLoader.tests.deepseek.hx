package three.js.test.unit.src.loaders;

import three.js.src.loaders.AudioLoader;
import three.js.src.loaders.Loader;

class AudioLoaderTests {

    static function main() {
        // INHERITANCE
        var object = new AudioLoader();
        unittest.assert(object instanceof Loader);

        // INSTANCING
        var object = new AudioLoader();
        unittest.assert(object != null);

        // PUBLIC
        unittest.todo("load");
    }
}