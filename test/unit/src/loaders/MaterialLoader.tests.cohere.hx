import haxe.unit.TestCase;
import haxe.unit.Test;
import js.Browser;

import loaders.MaterialLoader;
import loaders.Loader;

class TestMaterialLoader extends TestCase {
    function testExtending() {
        var object = new MaterialLoader();
        var expected = new Loader();
        this.assertTrue(Std.is(object, Loader));
    }

    function testTextures() {
        var actual = new MaterialLoader().textures;
        var expected = cast({});
        this.assertEquals(actual, expected);
    }

    function testInstancing() {
        var object = new MaterialLoader();
        this.assertNotNull(object);
    }

    function testLoad() {
        // TODO: Implement test.
    }

    function testParse() {
        // TODO: Implement test.
    }

    function testSetTextures() {
        // TODO: Implement test.
    }

    static function createMaterialFromType(type) {
        // TODO: Implement test.
    }
}

class TestMain {
    static function main() {
        #if js
            Browser.main();
        #end

        Test.runWithExitStatus(TestMaterialLoader);
    }
}