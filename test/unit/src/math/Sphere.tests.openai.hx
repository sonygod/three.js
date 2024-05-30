package three.math;

import haxe.unit.TestCase;

class SphereTests {

    public function new() {}

    @Test
    public function instancing() {
        var a = new Sphere();
        assertEquals(a.center, Vector3.zero);
        assertEquals(a.radius, -1);

        a = new Sphere(Vector3.one.clone(), 1);
        assertEquals(a.center, Vector3.one);
        assertEquals(a.radius, 1);
    }

    @Test
    public function isSphere() {
        var a = new Sphere();
        assertTrue(a.isSphere);

        var b = new Box3();
        assertFalse(b.isSphere);
    }

    @Test
    public function set() {
        var a = new Sphere();
        assertEquals(a.center, Vector3.zero);
        assertEquals(a.radius, -1);

        a.set(Vector3.one, 1);
        assertEquals(a.center, Vector3.one);
        assertEquals(a.radius, 1);
    }

    @Test
    public function setFromPoints() {
        var a = new Sphere();
        var expectedCenter = new Vector3(0.9330126941204071, 0, 0);
        var expectedRadius = 1.3676668773461689;
        var optionalCenter = new Vector3(1, 1, 1);
        var points = [
            new Vector3(1, 1, 0), new Vector3(1, 1, 0),
            new Vector3(1, 1, 0), new Vector3(1, 1, 0),
            new Vector3(1, 1, 0), new Vector3(0.8660253882408142, 0.5, 0),
            new Vector3(-0, 0.5, 0.8660253882408142), new Vector3(1.8660253882408142, 0.5, 0),
            new Vector3(0, 0.5, -0.8660253882408142), new Vector3(0.8660253882408142, -0.5, 0),
            new Vector3(0.8660253882408142, -0.5, -0), new Vector3(-0, -0.5, 0.8660253882408142),
            new Vector3(1.8660253882408142, -0.5, 0), new Vector3(0, -0.5, -0.8660253882408142),
            new Vector3(0.8660253882408142, -0.5, -0), new Vector3(-0, -1, 0),
            new Vector3(-0, -1, 0), new Vector3(0, -1, 0),
            new Vector3(0, -1, -0), new Vector3(-0, -1, -0),
        ];

        a.setFromPoints(points);
        assertAlmostEqual(a.center.x, expectedCenter.x, 0.00001);
        assertAlmostEqual(a.center.y, expectedCenter.y, 0.00001);
        assertAlmostEqual(a.center.z, expectedCenter.z, 0.00001);
        assertAlmostEqual(a.radius, expectedRadius, 0.00001);

        expectedRadius = 2.5946195770400102;
        a.setFromPoints(points, optionalCenter);
        assertAlmostEqual(a.center.x, optionalCenter.x, 0.00001);
        assertAlmostEqual(a.center.y, optionalCenter.y, 0.00001);
        assertAlmostEqual(a.center.z, optionalCenter.z, 0.00001);
        assertAlmostEqual(a.radius, expectedRadius, 0.00001);
    }

    @Test
    public function clone() {
        // todo
    }

    @Test
    public function copy() {
        var a = new Sphere(Vector3.one.clone(), 1);
        var b = new Sphere().copy(a);

        assertEquals(b.center, Vector3.one);
        assertEquals(b.radius, 1);

        a.center = Vector3.zero;
        a.radius = 0;
        assertEquals(b.center, Vector3.one);
        assertEquals(b.radius, 1);
    }

    @Test
    public function isEmpty() {
        var a = new Sphere();
        assertTrue(a.isEmpty);

        a.set(Vector3.one, 1);
        assertFalse(a.isEmpty);

        // Negative radius contains no points
        a.set(Vector3.one, -1);
        assertTrue(a.isEmpty);

        // Zero radius contains only the center point
        a.set(Vector3.one, 0);
        assertFalse(a.isEmpty);
    }

    @Test
    public function makeEmpty() {
        var a = new Sphere(Vector3.one.clone(), 1);

        assertFalse(a.isEmpty);

        a.makeEmpty();
        assertTrue(a.isEmpty);
        assertEquals(a.center, Vector3.zero);
    }

    @Test
    public function containsPoint() {
        var a = new Sphere(Vector3.one.clone(), 1);

        assertFalse(a.containsPoint(Vector3.zero));
        assertTrue(a.containsPoint(Vector3.one));

        a.set(Vector3.zero, 0);
        assertTrue(a.containsPoint(a.center));
    }

    @Test
    public function distanceToPoint() {
        var a = new Sphere(Vector3.one.clone(), 1);

        assertEquals(a.distanceToPoint(Vector3.zero), 0.7320, 0.001);
        assertEquals(a.distanceToPoint(Vector3.one), -1);
    }

    @Test
    public function intersectsSphere() {
        var a = new Sphere(Vector3.one.clone(), 1);
        var b = new Sphere(Vector3.zero.clone(), 1);
        var c = new Sphere(Vector3.zero.clone(), 0.25);

        assertTrue(a.intersectsSphere(b));
        assertFalse(a.intersectsSphere(c));
    }

    @Test
    public function intersectsBox() {
        var a = new Sphere(Vector3.zero, 1);
        var b = new Sphere(new Vector3(-5, -5, -5), 1);
        var box = new Box3(Vector3.zero, Vector3.one);

        assertTrue(a.intersectsBox(box));
        assertFalse(b.intersectsBox(box));
    }

    @Test
    public function intersectsPlane() {
        var a = new Sphere(Vector3.zero.clone(), 1);
        var b = new Plane(new Vector3(0, 1, 0), 1);
        var c = new Plane(new Vector3(0, 1, 0), 1.25);
        var d = new Plane(new Vector3(0, -1, 0), 1.25);

        assertTrue(a.intersectsPlane(b));
        assertFalse(a.intersectsPlane(c));
        assertFalse(a.intersectsPlane(d));
    }

    @Test
    public function clampPoint() {
        var a = new Sphere(Vector3.one.clone(), 1);
        var point = new Vector3();

        a.clampPoint(new Vector3(1, 1, 3), point);
        assertEquals(point, new Vector3(1, 1, 2));

        a.clampPoint(new Vector3(1, 1, -3), point);
        assertEquals(point, new Vector3(1, 1, 0));
    }

    @Test
    public function getBoundingBox() {
        var a = new Sphere(Vector3.one.clone(), 1);
        var aabb = new Box3();

        a.getBoundingBox(aabb);
        assertEquals(aabb, new Box3(Vector3.zero, Vector3.two));

        a.set(Vector3.zero, 0);
        a.getBoundingBox(aabb);
        assertEquals(aabb, new Box3(Vector3.zero, Vector3.zero));

        // Empty sphere produces empty bounding box
        a.makeEmpty();
        a.getBoundingBox(aabb);
        assertTrue(aabb.isEmpty());
    }

    @Test
    public function applyMatrix4() {
        var a = new Sphere(Vector3.one.clone(), 1);
        var m = new Matrix4().makeTranslation(1, -2, 1);
        var aabb1 = new Box3();
        var aabb2 = new Box3();

        a.clone().applyMatrix4(m).getBoundingBox(aabb1);
        a.getBoundingBox(aabb2);

        assertEquals(aabb1, aabb2.applyMatrix4(m));
    }

    @Test
    public function translate() {
        var a = new Sphere(Vector3.one.clone(), 1);

        a.translate(Vector3.one.clone().negate());
        assertEquals(a.center, Vector3.zero);
    }

    @Test
    public function expandByPoint() {
        var a = new Sphere(Vector3.zero.clone(), 1);
        var p = new Vector3(2, 0, 0);

        assertFalse(a.containsPoint(p));

        a.expandByPoint(p);

        assertTrue(a.containsPoint(p));
        assertEquals(a.center, new Vector3(0.5, 0, 0));
        assertEquals(a.radius, 1.5);
    }

    @Test
    public function union() {
        var a = new Sphere(Vector3.zero.clone(), 1);
        var b = new Sphere(new Vector3(2, 0, 0), 1);

        a.union(b);

        assertEquals(a.center, new Vector3(1, 0, 0));
        assertEquals(a.radius, 2);

        // d contains c (demonstrates why it is necessary to process two points in union)

        var c = new Sphere(Vector3.zero.clone(), 1);
        var d = new Sphere(new Vector3(1, 0, 0), 4);

        c.union(d);

        assertEquals(c.center, new Vector3(1, 0, 0));
        assertEquals(c.radius, 4);

        // edge case: both spheres have the same center point

        var e = new Sphere(Vector3.zero.clone(), 1);
        var f = new Sphere(Vector3.zero.clone(), 4);

        e.union(f);

        assertEquals(e.center, new Vector3(0, 0, 0));
        assertEquals(e.radius, 4);
    }

    @Test
    public function equals() {
        var a = new Sphere();
        var b = new Sphere(new Vector3(1, 0, 0));
        var c = new Sphere(new Vector3(1, 0, 0), 1.0);

        assertFalse(a.equals(b));
        assertFalse(a.equals(c));
        assertFalse(b.equals(c));

        a.copy(b);
        assertTrue(a.equals(b));
    }
}