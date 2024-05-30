package three.js.test.unit.src.loaders;

import three.js.src.loaders.AnimationLoader;
import three.js.src.loaders.Loader;

class AnimationLoaderTests {

    static function main() {
        // INHERITANCE
        var object = new AnimationLoader();
        unittest.assert(object instanceof Loader);

        // INSTANCING
        var object = new AnimationLoader();
        unittest.assert(object != null);

        // PUBLIC
        unittest.todo("load");
        unittest.todo("parse");
    }
}