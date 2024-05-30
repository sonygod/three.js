package ;

import haxe.unit.TestCase;

class Vector4Test {
    public function new() {}

    public function testInstancing() {
        var a = new Vector4();
        assertEquals(a.x, 0);
        assertEquals(a.y, 0);
        assertEquals(a.z, 0);
        assertEquals(a.w, 1);

        a = new Vector4(x, y, z, w);
        assertEquals(a.x, x);
        assertEquals(a.y, y);
        assertEquals(a.z, z);
        assertEquals(a.w, w);
    }

    public function testSet() {
        var a = new Vector4();
        assertEquals(a.x, 0);
        assertEquals(a.y, 0);
        assertEquals(a.z, 0);
        assertEquals(a.w, 1);

        a.set(x, y, z, w);
        assertEquals(a.x, x);
        assertEquals(a.y, y);
        assertEquals(a.z, z);
        assertEquals(a.w, w);
    }

    // ... (rest of the tests)

    public function testAdd() {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);

        a.add(b);
        assertEquals(a.x, 0);
        assertEquals(a.y, 0);
        assertEquals(a.z, 0);
        assertEquals(a.w, 0);
    }

    public function testAddScaledVector() {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);
        var s = 3;

        a.addScaledVector(b, s);
        assertEquals(a.x, x - x * s);
        assertEquals(a.y, y - y * s);
        assertEquals(a.z, z - z * s);
        assertEquals(a.w, w - w * s);
    }

    public function testSub() {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);

        a.sub(b);
        assertEquals(a.x, 2 * x);
        assertEquals(a.y, 2 * y);
        assertEquals(a.z, 2 * z);
        assertEquals(a.w, 2 * w);
    }

    public function testMultiplyScalar() {
        var a = new Vector4(x, y, z, w);
        var s = 2;

        a.multiplyScalar(s);
        assertEquals(a.x, x * s);
        assertEquals(a.y, y * s);
        assertEquals(a.z, z * s);
        assertEquals(a.w, w * s);
    }

    // ... (rest of the tests)
}