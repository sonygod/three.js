package three.js.test.unit.utils;

class SmartComparer {
  private var message:String;

  public function new() {
    // Diagnostic message, when comparison fails.
    message = '';
  }

  public function areEqual(val1:Dynamic, val2:Dynamic):Bool {
    // Values are strictly equal.
    if (val1 == val2) return true;

    // Null or undefined values.
    if (val1 == null || val2 == null) {
      if (val1 != val2) {
        makeFail('One value is undefined or null', val1, val2);
      }
      // Both null / undefined.
      return true;
    }

    // Don't compare functions.
    if (isFunction(val1) && isFunction(val2)) return true;

    // Array comparison.
    var arrCmp = compareArrays(val1, val2);
    if (arrCmp != null) return arrCmp;

    // Has custom equality comparer.
    if (val1.equals != null) {
      if (val1.equals(val2)) return true;
      return makeFail('Comparison with .equals method returned false');
    }

    // Object comparison.
    var objCmp = compareObjects(val1, val2);
    if (objCmp != null) return objCmp;

    // Object differs (unknown reason).
    return makeFail('Values differ', val1, val2);
  }

  public function getDiagnostic():String {
    return message;
  }

  private function isFunction(value:Dynamic):Bool {
    // The use of `Object#toString` avoids issues with the `typeof` operator
    // in Safari 8 which returns 'object' for typed array constructors, and
    // PhantomJS 1.9 which returns 'function' for `NodeList` instances.
    var tag = isObject(value) ? Std.string(Type.GetType(value)) : '';
    return tag == '[object Function]' || tag == '[object GeneratorFunction]';
  }

  private function isObject(value:Dynamic):Bool {
    // Avoid a V8 JIT bug in Chrome 19-20.
    // See https://code.google.com/p/v8/issues/detail?id=2291 for more details.
    var type = Std.string(Type.GetType(value));
    return value != null && (type == 'object' || type == 'function');
  }

  private function compareArrays(val1:Array<Dynamic>, val2:Array<Dynamic>):Bool {
    var isArr1 = Std.is(val1, Array<Dynamic>);
    var isArr2 = Std.is(val2, Array<Dynamic>);

    // Compare type.
    if (isArr1 != isArr2) return makeFail('Values are not both arrays');

    // Not arrays. Continue.
    if (!isArr1) return null;

    // Compare length.
    var N1 = val1.length;
    var N2 = val2.length;
    if (N1 != N2) return makeFail('Array length differs', N1, N2);

    // Compare content at each index.
    for (i in 0...N1) {
      var cmp = areEqual(val1[i], val2[i]);
      if (!cmp) return addContext('array index "' + i + '"');
    }

    // Arrays are equal.
    return true;
  }

  private function compareObjects(val1:Dynamic, val2:Dynamic):Bool {
    var isObj1 = isObject(val1);
    var isObj2 = isObject(val2);

    // Compare type.
    if (isObj1 != isObj2) return makeFail('Values are not both objects');

    // Not objects. Continue.
    if (!isObj1) return null;

    // Compare keys.
    var keys1 = Reflect.fields(val1);
    var keys2 = Reflect.fields(val2);

    for (key in keys1) {
      if (!Lambda.has(keys2, key)) {
        return makeFail('Property "' + key + '" is unexpected.');
      }
    }

    for (key in keys2) {
      if (!Lambda.has(keys1, key)) {
        return makeFail('Property "' + key + '" is missing.');
      }
    }

    // Keys are the same. For each key, compare content until a difference is found.
    var hadDifference = false;

    for (key in keys1) {
      if (key == 'uuid' || key == 'id') continue;

      var prop1 = Reflect.field(val1, key);
      var prop2 = Reflect.field(val2, key);

      // Compare property content.
      var eq = areEqual(prop1, prop2);

      // In case of failure, an message should already be set.
      // Add context to low level message.
      if (!eq) {
        addContext('property "' + key + "'");
        hadDifference = true;
      }
    }

    return !hadDifference;
  }

  private function makeFail(msg:String, val1:Dynamic, val2:Dynamic):Bool {
    message = msg;
    if (val1 != null && val2 != null) message += ' (' + val1 + ' vs ' + val2 + ')';
    return false;
  }

  private function addContext(msg:String):Bool {
    // There should already be a validation message. Add more context to it.
    message = message != null ? message : 'Error';
    message += ', at ' + msg;
    return false;
  }
}