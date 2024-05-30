import haxe.unit.TestCase;
import three.loaders.AudioLoader;
import three.loaders.Loader;

class AudioLoaderTests {
    public function new() {}

    public function testExtending():Void {
        var object:AudioLoader = new AudioLoader();
        assertTrue(object instanceof Loader, 'AudioLoader extends from Loader');
    }

    public function testInstancing():Void {
        var object:AudioLoader = new AudioLoader();
        assertNotNull(object, 'Can instantiate an AudioLoader.');
    }

    public function testLoad():Void {
        // TODO: implement this test
        assertFalse(true, 'everything\'s gonna be alright');
    }
}