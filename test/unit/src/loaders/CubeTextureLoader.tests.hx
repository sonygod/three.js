import haxe.unit.TestCase;
import three.loaders.CubeTextureLoader;
import three.loaders.Loader;

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

    public function testLoad():Void {
        // todo: implement me
        assertTrue(false, "everything's gonna be alright");
    }

    public static function main() {
        var testCase:TestCase = new CubeTextureLoaderTests();
        testCase.testExtending();
        testCase.testInstancing();
        testCase.testLoad();
    }
}