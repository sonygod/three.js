package three.test.unit.src.loaders;

import three.loaders.ImageBitmapLoader;
import three.loaders.Loader;
import utils.ConsoleWrapper;

class ImageBitmapLoaderTests {
    public function new() {}

    public static function main() {
        TestRunner.runTests([
            new TestRunner.Test("Loaders", [
                new TestRunner.Test("ImageBitmapLoader", [
                    new TestRunner.Test("Extending", testExtending),
                    new TestRunner.Test("Instancing", testInstancing),
                    new TestRunner.Test("options", testOptions),
                    new TestRunner.Test("isImageBitmapLoader", testIsImageBitmapLoader),
                    new TestRunner.Test("setOptions", testSetOptions),
                    new TestRunner.Test("load", testLoad)
                ])
            ])
        ]);
    }

    private static function testExtending(assert: Assert):Void {
        ConsoleWrapper.setLevel(ConsoleWrapper.LEVEL_OFF);
        var object = new ImageBitmapLoader();
        ConsoleWrapper.setLevel(ConsoleWrapper.LEVEL_DEFAULT);
        assert.isTrue(object instanceof Loader, 'ImageBitmapLoader extends from Loader');
    }

    private static function testInstancing(assert: Assert):Void {
        ConsoleWrapper.setLevel(ConsoleWrapper.LEVEL_OFF);
        var object = new ImageBitmapLoader();
        ConsoleWrapper.setLevel(ConsoleWrapper.LEVEL_DEFAULT);
        assert.ok(object, 'Can instantiate an ImageBitmapLoader.');
    }

    private static function testOptions(assert: Assert):Void {
        ConsoleWrapper.setLevel(ConsoleWrapper.LEVEL_OFF);
        var actual = new ImageBitmapLoader().options;
        ConsoleWrapper.setLevel(ConsoleWrapper.LEVEL_DEFAULT);
        var expected = { premultiplyAlpha: 'none' };
        assert.deepEqual(actual, expected, 'ImageBitmapLoader defines options.');
    }

    private static function testIsImageBitmapLoader(assert: Assert):Void {
        ConsoleWrapper.setLevel(ConsoleWrapper.LEVEL_OFF);
        var object = new ImageBitmapLoader();
        ConsoleWrapper.setLevel(ConsoleWrapper.LEVEL_DEFAULT);
        assert.ok(object.isImageBitmapLoader, 'ImageBitmapLoader.isImageBitmapLoader should be true');
    }

    private static function testSetOptions(assert: Assert):Void {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    private static function testLoad(assert: Assert):Void {
        assert.ok(false, 'everything\'s gonna be alright');
    }
}