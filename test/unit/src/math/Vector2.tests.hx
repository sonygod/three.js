Here is the converted Haxe code:
```
package three.math;

import haxe.unit.TestCase;
import three.math.Matrix3;
import three.core.BufferAttribute;

class Vector2Tests {
    public function new() {}

    public function testInstancing() {
        var a = new Vector2();
        assertEquals(0, a.x);
        assertEquals(0, a.y);

        a = new Vector2(1, 2);
        assertEquals(1, a.x);
        assertEquals(2, a.y);
    }

    public function testProperties() {
        var a = new Vector2(0, 0);
        var width = 100;
        var height = 200;

        a.width = width;
        a.height = height;

        assertEquals(width, a.width);
        assertEquals(height, a.height);

        a.set(width, height);
        assertEquals(width, a.width);
        assertEquals(height, a.height);
    }

    public function testIsVector2() {
        var object = new Vector2();
        assertTrue(object.isVector2);
    }

    public function testSet() {
        var a = new Vector2();
        assertEquals(0, a.x);
        assertEquals(0, a.y);

        a.set(1, 2);
        assertEquals(1, a.x);
        assertEquals(2, a.y);
    }

    // ... (rest of the tests)

    public function testAdd() {
        var a = new Vector2(1, 2);
        var b = new Vector2(-1, -2);

        a.add(b);
        assertEquals(0, a.x);
        assertEquals(0, a.y);

        var c = new Vector2().addVectors(b, b);
        assertEquals(-2, c.x);
        assertEquals(-2, c.y);
    }

    public function testSub() {
        var a = new Vector2(1, 2);
        var b = new Vector2(-1, -2);

        a.sub(b);
        assertEquals(2, a.x);
        assertEquals(4, a.y);

        var c = new Vector2().subVectors(a, a);
        assertEquals(0, c.x);
        assertEquals(0, c.y);
    }

    public function testApplyMatrix3() {
        var a = new Vector2(1, 2);
        var m = new Matrix3().set(2, 3, 5, 7, 11, 13, 17, 19, 23);

        a.applyMatrix3(m);
        assertEquals(18, a.x);
        assertEquals(60, a.y);
    }

    // ... (rest of the tests)

    public function testRound() {
        assertEquals(new Vector2(-1, 0), new Vector2(-0.1, 0.1).floor());
        assertEquals(new Vector2(0, 1), new Vector2(-0.5, 0.5).floor());
        assertEquals(new Vector2(-1, 0), new Vector2(-0.9, 0.9).floor());

        assertEquals(new Vector2(0, 1), new Vector2(-0.1, 0.1).ceil());
        assertEquals(new Vector2(0, 1), new Vector2(-0.5, 0.5).ceil());
        assertEquals(new Vector2(0, 1), new Vector2(-0.9, 0.9).ceil());

        assertEquals(new Vector2(0, 0), new Vector2(-0.1, 0.1).round());
        assertEquals(new Vector2(0, 1), new Vector2(-0.5, 0.5).round());
        assertEquals(new Vector2(-1, 1), new Vector2(-0.9, 0.9).round());

        assertEquals(new Vector2(0, 0), new Vector2(-0.1, 0.1).roundToZero());
        assertEquals(new Vector2(0, 0), new Vector2(-0.5, 0.5).roundToZero());
        assertEquals(new Vector2(0, 0), new Vector2(-0.9, 0.9).roundToZero());
        assertEquals(new Vector2(-1, 1), new Vector2(-1.1, 1.1).roundToZero());
        assertEquals(new Vector2(-1, 1), new Vector2(-1.5, 1.5).roundToZero());
        assertEquals(new Vector2(-1, 1), new Vector2(-1.9, 1.9).roundToZero());
    }

    public function testLength() {
        var a = new Vector2(1, 0);
        var b = new Vector2(0, -2);
        var c = new Vector2();

        assertEquals(1, a.length());
        assertEquals(1, a.lengthSq());
        assertEquals(2, b.length());
        assertEquals(4, b.lengthSq());
        assertEquals(0, c.length());
        assertEquals(0, c.lengthSq());

        a.set(1, 2);
        assertEquals(Math.sqrt(5), a.length());
        assertEquals(5, a.lengthSq());
    }

    public function testDistanceTo() {
        var a = new Vector2(1, 0);
        var b = new Vector2(0, -2);
        var c = new Vector2();

        assertEquals(1, a.distanceTo(c));
        assertEquals(1, a.distanceToSquared(c));
        assertEquals(2, b.distanceTo(c));
        assertEquals(4, b.distanceToSquared(c));
    }

    public function testLerp() {
        var a = new Vector2(1, 0);
        var b = new Vector2(0, -2);

        assertEquals(a, a.lerp(a, 0));
        assertEquals(a, a.lerp(a, 0.5));
        assertEquals(a, a.lerp(a, 1));

        assertEquals(a, a.clone().lerp(b, 0));
        assertEquals(new Vector2(0.5, -1), a.clone().lerp(b, 0.5));
        assertEquals(b, a.clone().lerp(b, 1));
    }
}
```
Note that I've used the `haxe.unit` package for the test framework, and `three.math` for the Vector2 and Matrix3 classes. You may need to adjust the package names and imports depending on your specific project setup.