package ;

import js.QUnit;

class TestUtils {
    public static function arrayMin(array:Array<Int>):Int {
        if (array.length == 0) {
            return Int.POSITIVE_INFINITY;
        }
        var min = array[0];
        for (i in 1...array.length) {
            if (array[i] < min) {
                min = array[i];
            }
        }
        return min;
    }

    public static function arrayMax(array:Array<Int>):Int {
        if (array.length == 0) {
            return Int.NEGATIVE_INFINITY;
        }
        var max = array[0];
        for (i in 1...array.length) {
            if (array[i] > max) {
                max = array[i];
            }
        }
        return max;
    }

    public static function getTypedArray(type:String, buffer:js.ArrayBuffer):js.ArrayBufferView {
        switch (type) {
            case "Int8Array":
                return new js.Int8Array(buffer);
            case "Uint8Array":
                return new js.Uint8Array(buffer);
            case "Uint8ClampedArray":
                return new js.Uint8ClampedArray(buffer);
            case "Int16Array":
                return new js.Int16Array(buffer);
            case "Uint16Array":
                return new js.Uint16Array(buffer);
            case "Int32Array":
                return new js.Int32Array(buffer);
            case "Uint32Array":
                return new js.Uint32Array(buffer);
            case "Float32Array":
                return new js.Float32Array(buffer);
            case "Float64Array":
                return new js.Float64Array(buffer);
            default:
                throw "Unsupported typed array type: " + type;
        }
    }
}

class TestUtilsTest {
    public static function testArrayMin():Void {
        QUnit.equal(TestUtils.arrayMin([]), Int.POSITIVE_INFINITY, "Empty array return positive infinit");
        QUnit.equal(TestUtils.arrayMin([5]), 5, "Single valued array should return the unique value as minimum");
        QUnit.equal(TestUtils.arrayMin([1, 5, 10]), 1, "The array [1, 5, 10] return 1");
        QUnit.equal(TestUtils.arrayMin([5, 1, 10]), 1, "The array [5, 1, 10] return 1");
        QUnit.equal(TestUtils.arrayMin([10, 5, 1]), 1, "The array [10, 5, 1] return 1");
        QUnit.equal(TestUtils.arrayMax([-0, 0]), -0, "The array [-0, 0] return -0");
        QUnit.equal(TestUtils.arrayMin([-Int.NEGATIVE_INFINITY, 0, Int.POSITIVE_INFINITY]), Int.NEGATIVE_INFINITY, "The array [-Infinity, 0, Infinity] return -Infinity");
    }

    public static function testArrayMax():Void {
        QUnit.equal(TestUtils.arrayMax([]), Int.NEGATIVE_INFINITY, "Empty array return negative infinit");
        QUnit.equal(TestUtils.arrayMax([5]), 5, "Single valued array should return the unique value as maximum");
        QUnit.equal(TestUtils.arrayMax([10, 5, 1]), 10, "The array [10, 5, 1] return 10");
        QUnit.equal(TestUtils.arrayMax([1, 10, 5]), 10, "The array [1, 10, 5] return 10");
        QUnit.equal(TestUtils.arrayMax([1, 5, 10]), 10, "The array [1, 5, 10] return 10");
        QUnit.equal(TestUtils.arrayMax([-0, 0]), 0, "The array [-0, 0] return 0");
        QUnit.equal(TestUtils.arrayMax([-Int.NEGATIVE_INFINITY, 0, Int.POSITIVE_INFINITY]), Int.POSITIVE_INFINITY, "The array [-Infinity, 0, Infinity] return Infinity");
    }

    public static function testGetTypedArray():Void {
        QUnit.ok(js.Reflect.instanceOf(TestUtils.getTypedArray("Int8Array", new js.ArrayBuffer(0)), js.Int8Array), "Int8Array");
        QUnit.ok(js.Reflect.instanceOf(TestUtils.getTypedArray("Uint8Array", new js.ArrayBuffer(0)), js.Uint8Array), "Uint8Array");
        QUnit.ok(js.Reflect.instanceOf(TestUtils.getTypedArray("Uint8ClampedArray", new js.ArrayBuffer(0)), js.Uint8ClampedArray), "Uint8ClampedArray");
        QUnit.ok(js.Reflect.instanceOf(TestUtils.getTypedArray("Int16Array", new js.ArrayBuffer(0)), js.Int16Array), "Int16Array");
        QUnit.ok(js.Reflect.instanceOf(TestUtils.getTypedArray("Uint16Array", new js.ArrayBuffer(0)), js.Uint16Array), "Uint16Array");
        QUnit.ok(js.Reflect.instanceOf(TestUtils.getTypedArray("Int32Array", new js.ArrayBuffer(0)), js.Int32Array), "Int32Array");
        QUnit.ok(js.Reflect.instanceOf(TestUtils.getTypedArray("Uint32Array", new js.ArrayBuffer(0)), js.Uint32Array), "Uint32Array");
        QUnit.ok(js.Reflect.instanceOf(TestUtils.getTypedArray("Float32Array", new js.ArrayBuffer(0)), js.Float32Array), "Float32Array");
        QUnit.ok(js.Reflect.instanceOf(TestUtils.getTypedArray("Float64Array", new js.ArrayBuffer(0)), js.Float64Array), "Float64Array");
    }
}

QUnit.module("utils", function() {
    QUnit.test("arrayMin", TestUtilsTest.testArrayMin);
    QUnit.test("arrayMax", TestUtilsTest.testArrayMax);
    QUnit.test("getTypedArray", TestUtilsTest.testGetTypedArray);
});