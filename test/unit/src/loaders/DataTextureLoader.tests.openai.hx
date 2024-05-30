import haxe.unit.TestCase;
import three.loaders.DataTextureLoader;
import three.loaders.Loader;

class DataTextureLoaderTests {

    public function new() {}

    public function testExtending() {
        var object = new DataTextureLoader();
        assertTrue(object instanceof Loader, 'DataTextureLoader extends from Loader');
    }

    public function testInstancing() {
        var object = new DataTextureLoader();
        assertNotNull(object, 'Can instantiate a DataTextureLoader.');
    }

    public function testLoad() {
        // TODO: implement me!
        fail("not implemented");
    }
}