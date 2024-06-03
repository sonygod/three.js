import js.Browser.document;
import threejs.loaders.DataTextureLoader;
import threejs.loaders.Loader;

class DataTextureLoaderTests {
    public static function main() {
        testExtending();
        testInstancing();
    }

    private static function testExtending() {
        var object = new DataTextureLoader();
        if(Std.is(object, Loader)) {
            js.Browser.window.console.log("DataTextureLoader extends from Loader");
        } else {
            js.Browser.window.console.log("DataTextureLoader does not extend from Loader");
        }
    }

    private static function testInstancing() {
        var object = new DataTextureLoader();
        if(object != null) {
            js.Browser.window.console.log("Can instantiate a DataTextureLoader.");
        } else {
            js.Browser.window.console.log("Cannot instantiate a DataTextureLoader.");
        }
    }
}