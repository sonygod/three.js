import qunit.QUnit;

class UtilsTest {

	static function main() {
		QUnit.module("utils", function() {
			QUnit.test("arrayMin", function(assert) {
				assert.equal(arrayMin([]), Math.POSITIVE_INFINITY, "Empty array return positive infinit");
				assert.equal(arrayMin([5]), 5, "Single valued array should return the unique value as minimum");
				assert.equal(arrayMin([1, 5, 10]), 1, "The array [ 1, 5, 10 ] return 1");
				assert.equal(arrayMin([5, 1, 10]), 1, "The array [ 5, 1, 10 ] return 1");
				assert.equal(arrayMin([10, 5, 1]), 1, "The array [ 10, 5, 1 ] return 1");
				assert.equal(arrayMax([-0.0, 0.0]), -0.0, "The array [ - 0, 0 ] return -0");
				assert.equal(arrayMin([-Math.POSITIVE_INFINITY, 0, Math.POSITIVE_INFINITY]), -Math.POSITIVE_INFINITY, "The array [ - Infinity, 0, Infinity ] return -Infinity");
			});

			QUnit.test("arrayMax", function(assert) {
				assert.equal(arrayMax([]), Math.NEGATIVE_INFINITY, "Empty array return negative infinit");
				assert.equal(arrayMax([5]), 5, "Single valued array should return the unique value as maximum");
				assert.equal(arrayMax([10, 5, 1]), 10, "The array [ 10, 5, 1 ] return 10");
				assert.equal(arrayMax([1, 10, 5]), 10, "The array [ 1, 10, 5 ] return 10");
				assert.equal(arrayMax([1, 5, 10]), 10, "The array [ 1, 5, 10 ] return 10");
				assert.equal(arrayMax([-0.0, 0.0]), 0.0, "The array [ - 0, 0 ] return 0");
				assert.equal(arrayMax([-Math.POSITIVE_INFINITY, 0, Math.POSITIVE_INFINITY]), Math.POSITIVE_INFINITY, "The array [ - Infinity, 0, Infinity ] return Infinity");
			});

			QUnit.test("getTypedArray", function(assert) {
				assert.ok(getTypedArray("Int8Array", new haxe.io.Bytes()) instanceof haxe.io.Int8Array, "Int8Array");
				assert.ok(getTypedArray("Uint8Array", new haxe.io.Bytes()) instanceof haxe.io.UInt8Array, "Uint8Array");
				assert.ok(getTypedArray("Uint8ClampedArray", new haxe.io.Bytes()) instanceof haxe.io.UInt8Array, "Uint8ClampedArray");
				assert.ok(getTypedArray("Int16Array", new haxe.io.Bytes()) instanceof haxe.io.Int16Array, "Int16Array");
				assert.ok(getTypedArray("Uint16Array", new haxe.io.Bytes()) instanceof haxe.io.UInt16Array, "Uint16Array");
				assert.ok(getTypedArray("Int32Array", new haxe.io.Bytes()) instanceof haxe.io.Int32Array, "Int32Array");
				assert.ok(getTypedArray("Uint32Array", new haxe.io.Bytes()) instanceof haxe.io.UInt32Array, "Uint32Array");
				assert.ok(getTypedArray("Float32Array", new haxe.io.Bytes()) instanceof haxe.io.Float32Array, "Float32Array");
				assert.ok(getTypedArray("Float64Array", new haxe.io.Bytes()) instanceof haxe.io.Float64Array, "Float64Array");
			});
		});
	}

	static function arrayMin<T>(array:Array<T>):T {
		if (array.length == 0) {
			return cast Math.POSITIVE_INFINITY;
		}
		var min = array[0];
		for (i in 1...array.length) {
			if (array[i] < min) {
				min = array[i];
			}
		}
		return min;
	}

	static function arrayMax<T>(array:Array<T>):T {
		if (array.length == 0) {
			return cast Math.NEGATIVE_INFINITY;
		}
		var max = array[0];
		for (i in 1...array.length) {
			if (array[i] > max) {
				max = array[i];
			}
		}
		return max;
	}

	static function getTypedArray(type:String, buffer:haxe.io.Bytes):Dynamic {
		switch (type) {
			case "Int8Array":
				return new haxe.io.Int8Array(buffer);
			case "Uint8Array":
				return new haxe.io.UInt8Array(buffer);
			case "Uint8ClampedArray":
				return new haxe.io.UInt8Array(buffer);
			case "Int16Array":
				return new haxe.io.Int16Array(buffer);
			case "Uint16Array":
				return new haxe.io.UInt16Array(buffer);
			case "Int32Array":
				return new haxe.io.Int32Array(buffer);
			case "Uint32Array":
				return new haxe.io.UInt32Array(buffer);
			case "Float32Array":
				return new haxe.io.Float32Array(buffer);
			case "Float64Array":
				return new haxe.io.Float64Array(buffer);
			default:
				return null;
		}
	}
}

class Main {
	static function main() {
		UtilsTest.main();
	}
}