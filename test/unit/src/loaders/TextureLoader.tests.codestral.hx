import js.Browser.document;
import js.html.QUnit;
import three.loaders.TextureLoader;
import three.loaders.Loader;

QUnit.module("Loaders", () -> {
    QUnit.module("TextureLoader", () -> {
        // INHERITANCE
        QUnit.test("Extending", (assert) -> {
            var object:TextureLoader = new TextureLoader();
            assert.strictEqual(Std.is(object, Loader), true, 'TextureLoader extends from Loader');
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) -> {
            var object:TextureLoader = new TextureLoader();
            assert.ok(object, "Can instantiate a TextureLoader.");
        });

        // PUBLIC
        QUnit.todo("load", (assert) -> {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    });
});