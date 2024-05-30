import js.QUnit;
import js.d.loaders.AudioLoader;
import js.d.loaders.Loader;

class AudioLoaderTest {
    static function extending() {
        var object = new AudioLoader();
        var isInstanceOfLoader = Type.getInstanceFields(object) instanceof Loader;
        trace(isInstanceOfLoader);
    }

    static function instancing() {
        var object = new AudioLoader();
        trace(object != null);
    }

    static function load() {
        // TODO: Implement load test
    }
}

class Loaders {
    static function run() {
        QUnit.module('Loaders', function () {
            QUnit.module('AudioLoader', function () {
                QUnit.test('Extending', AudioLoaderTest.extending);
                QUnit.test('Instancing', AudioLoaderTest.instancing);
                QUnit.todo('load', AudioLoaderTest.load);
            });
        });
    }
}

// Run the tests
Loaders.run();