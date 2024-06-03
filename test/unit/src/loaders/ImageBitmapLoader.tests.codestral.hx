@:require("three.js/src/loaders/ImageBitmapLoader.hx")
@:require("three.js/src/loaders/Loader.hx")
@:require("three.js/utils/console-wrapper.hx")

class ImageBitmapLoaderTests {
    public function new() {
        // Test for extending
        var object = new three.ImageBitmapLoader();
        if (!(object is three.Loader)) {
            throw "ImageBitmapLoader does not extend from Loader";
        }

        // Test for instancing
        object = new three.ImageBitmapLoader();
        if (object == null) {
            throw "Cannot instantiate an ImageBitmapLoader";
        }

        // Test for options
        var actual = new three.ImageBitmapLoader().options;
        var expected = { premultiplyAlpha: "none" };
        if (!deepEqual(actual, expected)) {
            throw "ImageBitmapLoader does not define options correctly";
        }

        // Test for isImageBitmapLoader
        object = new three.ImageBitmapLoader();
        if (!object.isImageBitmapLoader) {
            throw "ImageBitmapLoader.isImageBitmapLoader should be true";
        }
    }

    private function deepEqual(a:Dynamic, b:Dynamic):Bool {
        // Implement your own deepEqual function here or use a library
        // This function is used to compare two objects for equality
        return false;
    }
}