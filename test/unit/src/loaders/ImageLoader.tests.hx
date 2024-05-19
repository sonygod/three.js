package three.test.unit.src.loaders;

import haxe.unit.TestCase;
import three.loaders.ImageLoader;
import three.loaders.Loader;

class ImageLoaderTest {

    public function new() {}

    @Test
    public function testExtending() {
        var object = new ImageLoader();
        assertTrue(object instanceof Loader, 'ImageLoader extends from Loader');
    }

    @Test
    public function testInstancing() {
        var object = new ImageLoader();
        assertNotNull(object, 'Can instantiate an ImageLoader.');
    }

    @Test
    public function testLoad() {
        // todo: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }
}