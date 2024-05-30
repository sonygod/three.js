package three.js.test.unit.utils;

class SmartComparer {
  private var message:String;

  public function new() {
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
      makeFail('Comparison with .equals method returned false');
    }

    // Object comparison.
    var objCmp = compareObjects(val1, val2);
    if (objCmp != null) return objCmp;

    // Object differs (unknown reason).
    makeFail('Values differ', val1, val2);
    return false;
  }

  public function getDiagnostic():String {
    return message;
  }

  private function isFunction(value:Dynamic):Bool {
    var tag:String = isObject(value) ? Std.string(value) : '';
    return tag == '[object Function]' || tag == '[object GeneratorFunction]';
  }

  private function isObject(value:Dynamic):Bool {
    var type:String = typeof value;
    return value != null && (type == 'object' || type == 'function');
  }

  private function compareArrays(val1:Array<Dynamic>, val2:Array<Dynamic>):Bool {
    if (!Std.isOfType(val1, Array) || !Std.isOfType(val2, Array)) {
      makeFail('Values are not both arrays');
    }
    if (val1.length != val2.length) {
      makeFail('Array length differs', val1.length, val2.length);
    }
    for (i in 0...val1.length) {
      if (!areEqual(val1[i], val2[i])) {
        addContext('array index "' + i + '"');
      }
    }
    return true;
  }

  private function compareObjects(val1:Dynamic, val2:Dynamic):Bool {
    if (!isObject(val1) || !isObject(val2)) {
      makeFail('Values are not both objects');
    }
    var keys1:Array<String> = Reflect.fields(val1);
    var keys2:Array<String> = Reflect.fields(val2);
    for (key in keys1) {
      if (keys2.indexOf(key) < 0) {
        makeFail('Property "' + key + '" is unexpected.');
      }
    }
    for (key in keys2) {
      if (keys1.indexOf(key) < 0) {
        makeFail('Property "' + key + '" is missing.');
      }
    }
    var hadDifference = false;
    for (key in keys1) {
      if (key == 'uuid' || key == 'id') continue;
      var prop1 = Reflect.field(val1, key);
      var prop2 = Reflect.field(val2, key);
      if (!areEqual(prop1, prop2)) {
        addContext('property "' + key + '"');
        hadDifference = true;
      }
    }
    return !hadDifference;
  }

  private function makeFail(msg:String, ?val1:Dynamic, ?val2:Dynamic):Void {
    message = msg;
    if (val1 != null && val2 != null) {
      message += ' (' + val1 + ' vs ' + val2 + ')';
    }
  }

  private function addContext(msg:String):Void {
    message += ', at ' + msg;
  }
}