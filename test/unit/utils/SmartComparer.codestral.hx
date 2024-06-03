import js.html.ArrayBuffer;
import js.html.ArrayBufferView;
import js.html.Function;

class SmartComparer {
    private var message:String;

    public function new() {

    }

    public function areEqual(val1:Dynamic, val2:Dynamic):Bool {
        if (val1 === val2) return true;

        if (js.Boot.isNull(val1) || js.Boot.isNull(val2)) {
            if (val1 != val2) {
                return makeFail("One value is undefined or null", val1, val2);
            }
            return true;
        }

        if (js.Boot.isFunction(val1) && js.Boot.isFunction(val2)) return true;

        var arrCmp = compareArrays(val1, val2);
        if (arrCmp !== null) return arrCmp;

        if (Reflect.hasField(val1, "equals")) {
            if (Reflect.callMethod(val1, val1.equals, [val2])) return true;
            return makeFail("Comparison with .equals method returned false");
        }

        var objCmp = compareObjects(val1, val2);
        if (objCmp !== null) return objCmp;

        return makeFail("Values differ", val1, val2);
    }

    public function getDiagnostic():String {
        return message;
    }

    private function isFunction(value:Dynamic):Bool {
        if (js.Boot.isObject(value)) {
            var tag = js.Boot.getClass(value);
            return tag == Function || tag == js.html.Generator;
        }
        return false;
    }

    private function isObject(value:Dynamic):Bool {
        var type = Type.typeof(value);
        return type == TType.TClass || type == TType.TFunction || type == TType.TEnum || type == TType.TInstance;
    }

    private function compareArrays(val1:Dynamic, val2:Dynamic):Null<Bool> {
        var isArr1 = js.Boot.isArray(val1);
        var isArr2 = js.Boot.isArray(val2);

        if (isArr1 !== isArr2) return makeFail("Values are not both arrays");

        if (!isArr1) return null;

        var N1 = val1.length;
        var N2 = val2.length;

        if (N1 !== N2) return makeFail("Array length differs", N1, N2);

        for (var i = 0; i < N1; i++) {
            var cmp = areEqual(val1[i], val2[i]);
            if (!cmp) return addContext("array index \"" + i + "\"");
        }

        return true;
    }

    private function compareObjects(val1:Dynamic, val2:Dynamic):Null<Bool> {
        var isObj1 = isObject(val1);
        var isObj2 = isObject(val2);

        if (isObj1 !== isObj2) return makeFail("Values are not both objects");

        if (!isObj1) return null;

        var keys1 = Reflect.fields(val1);
        var keys2 = Reflect.fields(val2);

        for (var i = 0; i < keys1.length; i++) {
            if (keys2.indexOf(keys1[i]) < 0) {
                return makeFail("Property \"" + keys1[i] + "\" is unexpected.");
            }
        }

        for (var i = 0; i < keys2.length; i++) {
            if (keys1.indexOf(keys2[i]) < 0) {
                return makeFail("Property \"" + keys2[i] + "\" is missing.");
            }
        }

        var hadDifference = false;

        for (var i = 0; i < keys1.length; i++) {
            var key = keys1[i];

            if (key === "uuid" || key === "id") {
                continue;
            }

            var prop1 = Reflect.field(val1, key);
            var prop2 = Reflect.field(val2, key);

            var eq = areEqual(prop1, prop2);

            if (!eq) {
                addContext("property \"" + key + "\"");
                hadDifference = true;
            }
        }

        return !hadDifference;
    }

    private function makeFail(msg:String, val1:Dynamic = null, val2:Dynamic = null):Bool {
        message = msg;
        if (arguments.length > 1) message += " (" + val1 + " vs " + val2 + ")";
        return false;
    }

    private function addContext(msg:String):Bool {
        message = message || "Error";
        message += ", at " + msg;
        return false;
    }
}