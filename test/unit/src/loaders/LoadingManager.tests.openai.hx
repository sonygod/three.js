package three.js.test.unit.src.loaders;

import three.js.loaders.LoadingManager;
import three.js.loaders.Loader;

class LoadingManagerTests {
    public function new() {}

    public static function main() {
        QUnit.module("Loaders", () => {
            QUnit.module("LoadingManager", () => {
                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    // no params
                    var object = new LoadingManager();
                    assert.ok(object, "Can instantiate a LoadingManager.");
                });

                // PUBLIC
                QUnit.todo("onStart", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("onLoad", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("onProgress", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("onError", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("itemStart", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("itemEnd", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("itemError", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("resolveURL", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setURLModifier", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("addHandler", (assert) => {
                    // addHandler( regex, loader )
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("removeHandler", (assert) => {
                    // removeHandler( regex )
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getHandler", (assert) => {
                    // getHandler( file )
                    assert.ok(false, "everything's gonna be alright");
                });

                // OTHERS
                QUnit.test("addHandler/getHandler/removeHandler", (assert) => {
                    var loadingManager = new LoadingManager();
                    var loader = new Loader();

                    var regex1 = ~/\.jpg$/i;
                    var regex2 = ~/\.jpg$/gi;

                    loadingManager.addHandler(regex1, loader);

                    assert.equal(loadingManager.getHandler("foo.jpg"), loader, "Returns the expected loader.");
                    assert.equal(loadingManager.getHandler("foo.jpg.png"), null, "Returns null since the correct file extension is not at the end of the file name.");
                    assert.equal(loadingManager.getHandler("foo.jpeg"), null, "Returns null since file extension is wrong.");

                    loadingManager.removeHandler(regex1);
                    loadingManager.addHandler(regex2, loader);

                    assert.equal(loadingManager.getHandler("foo.jpg"), loader, "Returns the expected loader when using a regex with \"g\" flag.");
                    assert.equal(loadingManager.getHandler("foo.jpg"), loader, "Returns the expected loader when using a regex with \"g\" flag. Test twice, see #17920.");
                });
            });
        });
    }
}