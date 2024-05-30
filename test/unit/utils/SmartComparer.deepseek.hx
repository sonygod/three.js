// Smart comparison of three.js objects.
// Identifies significant differences between two objects.
// Performs deep comparison.
// Comparison stops after the first difference is found.
// Provides an explanation for the failure.
class SmartComparer {

	// Diagnostic message, when comparison fails.
	var message:String;

	public function new() {

	}

	// val1 - first value to compare (typically the actual value)
	// val2 - other value to compare (typically the expected value)
	public function areEqual(val1:Dynamic, val2:Dynamic):Bool {

		// Values are strictly equal.
		if (val1 === val2) return true;

		// Null or undefined values.
		if (val1 == null || val2 == null) {

			if (val1 != val2) {

				return this.makeFail('One value is undefined or null', val1, val2);

			}

			// Both null / undefined.
			return true;

		}

		// Don't compare functions.
		if (this.isFunction(val1) && this.isFunction(val2)) return true;

		// Array comparison.
		var arrCmp = this.compareArrays(val1, val2);
		if (arrCmp !== undefined) return arrCmp;

		// Has custom equality comparer.
		if (Std.is(val1, Dynamic -> Bool)) {

			if (val1.equals(val2)) return true;

			return this.makeFail('Comparison with .equals method returned false');

		}

		// Object comparison.
		var objCmp = this.compareObjects(val1, val2);
		if (objCmp !== undefined) return objCmp;

		// Object differs (unknown reason).
		return this.makeFail('Values differ', val1, val2);

	}

	public function getDiagnostic():String {

		return message;

	}

	private function isFunction(value:Dynamic):Bool {

		// The use of `Object#toString` avoids issues with the `typeof` operator
		// in Safari 8 which returns 'object' for typed array constructors, and
		// PhantomJS 1.9 which returns 'function' for `NodeList` instances.
		var tag = Std.is(value, Dynamic -> String) ? Std.string(value) : '';

		return tag == '[object Function]' || tag == '[object GeneratorFunction]';

	}

	private function isObject(value:Dynamic):Bool {

		// Avoid a V8 JIT bug in Chrome 19-20.
		// See https://code.google.com/p/v8/issues/detail?id=2291 for more details.
		var type = Std.typeof(value);

		return !!value && (type == 'object' || type == 'function');

	}

	private function compareArrays(val1:Dynamic, val2:Dynamic):Bool {

		var isArr1 = Std.is(val1, Array<Dynamic>);
		var isArr2 = Std.is(val2, Array<Dynamic>);

		// Compare type.
		if (isArr1 !== isArr2) return this.makeFail('Values are not both arrays');

		// Not arrays. Continue.
		if (!isArr1) return undefined;

		// Compare length.
		var N1 = val1.length;
		var N2 = val2.length;
		if (N1 !== val2.length) return this.makeFail('Array length differs', N1, N2);

		// Compare content at each index.
		for (i in 0...N1) {

			var cmp = this.areEqual(val1[i], val2[i]);
			if (!cmp) return this.addContext('array index "' + i + '"');

		}

		// Arrays are equal.
		return true;

	}

	private function compareObjects(val1:Dynamic, val2:Dynamic):Bool {

		var isObj1 = this.isObject(val1);
		var isObj2 = this.isObject(val2);

		// Compare type.
		if (isObj1 !== isObj2) return this.makeFail('Values are not both objects');

		// Not objects. Continue.
		if (!isObj1) return undefined;

		// Compare keys.
		var keys1 = Reflect.fields(val1);
		var keys2 = Reflect.fields(val2);

		for (i in 0...keys1.length) {

			if (keys2.indexOf(keys1[i]) < 0) {

				return this.makeFail('Property "' + keys1[i] + '" is unexpected.');

			}

		}

		for (i in 0...keys2.length) {

			if (keys1.indexOf(keys2[i]) < 0) {

				return this.makeFail('Property "' + keys2[i] + '" is missing.');

			}

		}

		// Keys are the same. For each key, compare content until a difference is found.
		var hadDifference = false;

		for (i in 0...keys1.length) {

			var key = keys1[i];

			if (key === 'uuid' || key === 'id') {

				continue;

			}

			var prop1 = Reflect.field(val1, key);
			var prop2 = Reflect.field(val2, key);

			// Compare property content.
			var eq = this.areEqual(prop1, prop2);

			// In case of failure, an message should already be set.
			// Add context to low level message.
			if (!eq) {

				this.addContext('property "' + key + '"');
				hadDifference = true;

			}

		}

		return !hadDifference;

	}

	private function makeFail(msg:String, val1:Dynamic, val2:Dynamic):Bool {

		message = msg;
		if (arguments.length > 1) message += ' (' + val1 + ' vs ' + val2 + ')';

		return false;

	}

	private function addContext(msg:String):Bool {

		// There should already be a validation message. Add more context to it.
		message = message || 'Error';
		message += ', at ' + msg;

		return false;

	}

}