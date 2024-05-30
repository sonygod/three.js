package three.js.test.unit.src;

import haxe.unit.TestCase;
import three.utils.Utils;

class UtilsTests extends TestCase {

    public function new() { super(); }

    public function testArrayMin() {
        assertEquals( Math.POSITIVE_INFINITY, Utils.arrayMin([]), 'Empty array return positive infinit');
        assertEquals( 5, Utils.arrayMin([5]), 'Single valued array should return the unique value as minimum');
        assertEquals( 1, Utils.arrayMin([1, 5, 10]), 'The array [ 1, 5, 10 ] return 1');
        assertEquals( 1, Utils.arrayMin([5, 1, 10]), 'The array [ 5, 1, 10 ] return 1');
        assertEquals( 1, Utils.arrayMin([10, 5, 1]), 'The array [ 10, 5, 1 ] return 1');
        assertEquals( -0, Utils.arrayMax([-0, 0]), 'The array [ -0, 0 ] return -0');
        assertEquals( -Math.INFINITY, Utils.arrayMin([-Math.INFINITY, 0, Math.INFINITY]), 'The array [ - Infinity, 0, Infinity ] return -Infinity');
    }

    public function testArrayMax() {
        assertEquals( -Math.INFINITY, Utils.arrayMax([]), 'Empty array return negative infinit');
        assertEquals( 5, Utils.arrayMax([5]), 'Single valued array should return the unique value as maximum');
        assertEquals( 10, Utils.arrayMax([10, 5, 1]), 'The array [ 10, 5, 1 ] return 10');
        assertEquals( 10, Utils.arrayMax([1, 10, 5]), 'The array [ 1, 10, 5 ] return 10');
        assertEquals( 10, Utils.arrayMax([1, 5, 10]), 'The array [ 1, 5, 10 ] return 10');
        assertEquals( 0, Utils.arrayMax([-0, 0]), 'The array [ -0, 0 ] return 0');
        assertEquals( Math.INFINITY, Utils.arrayMax([-Math.INFINITY, 0, Math.INFINITY]), 'The array [ - Infinity, 0, Infinity ] return Infinity');
    }

    public function testGetTypedArray() {
        var buffer = new haxe.io.BytesBuffer(new ArrayBuffer());
        assertTrue( Std.is(Utils.getTypedArray('Int8Array', buffer), Int8Array), 'Int8Array' );
        assertTrue( Std.is(Utils.getTypedArray('Uint8Array', buffer), Uint8Array), 'Uint8Array' );
        assertTrue( Std.is(Utils.getTypedArray('Uint8ClampedArray', buffer), Uint8ClampedArray), 'Uint8ClampedArray' );
        assertTrue( Std.is(Utils.getTypedArray('Int16Array', buffer), Int16Array), 'Int16Array' );
        assertTrue( Std.is(Utils.getTypedArray('Uint16Array', buffer), Uint16Array), 'Uint16Array' );
        assertTrue( Std.is(Utils.getTypedArray('Int32Array', buffer), Int32Array), 'Int32Array' );
        assertTrue( Std.is(Utils.getTypedArray('Uint32Array', buffer), Uint32Array), 'Uint32Array' );
        assertTrue( Std.is(Utils.getTypedArray('Float32Array', buffer), Float32Array), 'Float32Array' );
        assertTrue( Std.is(Utils.getTypedArray('Float64Array', buffer), Float64Array), 'Float64Array' );
    }
}