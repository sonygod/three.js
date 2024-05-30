import qunit.QUnit;
import loaders.Cache;

class CacheTests {
  public static function new() {
    QUnit.module("Loaders", () => {
      QUnit.module("Cache", () => {
        // PROPERTIES
        QUnit.test("enabled", () => {
          var actual = Cache.enabled;
          var expected = false;
          QUnit.strictEqual(actual, expected, 'Cache defines enabled.');
        });

        QUnit.test("files", () => {
          var actual = Cache.files;
          var expected = {};
          QUnit.deepEqual(actual, expected, 'Cache defines files.');
        });

        // PUBLIC
        QUnit.todo("add", () => {
          // function ( key, file )
          QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("get", () => {
          // function ( key )
          QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("remove", () => {
          // function ( key )
          QUnit.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("clear", () => {
          QUnit.ok(false, "everything's gonna be alright");
        });
      });
    });
  }
}