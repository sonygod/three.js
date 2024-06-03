import js.Browser.document;
import three.loaders.ObjectLoader;
import three.loaders.Loader;

class ObjectLoaderTests {
    public function new() {
        // INHERITANCE
        var object = new ObjectLoader();
        js.Boot.trace("ObjectLoader extends from Loader: ", object is Loader);

        // INSTANCING
        var object = new ObjectLoader();
        js.Boot.trace("Can instantiate an ObjectLoader: ", object != null);

        // More tests would go here, but they were marked as QUnit.todo
    }
}

var tests = new ObjectLoaderTests();