import js.Browser.document;
import three.loaders.LoadingManager;
import three.loaders.Loader;

class LoadingManagerTests {

    public static function main() {

        // INSTANCING
        var object:LoadingManager = new LoadingManager();
        trace('Can instantiate a LoadingManager.');

        // Add other tests here
    }

    // PUBLIC
    public static function testOnStart() {
        // Refer to #5689 for the reason why we don't set .onStart
        // in the constructor
        trace("Test not implemented yet");
    }

    public static function testOnLoad() {
        trace("Test not implemented yet");
    }

    public static function testOnProgress() {
        trace("Test not implemented yet");
    }

    public static function testOnError() {
        trace("Test not implemented yet");
    }

    public static function testItemStart() {
        trace("Test not implemented yet");
    }

    public static function testItemEnd() {
        trace("Test not implemented yet");
    }

    public static function testItemError() {
        trace("Test not implemented yet");
    }

    public static function testResolveURL() {
        trace("Test not implemented yet");
    }

    public static function testSetURLModifier() {
        trace("Test not implemented yet");
    }

    public static function testAddHandler() {
        trace("Test not implemented yet");
    }

    public static function testRemoveHandler() {
        trace("Test not implemented yet");
    }

    public static function testGetHandler() {
        trace("Test not implemented yet");
    }

    // OTHERS
    public static function testAddHandlerGetHandlerRemoveHandler() {

        var loadingManager:LoadingManager = new LoadingManager();
        var loader:Loader = new Loader();

        var regex1 = new EReg(/\.jpg$/i, "");
        var regex2 = new EReg(/\.jpg$/gi, "");

        loadingManager.addHandler(regex1, loader);

        // You will need to implement your own assert function or use a testing library
        // assert.equal(loadingManager.getHandler('foo.jpg'), loader, 'Returns the expected loader.');
        // assert.equal(loadingManager.getHandler('foo.jpg.png'), null, 'Returns null since the correct file extension is not at the end of the file name.');
        // assert.equal(loadingManager.getHandler('foo.jpeg'), null, 'Returns null since file extension is wrong.');

        loadingManager.removeHandler(regex1);
        loadingManager.addHandler(regex2, loader);

        // assert.equal(loadingManager.getHandler('foo.jpg'), loader, 'Returns the expected loader when using a regex with "g" flag.');
        // assert.equal(loadingManager.getHandler('foo.jpg'), loader, 'Returns the expected loader when using a regex with "g" flag. Test twice, see #17920.');
    }
}