import haxe.unit.TestCase;
import haxe.unit.Test;
import js.Browser;

class TestLoader extends TestCase {
    function new() {
        super();
    }

    static function __init__() {
        var t = new TestLoader();
        #if js
            t.ignore = true;
        #end
        Test.add(t);
    }

    public function testInstancing() {
        var loader = new js.loaders.Loader();
        var manager = new js.loaders.LoadingManager();
        var crossOrigin = "anonymous";
        var withCredentials = false;
        var path = "";
        var resourcePath = "";
        var requestHeader = {};

        this->assertTrue(loader != null, "Can instantiate a Loader.");
    }

    public function testManager() {
        var loader = new js.loaders.Loader();
        var manager = new js.loaders.LoadingManager();

        this->assertTrue(loader.manager instanceof js.loaders.LoadingManager, "Loader defines a default manager if not supplied in constructor.");
    }

    public function testCrossOrigin() {
        var loader = new js.loaders.Loader();
        var crossOrigin = "anonymous";

        this->assertEquals(loader.crossOrigin, crossOrigin, "Loader defines crossOrigin.");
    }

    public function testWithCredentials() {
        var loader = new js.loaders.Loader();
        var withCredentials = false;

        this->assertEquals(loader.withCredentials, withCredentials, "Loader defines withCredentials.");
    }

    public function testPath() {
        var loader = new js.loaders.Loader();
        var path = "";

        this->assertEquals(loader.path, path, "Loader defines path.");
    }

    public function testResourcePath() {
        var loader = new js.loaders.Loader();
        var resourcePath = "";

        this->assertEquals(loader.resourcePath, resourcePath, "Loader defines resourcePath.");
    }

    public function testRequestHeader() {
        var loader = new js.loaders.Loader();
        var requestHeader = {};

        this->assertEquals(loader.requestHeader, requestHeader, "Loader defines requestHeader.");
    }
}

TestLoader.__init__();