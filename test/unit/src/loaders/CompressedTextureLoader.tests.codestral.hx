import qunit.QUnitModule;
import qunit.QUnitTest;
import threejs.src.loaders.CompressedTextureLoader;
import threejs.src.loaders.Loader;

class CompressedTextureLoaderTests {
    public function new() {
        var module = QUnitModule.create("Loaders");

        var compressedTextureLoaderModule = QUnitModule.create("CompressedTextureLoader", module);

        var extendingTest = QUnitTest.create("Extending", (assert) -> {
            var object = new CompressedTextureLoader();
            assert.strictEqual(Std.is(object, Loader), true, "CompressedTextureLoader extends from Loader");
        }, compressedTextureLoaderModule);

        var instancingTest = QUnitTest.create("Instancing", (assert) -> {
            var object = new CompressedTextureLoader();
            assert.ok(object != null, "Can instantiate a CompressedTextureLoader.");
        }, compressedTextureLoaderModule);

        var loadTest = QUnitTest.create("load", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        }, compressedTextureLoaderModule);
        loadTest.todo();
    }
}