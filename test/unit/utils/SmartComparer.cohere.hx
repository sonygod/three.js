import js.Lib.Reflect;

class SmartComparer {
    private var _message: String;

    public function new() {
        _message = null;
    }

    public function areEqual(val1: Dynamic, val2: Dynamic): Bool {
        if (val1 === val2) return true;

        if (val1 == null || val2 == null) {
            if (val1 != val2) {
                return makeFail("One value is null", val1, val2);
            }
            return true; // both null
        }

        if (js.Lib.Reflect.isFunction(val1) && js.Lib.Reflect.isFunction(val2)) return true;

        if (js.Lib.Reflect.isArray(val1) && js.Lib.Reflect.isArray(val2)) {
            return compareArrays(val1, val2);
        }

        if (js.Lib.Reflect.isObject(val1) && js.Lib.Reflect.isObject(val2)) {
            return compareObjects(val1, val2);
        }

        if (Std.is(val1, val2)) return true;

        return makeFail("Values differ", val1, val2);
    }

    public function getDiagnostic(): String {
        return _message;
    }

    private function compareArrays(arr1: Array<Dynamic>, arr2: Array<Dynamic>): Bool {
        if (arr1.length != arr2.length) {
            return makeFail("Array length differs", arr1.length, arr2.length);
        }

        for (i in 0...arr1.length) {
            if (!areEqual(arr1[i], arr2[i])) {
                return addContext("array index " + i);
            }
        }

        return true;
    }

    private function compareObjects(obj1: Dynamic, obj2: Dynamic): Bool {
        var keys1 = Reflect.fields(obj1);
        var keys2 = Reflect.fields(obj2);

        for (key in keys1) {
            if (!keys2.contains(key)) {
                return makeFail("Property " ~ key ~ " is unexpected.");
            }
        }

        for (key in keys2) {
            if (!keys1.contains(key)) {
                return makeFail("Property " ~ key ~ " is missing.");
            }
        }

        var hadDifference = false;

        for (key in keys1) {
            if (key == "uuid" || key == "id") continue;

            var prop1 = Reflect.field(obj1, key);
            var prop2 = Reflect.field(obj2, key);

            if (!areEqual(prop1, prop2)) {
                addContext("property " ~ key);
                hadDifference = true;
            }
        }

        return !hadDifference;
    }

    private function makeFail(msg: String, ?val1: Dynamic, ?val2: Dynamic): Bool {
        _message = msg;
        if (val1 != null && val2 != null) _message += " (" ~ Std.string(val1) ~ " vs " ~ Std.string(val2) ~ ")";
        return false;
    }

    private function addContext(msg: String): Bool {
        if (_message == null) _message = "Error";
        _message += ", at " ~ msg;
        return false;
    }
}