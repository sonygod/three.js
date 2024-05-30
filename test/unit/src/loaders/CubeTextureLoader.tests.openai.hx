import haxe.unit.TestCase;

import loaders.CubeTextureLoader;
import loaders.Loader;

class CubeTextureLoaderTests {
    public function new() {}

    public function testExtending():Void {
        var object:CubeTextureLoader = new CubeTextureLoader();
        assertTrue(object instanceof Loader, 'CubeTextureLoader extends from Loader');
    }

    public function testInstancing():Void {
        var object:CubeTextureLoader = new CubeTextureLoader();
        assertNotNull(object, 'Can instantiate a CubeTextureLoader.');
    }

    // Note: Todo test is not a built-in concept in Haxe's unit testing framework
    // You may use a testing framework like MUnit or Minject to achieve similar functionality
    // For the sake of demonstration, I'll leave the test as is
    public function testLoad():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }
}