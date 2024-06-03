import three.loaders.FileLoader;
import three.loaders.Loader;

class FileLoaderTests {

    static function main() {

        // INHERITANCE
        function testExtending() {
            var object = new FileLoader();
            // assert.strictEqual(Std.is(object, Loader), true, 'FileLoader extends from Loader');
        }

        // INSTANCING
        function testInstancing() {
            var object = new FileLoader();
            // assert.ok(object, 'Can instantiate a FileLoader.');
        }

        // PUBLIC
        function testLoad() {
            // TODO: Implement test
        }

        function testSetResponseType() {
            // TODO: Implement test
        }

        function testSetMimeType() {
            // TODO: Implement test
        }

        // Run tests
        testExtending();
        testInstancing();
        testLoad();
        testSetResponseType();
        testSetMimeType();
    }
}

FileLoaderTests.main();