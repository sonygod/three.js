import haxe.unit.TestCase;
import three.math.Euler;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector3;

class EulerTest {
    public function new() {}

    public function testInstancing() {
        var a = new Euler();
        assertEquals(a, new Euler(0, 0, 0, 'XYZ'));
        assertNotEquals(a, new Euler(1, 0, 0, 'XYZ'));
        assertNotEquals(a, new Euler(0, 1, 0, 'ZYX'));
    }

    public function testDEFAULT_ORDER() {
        assertEquals(Euler.DEFAULT_ORDER, 'XYZ');
    }

    public function testX() {
        var a = new Euler();
        assertEquals(a.x, 0);
        a = new Euler(1, 2, 3);
        assertEquals(a.x, 1);
        a = new Euler(4, 5, 6, 'XYZ');
        assertEquals(a.x, 4);
        a = new Euler(7, 8, 9, 'XYZ');
        a.x = 10;
        assertEquals(a.x, 10);
        a = new Euler(11, 12, 13, 'XYZ');
        var b = false;
        a.onChange(function() {
            b = true;
        });
        a.x = 14;
        assertTrue(b);
        assertEquals(a.x, 14);
    }

    public function testY() {
        var a = new Euler();
        assertEquals(a.y, 0);
        a = new Euler(1, 2, 3);
        assertEquals(a.y, 2);
        a = new Euler(4, 5, 6, 'XYZ');
        assertEquals(a.y, 5);
        a = new Euler(7, 8, 9, 'XYZ');
        a.y = 10;
        assertEquals(a.y, 10);
        a = new Euler(11, 12, 13, 'XYZ');
        var b = false;
        a.onChange(function() {
            b = true;
        });
        a.y = 14;
        assertTrue(b);
        assertEquals(a.y, 14);
    }

    public function testZ() {
        var a = new Euler();
        assertEquals(a.z, 0);
        a = new Euler(1, 2, 3);
        assertEquals(a.z, 3);
        a = new Euler(4, 5, 6, 'XYZ');
        assertEquals(a.z, 6);
        a = new Euler(7, 8, 9, 'XYZ');
        a.z = 10;
        assertEquals(a.z, 10);
        a = new Euler(11, 12, 13, 'XYZ');
        var b = false;
        a.onChange(function() {
            b = true;
        });
        a.z = 14;
        assertTrue(b);
        assertEquals(a.z, 14);
    }

    public function testOrder() {
        var a = new Euler();
        assertEquals(a.order, Euler.DEFAULT_ORDER);
        a = new Euler(1, 2, 3);
        assertEquals(a.order, Euler.DEFAULT_ORDER);
        a = new Euler(4, 5, 6, 'YZX');
        assertEquals(a.order, 'YZX');
        a = new Euler(7, 8, 9, 'YZX');
        a.order = 'ZXY';
        assertEquals(a.order, 'ZXY');
        a = new Euler(11, 12, 13, 'YZX');
        var b = false;
        a.onChange(function() {
            b = true;
        });
        a.order = 'ZXY';
        assertTrue(b);
        assertEquals(a.order, 'ZXY');
    }

    public function testIsEuler() {
        var a = new Euler();
        assertTrue(a.isEuler);
        var b = new Vector3();
        assertFalse(b.isEuler);
    }

    public function testCloneCopyEquals() {
        var a = eulerAxyz.clone();
        assertEquals(a, eulerAxyz);
        assertNotEquals(a, eulerZero);
        assertNotEquals(a, eulerAzyx);
        a.copy(eulerAzyx);
        assertEquals(a, eulerAzyx);
        assertNotEquals(a, eulerAxyz);
        assertNotEquals(a, eulerZero);
    }

    public function testQuaternionSetFromEulerEulerSetFromQuaternion() {
        var testValues = [eulerZero, eulerAxyz, eulerAzyx];
        for (value in testValues) {
            var q = new Quaternion().setFromEuler(value);
            var v2 = new Euler().setFromQuaternion(q, value.order);
            var q2 = new Quaternion().setFromEuler(v2);
            assertTrue(quatEquals(q, q2));
        }
    }

    public function testMatrix4MakeRotationFromEulerEulerSetFromRotationMatrix() {
        var testValues = [eulerZero, eulerAxyz, eulerAzyx];
        for (value in testValues) {
            var m = new Matrix4().makeRotationFromEuler(value);
            var v2 = new Euler().setFromRotationMatrix(m, value.order);
            var m2 = new Matrix4().makeRotationFromEuler(v2);
            assertTrue(matrixEquals4(m, m2, 0.0001));
        }
    }

    public function testReorder() {
        var testValues = [eulerZero, eulerAxyz, eulerAzyx];
        for (value in testValues) {
            var q = new Quaternion().setFromEuler(value);
            value.reorder('YZX');
            var q2 = new Quaternion().setFromEuler(value);
            assertTrue(quatEquals(q, q2));
            value.reorder('ZXY');
            var q3 = new Quaternion().setFromEuler(value);
            assertTrue(quatEquals(q, q3));
        }
    }

    public function testSetGetPropertiesCheckCallbacks() {
        var a = new Euler();
        a.onChange(function() {
            assertTrue(true);
        });
        a.x = 1;
        a.y = 2;
        a.z = 3;
        a.order = 'ZYX';
        assertEquals(a.x, 1);
        assertEquals(a.y, 2);
        assertEquals(a.z, 3);
        assertEquals(a.order, 'ZYX');
    }

    public function testCloneCopyCheckCallbacks() {
        var a = new Euler(1, 2, 3, 'ZXY');
        var b = new Euler(4, 5, 6, 'XZY');
        var cbSucceed = function() {
            assertTrue(true);
        };
        var cbFail = function() {
            assertFalse(true);
        };
        a.onChange(cbFail);
        b.onChange(cbFail);
        a = b.clone();
        assertEquals(a, b);
        a = new Euler(1, 2, 3, 'ZXY');
        a.onChange(cbSucceed);
        a.copy(b);
        assertEquals(a, b);
    }

    public function testToArray() {
        var order = 'YXZ';
        var a = new Euler(x, y, z, order);
        var array = a.toArray();
        assertEquals(array[0], x);
        assertEquals(array[1], y);
        assertEquals(array[2], z);
        assertEquals(array[3], order);
        array = [];
        a.toArray(array);
        assertEquals(array[0], x);
        assertEquals(array[1], y);
        assertEquals(array[2], z);
        assertEquals(array[3], order);
        array = [];
        a.toArray(array, 1);
        assertEquals(array[0], null);
        assertEquals(array[1], x);
        assertEquals(array[2], y);
        assertEquals(array[3], z);
        assertEquals(array[4], order);
    }

    public function testFromArray() {
        var a = new Euler();
        var array = [x, y, z];
        var cb = function() {
            assertTrue(true);
        };
        a.onChange(cb);
        a.fromArray(array);
        assertEquals(a.x, x);
        assertEquals(a.y, y);
        assertEquals(a.z, z);
        assertEquals(a.order, 'XYZ');
        a = new Euler();
        array = [x, y, z, 'ZXY'];
        a.onChange(cb);
        a.fromArray(array);
        assertEquals(a.x, x);
        assertEquals(a.y, y);
        assertEquals(a.z, z);
        assertEquals(a.order, 'ZXY');
    }

    public function testOnChange() {
        var f = function() {};
        var a = new Euler(11, 12, 13, 'XYZ');
        a.onChange(f);
        assertEquals(a._onChangeCallback, f);
    }

    public function testOnChangeCallback() {
        var b = false;
        var a = new Euler(11, 12, 13, 'XYZ');
        var f = function() {
            b = true;
            assertEquals(a, this);
        };
        a._onChangeCallback = f;
        assertEquals(a._onChangeCallback, f);
        a._onChangeCallback();
        assertTrue(b);
    }

    public function testIterable() {
        var e = new Euler(0.5, 0.75, 1, 'YZX');
        var array = [for (v in e) v];
        assertEquals(array[0], 0.5);
        assertEquals(array[1], 0.75);
        assertEquals(array[2], 1);
        assertEquals(array[3], 'YZX');
    }
}