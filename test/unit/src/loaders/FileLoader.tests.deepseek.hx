package three.js.test.unit.src.loaders;

import three.js.src.loaders.FileLoader;
import three.js.src.loaders.Loader;

class FileLoaderTests {

    static function main() {
        // INHERITANCE
        var object = new FileLoader();
        unittest.assertTrue(object instanceof Loader, 'FileLoader extends from Loader');

        // INSTANCING
        var object = new FileLoader();
        unittest.assertNotNull(object, 'Can instantiate a FileLoader.');

        // PUBLIC
        unittest.todo('load', 'everything\'s gonna be alright');
        unittest.todo('setResponseType', 'everything\'s gonna be alright');
        unittest.todo('setMimeType', 'everything\'s gonna be alright');
    }
}