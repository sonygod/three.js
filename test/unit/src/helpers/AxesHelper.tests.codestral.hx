import js.Browser.document;
import js.Lib;
import threejs.src.helpers.AxesHelper;
import threejs.src.objects.LineSegments;

class Main {

    public static function main(): Void {
        testHelpers();
    }

    public static function testHelpers(): Void {
        testAxesHelper();
    }

    public static function testAxesHelper(): Void {
        qUnitTest("Extending", function(assert) {
            var object = new AxesHelper();
            assert.strictEqual(Std.is(object, LineSegments), true, "AxesHelper extends from LineSegments");
        });

        qUnitTest("Instancing", function(assert) {
            var object = new AxesHelper();
            assert.ok(object, "Can instantiate an AxesHelper.");
        });

        qUnitTest("type", function(assert) {
            var object = new AxesHelper();
            assert.ok(object.type == "AxesHelper", "AxesHelper.type should be AxesHelper");
        });

        qUnitTodo("setColors", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        qUnitTest("dispose", function(assert) {
            assert.expect(0);
            var object = new AxesHelper();
            object.dispose();
        });
    }

    public static function qUnitTest(name: String, callback: js.Function): Void {
        Lib.trace("QUnit.test('" + name + "', callback)");
        callback(QUnitAssert);
    }

    public static function qUnitTodo(name: String, callback: js.Function): Void {
        Lib.trace("QUnit.todo('" + name + "', callback)");
        callback(QUnitAssert);
    }
}

class QUnitAssert {
    public static function ok(condition: Bool, message: String): Void {
        Lib.trace(condition ? "PASS: " + message : "FAIL: " + message);
    }

    public static function strictEqual(actual: Dynamic, expected: Dynamic, message: String): Void {
        Lib.trace(actual === expected ? "PASS: " + message : "FAIL: " + message);
    }

    public static function expect(count: Int): Void {
        Lib.trace("Expected " + count + " assertions");
    }
}