import three.loaders.Loader;
import three.loaders.LoadingManager;
import qunit.QUnit;

class LoaderTests {
    public function new() {
        QUnit.module("Loaders", () -> {
            QUnit.module("Loader", () -> {
                QUnit.test("Instancing", (assert) -> {
                    var object = new Loader();
                    assert.isTrue(object != null, "Can instantiate a Loader.");
                });

                QUnit.test("manager", (assert) -> {
                    var object = new Loader().manager;
                    assert.isTrue(Std.is(object, LoadingManager), "Loader defines a default manager if not supplied in constructor.");
                });

                QUnit.test("crossOrigin", (assert) -> {
                    var actual = new Loader().crossOrigin;
                    var expected = "anonymous";
                    assert.strictEqual(actual, expected, "Loader defines crossOrigin.");
                });

                QUnit.test("withCredentials", (assert) -> {
                    var actual = new Loader().withCredentials;
                    var expected = false;
                    assert.strictEqual(actual, expected, "Loader defines withCredentials.");
                });

                QUnit.test("path", (assert) -> {
                    var actual = new Loader().path;
                    var expected = "";
                    assert.strictEqual(actual, expected, "Loader defines path.");
                });

                QUnit.test("resourcePath", (assert) -> {
                    var actual = new Loader().resourcePath;
                    var expected = "";
                    assert.strictEqual(actual, expected, "Loader defines resourcePath.");
                });

                QUnit.test("requestHeader", (assert) -> {
                    var actual = new Loader().requestHeader;
                    var expected = new haxe.ds.StringMap<Dynamic>();
                    assert.deepEqual(actual, expected, "Loader defines requestHeader.");
                });
            });
        });
    }
}