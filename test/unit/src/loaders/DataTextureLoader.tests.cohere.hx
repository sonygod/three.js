import js.QUnit;
import js.d.loaders.DataTextureLoader;
import js.d.loaders.Loader;

class DataTextureLoaderTest {
    static function extending() {
        var object = new DataTextureLoader();
        var isInstanceOfLoader = object instanceof Loader;
        trace(isInstanceOfLoader);
        QUnit.strictEqual(isInstanceOfLoader, true);
    }

    static function instancing() {
        var object = new DataTextureLoader();
        QUnit.ok(object, 'Can instantiate a DataTextureLoader.');
    }

    static function load() {
        // TODO: Implement load test
    }
}

class Loaders {
    static function run() {
        QUnit.module('Loaders', function () {
            QUnit.module('DataTextureLoader', function () {
                DataTextureLoaderTest.extending();
                DataTextureLoaderTest.instancing();
                DataTextureLoaderTest.load();
            });
        });
    }
}

// Run the tests
Loaders.run();