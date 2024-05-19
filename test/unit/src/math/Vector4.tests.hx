Here is the converted Haxe code:
```
package three.math;

import haxe.unit.TestCase;

class Vector4Test {
    public function new() {}

    @Test
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

    @Test
    public function testIsVector4() {
        var object = new Vector4();
        assertTrue(object.isVector4);
    }

    @Test
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

    @Test
    public function testSetX() {
        var a = new Vector4();
        assertEquals(a.x, 0);

        a.setX(x);
        assertEquals(a.x, x);
    }

    @Test
    public function testSetY() {
        var a = new Vector4();
        assertEquals(a.y, 0);

        a.setY(y);
        assertEquals(a.y, y);
    }

    @Test
    public function testSetZ() {
        var a = new Vector4();
        assertEquals(a.z, 0);

        a.setZ(z);
        assertEquals(a.z, z);
    }

    @Test
    public function testSetW() {
        var a = new Vector4();
        assertEquals(a.w, 1);

        a.setW(w);
        assertEquals(a.w, w);
    }

    @Test
    public function testAdd() {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);

        a.add(b);
        assertEquals(a.x, 0);
        assertEquals(a.y, 0);
        assertEquals(a.z, 0);
        assertEquals(a.w, 0);
    }

    @Test
    public function testAddVectors() {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);
        var c = new Vector4().addVectors(a, b);

        assertEquals(c.x, 0);
        assertEquals(c.y, 0);
        assertEquals(c.z, 0);
        assertEquals(c.w, 0);
    }

    @Test
    public function testAddScaledVector() {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(6, 7, 8, 9);
        var s = 3;

        a.addScaledVector(b, s);
        assertEquals(a.x, x + b.x * s);
        assertEquals(a.y, y + b.y * s);
        assertEquals(a.z, z + b.z * s);
        assertEquals(a.w, w + b.w * s);
    }

    @Test
    public function testSub() {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);

        a.sub(b);
        assertEquals(a.x, 2 * x);
        assertEquals(a.y, 2 * y);
        assertEquals(a.z, 2 * z);
        assertEquals(a.w, 2 * w);
    }

    @Test
    public function testSubVectors() {
        var a = new Vector4(x, y, z, w);
        var b = new Vector4(-x, -y, -z, -w);
        var c = new Vector4().subVectors(a, b);

        assertEquals(c.x, 2 * x);
        assertEquals(c.y, 2 * y);
        assertEquals(c.z, 2 * z);
        assertEquals(c.w, 2 * w);
    }

    @Test
    public function testMultiplyScalar() {
        var a = new Vector4(x, y, z, w);

        a.multiplyScalar(2