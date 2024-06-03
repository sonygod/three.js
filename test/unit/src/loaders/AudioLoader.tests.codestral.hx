import js.Browser.document;
import qunit.QUnit;
import three.src.loaders.AudioLoader;
import three.src.loaders.Loader;

QUnit.module("Loaders", () -> {
    QUnit.module("AudioLoader", () -> {
        // INHERITANCE
        QUnit.test("Extending", (assert) -> {
            var object = new AudioLoader();
            assert.strictEqual(Std.is(object, Loader), true, "AudioLoader extends from Loader");
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) -> {
            var object = new AudioLoader();
            assert.ok(object != null, "Can instantiate an AudioLoader.");
        });

        // PUBLIC
        QUnit.todo("load", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });
    });
});