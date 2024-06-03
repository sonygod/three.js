import js.Browser.document;
import three.src.utils.Utils;

class UtilsTest {
    public static function main() {
        testArrayMin();
        testArrayMax();
        testGetTypedArray();
    }

    private static function testArrayMin() {
        trace("Testing arrayMin...");
        UtilsTest.assertEquals(Utils.arrayMin([]), Double.POSITIVE_INFINITY, "Empty array returns positive infinity");
        UtilsTest.assertEquals(Utils.arrayMin([5]), 5, "Single valued array should return the unique value as minimum");
        UtilsTest.assertEquals(Utils.arrayMin([1, 5, 10]), 1, "The array [1, 5, 10] returns 1");
        UtilsTest.assertEquals(Utils.arrayMin([5, 1, 10]), 1, "The array [5, 1, 10] returns 1");
        UtilsTest.assertEquals(Utils.arrayMin([10, 5, 1]), 1, "The array [10, 5, 1] returns 1");
        UtilsTest.assertEquals(Utils.arrayMin([-0.0, 0.0]), -0.0, "The array [-0.0, 0.0] returns -0.0");
        UtilsTest.assertEquals(Utils.arrayMin([Double.NEGATIVE_INFINITY, 0.0, Double.POSITIVE_INFINITY]), Double.NEGATIVE_INFINITY, "The array [Double.NEGATIVE_INFINITY, 0.0, Double.POSITIVE_INFINITY] returns Double.NEGATIVE_INFINITY");
    }

    private static function testArrayMax() {
        trace("Testing arrayMax...");
        UtilsTest.assertEquals(Utils.arrayMax([]), Double.NEGATIVE_INFINITY, "Empty array returns negative infinity");
        UtilsTest.assertEquals(Utils.arrayMax([5]), 5, "Single valued array should return the unique value as maximum");
        UtilsTest.assertEquals(Utils.arrayMax([10, 5, 1]), 10, "The array [10, 5, 1] returns 10");
        UtilsTest.assertEquals(Utils.arrayMax([1, 10, 5]), 10, "The array [1, 10, 5] returns 10");
        UtilsTest.assertEquals(Utils.arrayMax([1, 5, 10]), 10, "The array [1, 5, 10] returns 10");
        UtilsTest.assertEquals(Utils.arrayMax([-0.0, 0.0]), 0.0, "The array [-0.0, 0.0] returns 0.0");
        UtilsTest.assertEquals(Utils.arrayMax([Double.NEGATIVE_INFINITY, 0.0, Double.POSITIVE_INFINITY]), Double.POSITIVE_INFINITY, "The array [Double.NEGATIVE_INFINITY, 0.0, Double.POSITIVE_INFINITY] returns Double.POSITIVE_INFINITY");
    }

    private static function testGetTypedArray() {
        trace("Testing getTypedArray...");
        UtilsTest.assertTrue(Utils.getTypedArray("Int8Array", new js.html.ArrayBuffer(0)) is Int8Array, "Int8Array");
        UtilsTest.assertTrue(Utils.getTypedArray("Uint8Array", new js.html.ArrayBuffer(0)) is Uint8Array, "Uint8Array");
        UtilsTest.assertTrue(Utils.getTypedArray("Uint8ClampedArray", new js.html.ArrayBuffer(0)) is Uint8ClampedArray, "Uint8ClampedArray");
        UtilsTest.assertTrue(Utils.getTypedArray("Int16Array", new js.html.ArrayBuffer(0)) is Int16Array, "Int16Array");
        UtilsTest.assertTrue(Utils.getTypedArray("Uint16Array", new js.html.ArrayBuffer(0)) is Uint16Array, "Uint16Array");
        UtilsTest.assertTrue(Utils.getTypedArray("Int32Array", new js.html.ArrayBuffer(0)) is Int32Array, "Int32Array");
        UtilsTest.assertTrue(Utils.getTypedArray("Uint32Array", new js.html.ArrayBuffer(0)) is Uint32Array, "Uint32Array");
        UtilsTest.assertTrue(Utils.getTypedArray("Float32Array", new js.html.ArrayBuffer(0)) is Float32Array, "Float32Array");
        UtilsTest.assertTrue(Utils.getTypedArray("Float64Array", new js.html.ArrayBuffer(0)) is Float64Array, "Float64Array");
    }

    private static function assertEquals(actual:Dynamic, expected:Dynamic, message:String) {
        if (actual == expected) {
            trace("Test passed: " + message);
        } else {
            trace("Test failed: " + message + " (Expected " + expected + ", but got " + actual + ")");
        }
    }

    private static function assertTrue(condition:Bool, message:String) {
        if (condition) {
            trace("Test passed: " + message);
        } else {
            trace("Test failed: " + message);
        }
    }
}