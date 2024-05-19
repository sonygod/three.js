package three.test.unit.src.loaders;

import haxe.unit.TestCase;
import three.loaders.AnimationLoader;
import three.loaders.Loader;

class AnimationLoaderTest {
    public function new() {}

    public function testExtending() {
        var object:AnimationLoader = new AnimationLoader();
        assertTrue(object instanceof Loader, 'AnimationLoader extends from Loader');
    }

    public function testInstancing() {
        var object:AnimationLoader = new AnimationLoader();
        assertNotNull(object, 'Can instantiate an AnimationLoader.');
    }

    public function testLoad() {
        // todo: implement me
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testParse() {
        // todo: implement me
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public static function main() {
        var testCase:AnimationLoaderTest = new AnimationLoaderTest();
        testCase.testExtending();
        testCase.testInstancing();
        testCase.testLoad();
        testCase.testParse();
    }
}