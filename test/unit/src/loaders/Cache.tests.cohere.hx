import js.QUnit.*;
import js.QUnit.QUnitTest;

import loaders.Cache;

class TestCache {
    static function enabled(assert: QUnitAssert) {
        var actual = Cache.enabled;
        var expected = false;
        assert.strictEqual(actual, expected, "Cache defines enabled.");
    }

    static function files(assert: QUnitAssert) {
        var actual = Cache.files;
        var expected = cast({});
        assert.deepEqual(actual, expected, "Cache defines files.");
    }

    static function add(assert: QUnitAssert) {
        // function ( key, file )
        assert.ok(false, "everything's gonna be alright");
    }

    static function get(assert: QUnitAssert) {
        // function ( key )
        assert.ok(false, "everything's gonna be alright");
    }

    static function remove(assert: QUnitAssert) {
        // function ( key )
        assert.ok(false, "everything's gonna be alright");
    }

    static function clear(assert: QUnitAssert) {
        assert.ok(false, "everything's gonna be alright");
    }
}

class TestLoaders {
    static function run() {
        module("Loaders", {
            setup: function() { },
            teardown: function() { }
        });

        module("Cache", {
            setup: function() { },
            teardown: function() { }
        });

        test("enabled", TestCache.enabled);
        test("files", TestCache.files);
        todo("add", TestCache.add);
        todo("get", TestCache.get);
        todo("remove", TestCache.remove);
        todo("clear", TestCache.clear);
    }
}

TestLoaders.run();