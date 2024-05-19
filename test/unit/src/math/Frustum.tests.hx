package three.math;

import haxe.unit.TestCase;
import three.math.Frustum;
import three.math.Plane;
import three.math.Sphere;
import three.math.Vector3;
import three.math.Matrix4;
import three.math.Box3;
import three.objects.Mesh;
import three.geometries.BoxGeometry;
import three.objects.Sprite;

class FrustumTests {

    public function new() {}

    public function testInstancing() {
        var a = new Frustum();
        assertTrue(a.planes != null, 'Passed!');
        assertEquals(a.planes.length, 6, 'Passed!');

        var pDefault = new Plane();
        for (i in 0...6) {
            assertEquals(a.planes[i], pDefault, 'Passed!');
        }

        var p0 = new Plane(unit3, -1);
        var p1 = new Plane(unit3, 1);
        var p2 = new Plane(unit3, 2);
        var p3 = new Plane(unit3, 3);
        var p4 = new Plane(unit3, 4);
        var p5 = new Plane(unit3, 5);

        a = new Frustum(p0, p1, p2, p3, p4, p5);
        assertEquals(a.planes[0], p0, 'Passed!');
        assertEquals(a.planes[1], p1, 'Passed!');
        assertEquals(a.planes[2], p2, 'Passed!');
        assertEquals(a.planes[3], p3, 'Passed!');
        assertEquals(a.planes[4], p4, 'Passed!');
        assertEquals(a.planes[5], p5, 'Passed!');
    }

    public function testSet() {
        var a = new Frustum();
        var p0 = new Plane(unit3, -1);
        var p1 = new Plane(unit3, 1);
        var p2 = new Plane(unit3, 2);
        var p3 = new Plane(unit3, 3);
        var p4 = new Plane(unit3, 4);
        var p5 = new Plane(unit3, 5);

        a.set(p0, p1, p2, p3, p4, p5);

        assertEquals(a.planes[0], p0, 'Check plane #0');
        assertEquals(a.planes[1], p1, 'Check plane #1');
        assertEquals(a.planes[2], p2, 'Check plane #2');
        assertEquals(a.planes[3], p3, 'Check plane #3');
        assertEquals(a.planes[4], p4, 'Check plane #4');
        assertEquals(a.planes[5], p5, 'Check plane #5');
    }

    public function testClone() {
        var p0 = new Plane(unit3, -1);
        var p1 = new Plane(unit3, 1);
        var p2 = new Plane(unit3, 2);
        var p3 = new Plane(unit3, 3);
        var p4 = new Plane(unit3, 4);
        var p5 = new Plane(unit3, 5);

        var b = new Frustum(p0, p1, p2, p3, p4, p5);
        var a = b.clone();

        assertEquals(a.planes[0], p0, 'Passed!');
        assertEquals(a.planes[1], p1, 'Passed!');
        assertEquals(a.planes[2], p2, 'Passed!');
        assertEquals(a.planes[3], p3, 'Passed!');
        assertEquals(a.planes[4], p4, 'Passed!');
        assertEquals(a.planes[5], p5, 'Passed!');

        // ensure it is a true copy by modifying source
        a.planes[0].copy(p1);
        assertEquals(b.planes[0], p0, 'Passed!');
    }

    public function testCopy() {
        var p0 = new Plane(unit3, -1);
        var p1 = new Plane(unit3, 1);
        var p2 = new Plane(unit3, 2);
        var p3 = new Plane(unit3, 3);
        var p4 = new Plane(unit3, 4);
        var p5 = new Plane(unit3, 5);

        var b = new Frustum(p0, p1, p2, p3, p4, p5);
        var a = new Frustum().copy(b);

        assertEquals(a.planes[0], p0, 'Passed!');
        assertEquals(a.planes[1], p1, 'Passed!');
        assertEquals(a.planes[2], p2, 'Passed!');
        assertEquals(a.planes[3], p3, 'Passed!');
        assertEquals(a.planes[4], p4, 'Passed!');
        assertEquals(a.planes[5], p5, 'Passed!');

        // ensure it is a true copy by modifying source
        b.planes[0] = p1;
        assertEquals(a.planes[0], p0, 'Passed!');
    }

    public function testSetFromProjectionMatrixMakeOrthographicContainsPoint() {
        var m = new Matrix4().makeOrthographic(-1, 1, -1, 1, 1, 100);
        var a = new Frustum().setFromProjectionMatrix(m);

        assertFalse(a.containsPoint(new Vector3(0, 0, 0)), 'Passed!');
        assertTrue(a.containsPoint(new Vector3(0, 0, -50)), 'Passed!');
        assertTrue(a.containsPoint(new Vector3(0, 0, -1.001)), 'Passed!');
        assertTrue(a.containsPoint(new Vector3(-1, -1, -1.001)), 'Passed!');
        assertFalse(a.containsPoint(new Vector3(-1.1, -1.1, -1.001)), 'Passed!');
        assertTrue(a.containsPoint(new Vector3(1, 1, -1.001)), 'Passed!');
        assertFalse(a.containsPoint(new Vector3(1.1, 1.1, -1.001)), 'Passed!');
        assertTrue(a.containsPoint(new Vector3(0, 0, -99.999)), 'Passed!');
        assertTrue(a.containsPoint(new Vector3(-99.999, -99.999, -99.999)), 'Passed!');
        assertFalse(a.containsPoint(new Vector3(-100.1, -100.1, -100.1)), 'Passed!');
        assertTrue(a.containsPoint(new Vector3(99.999, 99.999, -99.999)), 'Passed!');
        assertFalse(a.containsPoint(new Vector3(100.1, 100.1, -100.1)), 'Passed!');
        assertFalse(a.containsPoint(new Vector3(0, 0, -101)), 'Passed!');
    }

    public function testSetFromProjectionMatrixMakePerspectiveContainsPoint() {
        var m = new Matrix4().makePerspective(-1, 1, 1, -1, 1, 100);
        var a = new Frustum().setFromProjectionMatrix(m);

        assertFalse(a.containsPoint(new Vector3(0, 0, 0)), 'Passed!');
        assertTrue(a.containsPoint(new Vector3(0, 0, -50)), 'Passed!');
        assertTrue(a.containsPoint(new Vector3(0, 0, -1.001)), 'Passed!');
        assertTrue(a.containsPoint(new Vector3(-1, -1, -1.001)), 'Passed!');
        assertFalse(a.containsPoint(new Vector3(-1.1, -1.1, -1.001)), 'Passed!');
        assertTrue(a.containsPoint(new Vector3(1, 1, -1.001)), 'Passed!');
        assertFalse(a.containsPoint(new Vector3(1.1, 1.1, -1.001)), 'Passed!');
        assertTrue(a.containsPoint(new Vector3(0, 0, -99.999)), 'Passed!');
        assertTrue(a.containsPoint(new Vector3(-99.999, -99.999, -99.999)), 'Passed!');
        assertFalse(a.containsPoint(new Vector3(-100.1, -100.1, -100.1)), 'Passed!');
        assertTrue(a.containsPoint(new Vector3(99.999, 99.999, -99.999)), 'Passed!');
        assertFalse(a.containsPoint(new Vector3(100.1, 100.1, -100.1)), 'Passed!');
        assertFalse(a.containsPoint(new Vector3(0, 0, -101)), 'Passed!');
    }

    public function testSetFromProjectionMatrixMakePerspectiveIntersectsSphere() {
        var m = new Matrix4().makePerspective(-1, 1, 1, -1, 1, 100);
        var a = new Frustum().setFromProjectionMatrix(m);

        assertFalse(a.intersectsSphere(new Sphere(new Vector3(0, 0, 0), 0)), 'Passed!');
        assertFalse(a.intersectsSphere(new Sphere(new Vector3(0, 0, 0), 0.9)), 'Passed!');
        assertTrue(a.intersectsSphere(new Sphere(new Vector3(0, 0, 0), 1.1)), 'Passed!');
        assertTrue(a.intersectsSphere(new Sphere(new Vector3(0, 0, -50), 0)), 'Passed!');
        assertTrue(a.intersectsSphere(new Sphere(new Vector3(0, 0, -1.001), 0)), 'Passed!');
        assertTrue(a.intersectsSphere(new Sphere(new Vector3(-1, -1, -1.001), 0)), 'Passed!');
        assertFalse(a.intersectsSphere(new Sphere(new Vector3(-1.1, -1.1, -1.001), 0)), 'Passed!');
        assertTrue(a.intersectsSphere(new Sphere(new Vector3(-1.1, -1.1, -1.001), 0.5)), 'Passed!');
        assertTrue(a.intersectsSphere(new Sphere(new Vector3(1, 1, -1.001), 0)), 'Passed!');
        assertFalse(a.intersectsSphere(new Sphere(new Vector3(1.1, 1.1, -1.001), 0)), 'Passed!');
        assertTrue(a.intersectsSphere(new Sphere(new Vector3(1.1, 1.1, -1.001), 0.5)), 'Passed!');
        assertTrue(a.intersectsSphere(new Sphere(new Vector3(0, 0, -99.999), 0)), 'Passed!');
        assertTrue(a.intersectsSphere(new Sphere(new Vector3(-99.999, -99.999, -99.999), 0)), 'Passed!');
        assertFalse(a.intersectsSphere(new Sphere(new Vector3(-100.1, -100.1, -100.1), 0)), 'Passed!');
        assertTrue(a.intersectsSphere(new Sphere(new Vector3(-100.1, -100.1, -100.1), 0.5)), 'Passed!');
        assertTrue(a.intersectsSphere(new Sphere(new Vector3(99.999, 99.999, -99.999), 0)), 'Passed!');
        assertFalse(a.intersectsSphere(new Sphere(new Vector3(100.1, 100.1, -100.1), 0)), 'Passed!');
        assertTrue(a.intersectsSphere(new Sphere(new Vector3(100.1, 100.1, -100.1), 0.2)), 'Passed!');
        assertFalse(a.intersectsSphere(new Sphere(new Vector3(0, 0, -101), 0)), 'Passed!');
        assertTrue(a.intersectsSphere(new Sphere(new Vector3(0, 0, -101), 1.1)), 'Passed!');
    }

    public function testIntersectsObject() {
        var m = new Matrix4().makePerspective(-1, 1, 1, -1, 1, 100);
        var a = new Frustum().setFromProjectionMatrix(m);
        var object = new Mesh(new BoxGeometry(1, 1, 1));
        var intersects:Bool;

        intersects = a.intersectsObject(object);
        assertFalse(intersects, 'No intersection');

        object.position.set(-1, -1, -1);
        object.updateMatrixWorld();

        intersects = a.intersectsObject(object);
        assertTrue(intersects, 'Successful intersection');

        object.position.set(1, 1, 1);
        object.updateMatrixWorld();

        intersects = a.intersectsObject(object);
        assertFalse(intersects, 'No intersection');
    }

    public function testIntersectsSprite() {
        var m = new Matrix4().makePerspective(-1, 1, 1, -1, 1, 100);
        var a = new Frustum().setFromProjectionMatrix(m);
        var sprite = new Sprite();
        var intersects:Bool;

        intersects = a.intersectsSprite(sprite);
        assertFalse(intersects, 'No intersection');

        sprite.position.set(-1, -1, -1);
        sprite.updateMatrixWorld();

        intersects = a.intersectsSprite(sprite);
        assertTrue(intersects, 'Successful intersection');
    }

    public function testIntersectsBox() {
        var m = new Matrix4().makePerspective(-1, 1, 1, -1, 1, 100);
        var a = new Frustum().setFromProjectionMatrix(m);
        var box = new Box3(zero3.clone(), one3.clone());
        var intersects:Bool;

        intersects = a.intersectsBox(box);
        assertFalse(intersects, 'No intersection');

        box.translate(new Vector3(-1 - eps, -1 - eps, -1 - eps));

        intersects = a.intersectsBox(box);
        assertTrue(intersects, 'Successful intersection');
    }
}