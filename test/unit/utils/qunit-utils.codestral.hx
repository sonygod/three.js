import qunit.QUnit;
import SmartComparer;
import ObjectLoader from three.js.loaders.ObjectLoader;

class QunitUtils {
    static function success(message: String): Void {
        QUnit.pushResult({
            result: true,
            actual: null,
            expected: null,
            message: message
        });
    }

    static function fail(message: String): Void {
        QUnit.pushResult({
            result: false,
            actual: null,
            expected: null,
            message: message
        });
    }

    static function numEqual(actual: Float, expected: Float, message: Null<String> = null): Void {
        var diff: Float = Math.abs(actual - expected);
        if (message == null) message = actual + " should be equal to " + expected;
        QUnit.pushResult({
            result: diff < 0.1,
            actual: actual,
            expected: expected,
            message: message
        });
    }

    static function equalKey(obj: Dynamic, ref: Dynamic, key: String): Void {
        var actual: Dynamic = Reflect.field(obj, key);
        var expected: Dynamic = Reflect.field(ref, key);
        var message: String = actual + " should be equal to " + expected + " for key \"" + key + "\"";
        QUnit.pushResult({
            result: actual == expected,
            actual: actual,
            expected: expected,
            message: message
        });
    }

    static function smartEqual(actual: Dynamic, expected: Dynamic, message: Null<String> = null): Void {
        var cmp: SmartComparer = new SmartComparer();
        var same: Bool = cmp.areEqual(actual, expected);
        var msg: String = cmp.getDiagnostic() != null ? cmp.getDiagnostic() : message;

        QUnit.pushResult({
            result: same,
            actual: actual,
            expected: expected,
            message: msg
        });
    }

    // Rest of the functions...
}

export { QunitUtils.runStdLightTests, QunitUtils.runStdGeometryTests };