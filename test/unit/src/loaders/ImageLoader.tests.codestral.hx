import three.loaders.ImageLoader;
import three.loaders.Loader;

class ImageLoaderTests {
    public static function main() {
        testExtending();
        testInstancing();
        // TODO: Implement load test
    }

    private static function testExtending() {
        var object:ImageLoader = new ImageLoader();
        if (Std.is(object, Loader)) {
            console.log("ImageLoader extends from Loader");
        } else {
            console.log("ImageLoader does not extend from Loader");
        }
    }

    private static function testInstancing() {
        var object:ImageLoader = new ImageLoader();
        if (object != null) {
            console.log("Can instantiate an ImageLoader.");
        } else {
            console.log("Cannot instantiate an ImageLoader.");
        }
    }
}