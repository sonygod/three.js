package three.test.unit.src.loaders;

import haxe.unit.TestCase;
import three.loaders.AudioLoader;
import three.loaders.Loader;

class AudioLoaderTests {

    public function new() {}

    public function testExtending() {
        var object = new AudioLoader();
        assertTrue(object instanceof Loader, 'AudioLoader extends from Loader');
    }

    public function testInstancing() {
        var object = new AudioLoader();
        assertNotNull(object, 'Can instantiate an AudioLoader.');
    }

    public function testLoad() {
        // todo: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

}