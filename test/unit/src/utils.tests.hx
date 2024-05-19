package three.js.test.unit.src;

import haxe.unit.TestCase;
import three.utils.Utils;

class UtilsTest extends TestCase {
    public function new() {
        super();
    }

    public function testArrayMin():Void {
        assertEquals( Math.POSITIVE_INFINITY, Utils.arrayMin([]), 'Empty array returns positive infinity');
        assertEquals(5, Utils.arrayMin([5]), 'Single valued array should return the unique value as minimum');
        assertEquals(1, Utils.arrayMin([1, 5, 10]), 'The array [1, 5, 10] returns 1');
        assertEquals(1, Utils.arrayMin([5, 1, 10]), 'The array [5, 1, 10] returns 1');
        assertEquals(1, Utils.arrayMin([10, 5, 1]), 'The array [10, 5, 1] returns 1');
        assertEquals(-0, Utils.arrayMax([-0, 0]), 'The array [-0, 0] returns -0');
        assertEquals(-Math.INFINITY, Utils.arrayMin([-Math.INFINITY, 0, Math.INFINITY]), 'The array [-Infinity, 0, Infinity] returns -Infinity');
    }

    public function testArrayMax():Void {
        assertEquals(-Math.INFINITY, Utils.arrayMax([]), 'Empty array returns negative infinity');
        assertEquals(5, Utils.arrayMax([5]), 'Single valued array should return the unique value as maximum');
        assertEquals(10, Utils.arrayMax([10, 5, 1]), 'The array [10, 5, 1] returns 10');
        assertEquals(10, Utils.arrayMax([1, 10, 5]), 'The array [1, 10, 5] returns 10');
        assertEquals(10, Utils.arrayMax([1, 5, 10]), 'The array [1, 5, 10] returns 10');
        assertEquals(0, Utils.arrayMax([-0, 0]), 'The array [-0, 0] returns 0');
        assertEquals(Math.INFINITY, Utils.arrayMax([-Math.INFINITY, 0, Math.INFINITY]), 'The array [-Infinity, 0, Infinity] returns Infinity');
    }

    public function testGetTypedArray():Void {
        assertTrue(Std.is(Utils.getTypedArray('Int8Array', new haxe.io.Bytes(0)), Int8Array), 'Int8Array');
        assertTrue(Std.is(Utils.getTypedArray('Uint8Array', new haxe.io.Bytes(0)), Uint8Array), 'Uint8Array');
        assertTrue(Std.is(Utils.getTypedArray('Uint8ClampedArray', new haxe.io.Bytes(0)), Uint8ClampedArray), 'Uint8ClampedArray');
        assertTrue(Std.is(Utils.getTypedArray('Int16Array', new haxe.io.Bytes(0)), Int16Array), 'Int16Array');
        assertTrue(Std.is(Utils.getTypedArray('Uint16Array', new haxe.io.Bytes(0)), Uint16Array), 'Uint16Array');
        assertTrue(Std.is(Utils.getTypedArray('Int32Array', new haxe.io.Bytes(0)), Int32Array), 'Int32Array');
        assertTrue(Std.is(Utils.getTypedArray('Uint32Array', new haxe.io.Bytes(0)), Uint32Array), 'Uint32Array');
        assertTrue(Std.is(Utils.getTypedArray('Float32Array', new haxe.io.Bytes(0)), Float32Array), 'Float32Array');
        assertTrue(Std.is(Utils.getTypedArray('Float64Array', new haxe.io.Bytes(0)), Float64Array), 'Float64Array');
    }
}