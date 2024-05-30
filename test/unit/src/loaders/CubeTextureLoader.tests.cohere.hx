import js.npm.three.CubeTextureLoader;
import js.npm.three.Loader;

class CubeTextureLoaderTest {
    static function extending() {
        var object = new CubeTextureLoader();
        trace(Std.is(object, Loader)); // Should print true
    }

    static function instancing() {
        var object = new CubeTextureLoader();
        trace(object != null); // Should print true
    }

    static function load() {
        // TODO: Implement load test
    }
}