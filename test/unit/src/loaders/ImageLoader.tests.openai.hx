import loaders.ImageLoader;
import loaders.Loader;

class ImageLoaderTests {
    public static function main() {
        utest.run([
            new TestImageLoader(),
        ]);
    }
}

class TestImageLoader extends utest.Test {
    public function new() {
        super();
    }

    public function testExtending() {
        var object = new ImageLoader();
        assertTrue(object instanceof Loader, 'ImageLoader extends from Loader');
    }

    public function testInstancing() {
        var object = new ImageLoader();
        assertNotNull(object, 'Can instantiate an ImageLoader.');
    }

    public function testLoad() {
        // TODO: implement test
        assertTrue(false, "everything's gonna be alright");
    }
}