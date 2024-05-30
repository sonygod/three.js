import js.QUnit;
import js.html.Image;

import openfl.display.Loader;
import openfl.display.ImageLoader;

class ImageLoaderTest {
    static function extending() {
        var object = new ImageLoader();
        var result = (Std.is(object, Loader));
        trace(result);
        QUnit.strictEqual(result, true);
    }

    static function instancing() {
        var object = new ImageLoader();
        QUnit.ok(object, 'Can instantiate an ImageLoader.');
    }

    static function load() {
        // TODO: Implement test for load method
    }
}

class ImageLoaderModule {
    static function runTests() {
        QUnit.module('Loaders', function () {
            QUnit.module('ImageLoader', function () {
                ImageLoaderTest.extending();
                ImageLoaderTest.instancing();
                ImageLoaderTest.load();
            });
        });
    }
}

ImageLoaderModule.runTests();