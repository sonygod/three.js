// haxe
import js.Browser.document;
import js.html.QUnit;
import three.src.loaders.Cache;

class CacheTests {
    public function new() {
        QUnit.module("Loaders", () -> {
            QUnit.module("Cache", () -> {
                // PROPERTIES
                QUnit.test("enabled", (assert) -> {
                    var actual = Cache.enabled;
                    var expected = false;
                    assert.strictEqual(actual, expected, 'Cache defines enabled.');
                });

                QUnit.test("files", (assert) -> {
                    var actual = Cache.files;
                    var expected = new haxe.ds.StringMap<Dynamic>();
                    assert.deepEqual(actual, expected, 'Cache defines files.');
                });

                // PUBLIC
                QUnit.todo("add", (assert) -> {
                    // function ( key, file )
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("get", (assert) -> {
                    // function ( key )
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("remove", (assert) -> {
                    // function ( key )
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("clear", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}