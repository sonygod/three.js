package three.js.test.unit.src.loaders;

import three.js.src.loaders.ImageBitmapLoader;
import three.js.src.loaders.Loader;
import three.js.utils.console_wrapper.CONSOLE_LEVEL;

class ImageBitmapLoaderTest {

    public static function main() {
        var module = new Module();
        module.run();
    }
}

class Module {
    public function run() {
        var module = new Module2();
        module.run();
    }
}

class Module2 {
    public function run() {
        var test = new Test();
        test.run();
    }
}

class Test {
    public function run() {
        // INHERITANCE
        this.testExtending();

        // INSTANCING
        this.testInstancing();

        // PROPERTIES
        this.testOptions();

        // PUBLIC
        this.testIsImageBitmapLoader();

        // TODO
        this.testSetOptions();
        this.testLoad();
    }

    private function testExtending() {
        // surpress the following console message when testing
        // THREE.ImageBitmapLoader: createImageBitmap() not supported.

        // Haxe 中没有直接的 console.level 设置，我们可以使用 trace 函数来模拟类似的行为
        // trace(CONSOLE_LEVEL.OFF, "");
        var object = new ImageBitmapLoader();
        // trace(CONSOLE_LEVEL.DEFAULT, "");

        unittest.Assert.isTrue(object instanceof Loader, "ImageBitmapLoader extends from Loader");
    }

    private function testInstancing() {
        // surpress the following console message when testing
        // THREE.ImageBitmapLoader: createImageBitmap() not supported.

        // trace(CONSOLE_LEVEL.OFF, "");
        var object = new ImageBitmapLoader();
        // trace(CONSOLE_LEVEL.DEFAULT, "");

        unittest.Assert.isNotNull(object, "Can instantiate an ImageBitmapLoader.");
    }

    private function testOptions() {
        // surpress the following console message when testing in node
        // THREE.ImageBitmapLoader: createImageBitmap() not supported.

        // trace(CONSOLE_LEVEL.OFF, "");
        var actual = new ImageBitmapLoader().options;
        // trace(CONSOLE_LEVEL.DEFAULT, "");

        var expected = { premultiplyAlpha: 'none' };
        unittest.Assert.isTrue(actual == expected, "ImageBitmapLoader defines options.");
    }

    private function testIsImageBitmapLoader() {
        // surpress the following console message when testing in node
        // THREE.ImageBitmapLoader: createImageBitmap() not supported.

        // trace(CONSOLE_LEVEL.OFF, "");
        var object = new ImageBitmapLoader();
        // trace(CONSOLE_LEVEL.DEFAULT, "");

        unittest.Assert.isTrue(object.isImageBitmapLoader, "ImageBitmapLoader.isImageBitmapLoader should be true");
    }

    private function testSetOptions() {
        // setOptions( options )
        unittest.Assert.isTrue(false, "everything's gonna be alright");
    }

    private function testLoad() {
        // load( url, onLoad, onProgress, onError )
        unittest.Assert.isTrue(false, "everything's gonna be alright");
    }
}