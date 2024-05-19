package three.test.unit.src.loaders;

import three.loaders.TextureLoader;
import three.loaders.Loader;

class TextureLoaderTests {
    public function new() {}

    public static function main() {
        // INHERITANCE
        TesterSuite.addTest("TextureLoader extends from Loader", function(assert: Assert) {
            var object:TextureLoader = new TextureLoader();
            assert.isTrue(object instanceof Loader, "TextureLoader extends from Loader");
        });

        // INSTANCING
        TesterSuite.addTest("Can instantiate a TextureLoader", function(assert: Assert) {
            var object:TextureLoader = new TextureLoader();
            assert.isTrue(object != null, "Can instantiate a TextureLoader.");
        });

        // PUBLIC
        TesterSuite.addTest("load", function(assert: Assert) {
            assert.fail("everything's gonna be alright");
        });
    }
}