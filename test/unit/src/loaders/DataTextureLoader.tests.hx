package three.test.unit.src.loaders;

import three.loaders.DataTextureLoader;
import three.loaders.Loader;

class DataTextureLoaderTests {

    public function new() {}

    public function testExtending(assert:Assertion) {
        var object = new DataTextureLoader();
        assertTrue(object instanceof Loader, 'DataTextureLoader extends from Loader');
    }

    public function testInstancing(assert:Assertion) {
        var object = new DataTextureLoader();
        assertTrue(object != null, 'Can instantiate a DataTextureLoader.');
    }

    public function testLoad(assert:Assertion) {
        // todo: implement me!
        assertTrue(false, "everything's gonna be alright");
    }
}