package three.math;

import haxe.unit.TestCase;
import three.bufferattribute.BufferAttribute;
import three.math.Box3;
import three.math.Plane;
import three.math.Vector3;

class TriangleTest {

    public function new() {}

    public function testInstancing() {
        var a = new Triangle();
        assertTrue(a.a.equals(Vector3.zero));
        assertTrue(a.b.equals(Vector3.zero));
        assertTrue(a.c.equals(Vector3.zero));

        a = new Triangle(Vector3.one.negate(), Vector3.one, Vector3.two);
        assertTrue(a.a.equals(Vector3.one.negate()));
        assertTrue(a.b.equals(Vector3.one));
        assertTrue(a.c.equals(Vector3.two));
    }

    public function testGetNormal() {
        // todo
        assertTrue(false);
    }

    public function testGetBarycoord() {
        // todo
        assertTrue(false);
    }

    public function testContainsPoint() {
        // todo
        assertTrue(false);
    }

    public function testGetInterpolation() {
        // todo
        assertTrue(false);
    }

    public function testIsFrontFacing() {
        // todo
        assertTrue(false);
    }

    public function testSet() {
        var a = new Triangle();
        a.set(Vector3.one.negate(), Vector3.one, Vector3.two);
        assertTrue(a.a.equals(Vector3.one.negate()));
        assertTrue(a.b.equals(Vector3.one));
        assertTrue(a.c.equals(Vector3.two));
    }

    public function testSetFromPointsAndIndices() {
        var a = new Triangle();
        var points = [Vector3.one, Vector3.one.negate(), Vector3.two];
        a.setFromPointsAndIndices(points, 1, 0, 2);
        assertTrue(a.a.equals(Vector3.one.negate()));
        assertTrue(a.b.equals(Vector3.one));
        assertTrue(a.c.equals(Vector3.two));
    }

    public function testSetFromAttributeAndIndices() {
        var a = new Triangle();
        var attribute = new BufferAttribute(new Float32Array([1, 1, 1, -1, -1, -1, 2, 2, 2]), 3);
        a.setFromAttributeAndIndices(attribute, 1, 0, 2);
        assertTrue(a.a.equals(Vector3.one.negate()));
        assertTrue(a.b.equals(Vector3.one));
        assertTrue(a.c.equals(Vector3.two));
    }

    public function testClone() {
        // todo
        assertTrue(false);
    }

    public function testCopy() {
        var a = new Triangle(Vector3.one.negate(), Vector3.one, Vector3.two);
        var b = new Triangle().copy(a);
        assertTrue(b.a.equals(Vector3.one.negate()));
        assertTrue(b.b.equals(Vector3.one));
        assertTrue(b.c.equals(Vector3.two));

        a.a = Vector3.one;
        a.b = Vector3.zero;
        a.c = Vector3.zero;
        assertTrue(b.a.equals(Vector3.one.negate()));
        assertTrue(b.b.equals(Vector3.one));
        assertTrue(b.c.equals(Vector3.two));
    }

    public function testGetArea() {
        var a = new Triangle();
        assertEquals(a.getArea(), 0);

        a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        assertEquals(a.getArea(), 0.5);

        a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
        assertEquals(a.getArea(), 2);

        a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(3, 0, 0));
        assertEquals(a.getArea(), 0);
    }

    public function testGetMidpoint() {
        var a = new Triangle();
        var midpoint = new Vector3();
        a.getMidpoint(midpoint);
        assertTrue(midpoint.equals(Vector3.zero));

        a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        a.getMidpoint(midpoint);
        assertTrue(midpoint.equals(new Vector3(1/3, 1/3, 0)));

        a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
        a.getMidpoint(midpoint);
        assertTrue(midpoint.equals(new Vector3(2/3, 0, 2/3)));
    }

    public function testGetNormal() {
        var a = new Triangle();
        var normal = new Vector3();
        a.getNormal(normal);
        assertTrue(normal.equals(Vector3.zero));

        a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        a.getNormal(normal);
        assertTrue(normal.equals(new Vector3(0, 0, 1)));

        a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
        a.getNormal(normal);
        assertTrue(normal.equals(new Vector3(0, 1, 0)));
    }

    public function testGetPlane() {
        var a = new Triangle();
        var plane = new Plane();
        a.getPlane(plane);
        assertNotNull(plane.normal);
        assertNotNull(plane.constant);

        a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        a.getPlane(plane);
        assertTrue(plane.normal.equals(new Vector3(0, 0, 1)));
        assertEquals(plane.constant, 0);

        a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
        a.getPlane(plane);
        assertTrue(plane.normal.equals(new Vector3(0, 1, 0)));
        assertEquals(plane.constant, 0);
    }

    public function testGetBarycoord() {
        var a = new Triangle();
        var barycoord = new Vector3();
        a.getBarycoord(Vector3.zero, barycoord);
        assertTrue(barycoord.equals(Vector3.zero));

        a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        a.getBarycoord(a.a, barycoord);
        assertTrue(barycoord.equals(new Vector3(1, 0, 0)));
        a.getBarycoord(a.b, barycoord);
        assertTrue(barycoord.equals(new Vector3(0, 1, 0)));
        a.getBarycoord(a.c, barycoord);
        assertTrue(barycoord.equals(new Vector3(0, 0, 1)));
    }

    public function testContainsPoint() {
        var a = new Triangle();
        assertTrue(!a.containsPoint(Vector3.zero));

        a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        assertTrue(a.containsPoint(a.a));
        assertTrue(a.containsPoint(a.b));
        assertTrue(a.containsPoint(a.c));

        a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
        assertTrue(a.containsPoint(a.a));
        assertTrue(a.containsPoint(a.b));
        assertTrue(a.containsPoint(a.c));
    }

    public function testIntersectsBox() {
        var a = new Triangle(new Vector3(1.5, 1.5, 2.5), new Vector3(2.5, 1.5, 1.5), new Vector3(1.5, 2.5, 1.5));
        var box = new Box3(new Vector3(1, 1, 1), new Vector3(3, 3, 3));
        assertTrue(a.intersectsBox(box));
    }

    public function testClosestPointToPoint() {
        var a = new Triangle(new Vector3(-1, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        var point = new Vector3();
        a.closestPointToPoint(new Vector3(0, 0.5, 0), point);
        assertTrue(point.equals(new Vector3(0, 0.5, 0)));

        a.closestPointToPoint(a.a, point);
        assertTrue(point.equals(a.a));

        a.closestPointToPoint(a.b, point);
        assertTrue(point.equals(a.b));

        a.closestPointToPoint(a.c, point);
        assertTrue(point.equals(a.c));
    }

    public function testIsFrontFacing() {
        var a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        var dir = new Vector3(0, 0, -1);
        assertTrue(a.isFrontFacing(dir));
    }

    public function testEquals() {
        var a = new Triangle(new Vector3(1, 0, 0), new Vector3(0, 1, 0), new Vector3(0, 0, 1));
        var b = new Triangle(new Vector3(0, 0, 1), new Vector3(0, 1, 0), new Vector3(1, 0, 0));
        var c = new Triangle(new Vector3(-1, 0, 0), new Vector3(0, 1, 0), new Vector3(0, 0, 1));

        assertTrue(a.equals(a));
        assertFalse(a.equals(b));
        assertFalse(a.equals(c));
        assertFalse(b.equals(c));

        a.copy(b);
        assertTrue(a.equals(a));
    }
}