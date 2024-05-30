package three.math;

import haxe.unit.TestCase;
import three.math.Plane;
import three.math.Vector3;
import three.math.Line3;
import three.math.Sphere;
import three.math.Box3;
import three.math.Matrix4;

class PlaneTests {
    public function new() {}

    public function testInstancing():Void {
        var a:Plane = new Plane();
        assertEquals(a.normal.x, 1);
        assertEquals(a.normal.y, 0);
        assertEquals(a.normal.z, 0);
        assertEquals(a.constant, 0);

        a = new Plane(Vector3.one.clone(), 0);
        assertEquals(a.normal.x, 1);
        assertEquals(a.normal.y, 1);
        assertEquals(a.normal.z, 1);
        assertEquals(a.constant, 0);

        a = new Plane(Vector3.one.clone(), 1);
        assertEquals(a.normal.x, 1);
        assertEquals(a.normal.y, 1);
        assertEquals(a.normal.z, 1);
        assertEquals(a.constant, 1);
    }

    public function testIsPlane():Void {
        var a:Plane = new Plane();
        assertTrue(a.isPlane);

        var b:Vector3 = new Vector3();
        assertFalse(b.isPlane);
    }

    public function testSet():Void {
        var a:Plane = new Plane();
        assertEquals(a.normal.x, 1);
        assertEquals(a.normal.y, 0);
        assertEquals(a.normal.z, 0);
        assertEquals(a.constant, 0);

        var b:Plane = a.clone().set(new Vector3(x, y, z), w);
        assertEquals(b.normal.x, x);
        assertEquals(b.normal.y, y);
        assertEquals(b.normal.z, z);
        assertEquals(b.constant, w);
    }

    public function testSetComponents():Void {
        var a:Plane = new Plane();
        assertEquals(a.normal.x, 1);
        assertEquals(a.normal.y, 0);
        assertEquals(a.normal.z, 0);
        assertEquals(a.constant, 0);

        var b:Plane = a.clone().setComponents(x, y, z, w);
        assertEquals(b.normal.x, x);
        assertEquals(b.normal.y, y);
        assertEquals(b.normal.z, z);
        assertEquals(b.constant, w);
    }

    public function testSetFromNormalAndCoplanarPoint():Void {
        var normal:Vector3 = Vector3.one.clone().normalize();
        var a:Plane = new Plane().setFromNormalAndCoplanarPoint(normal, Vector3.zero);
        assertEquals(a.normal, normal);
        assertEquals(a.constant, 0);
    }

    public function testSetFromCoplanarPoints():Void {
        var a:Plane = new Plane();
        var v1:Vector3 = new Vector3(2.0, 0.5, 0.25);
        var v2:Vector3 = new Vector3(2.0, -0.5, 1.25);
        var v3:Vector3 = new Vector3(2.0, -3.5, 2.2);
        var normal:Vector3 = new Vector3(1, 0, 0);
        var constant:Float = -2;

        a.setFromCoplanarPoints(v1, v2, v3);
        assertEquals(a.normal, normal);
        assertEquals(a.constant, constant);
    }

    public function testClone():Void {
        var a:Plane = new Plane(new Vector3(2.0, 0.5, 0.25));
        var b:Plane = a.clone();
        assertTrue(a.equals(b));
    }

    public function testCopy():Void {
        var a:Plane = new Plane(new Vector3(x, y, z), w);
        var b:Plane = new Plane().copy(a);
        assertEquals(b.normal.x, x);
        assertEquals(b.normal.y, y);
        assertEquals(b.normal.z, z);
        assertEquals(b.constant, w);

        a.normal.x = 0;
        a.normal.y = -1;
        a.normal.z = -2;
        a.constant = -3;
        assertEquals(b.normal.x, x);
        assertEquals(b.normal.y, y);
        assertEquals(b.normal.z, z);
        assertEquals(b.constant, w);
    }

    public function testNormalize():Void {
        var a:Plane = new Plane(new Vector3(2, 0, 0), 2);
        a.normalize();
        assertEquals(a.normal.length(), 1);
        assertEquals(a.normal, new Vector3(1, 0, 0));
        assertEquals(a.constant, 1);
    }

    public function testNegateDistanceToPoint():Void {
        var a:Plane = new Plane(new Vector3(2, 0, 0), -2);
        a.normalize();
        assertEquals(a.distanceToPoint(new Vector3(4, 0, 0)), 3);
        assertEquals(a.distanceToPoint(new Vector3(1, 0, 0)), 0);

        a.negate();
        assertEquals(a.distanceToPoint(new Vector3(4, 0, 0)), -3);
        assertEquals(a.distanceToPoint(new Vector3(1, 0, 0)), 0);
    }

    public function testDistanceToPoint():Void {
        var a:Plane = new Plane(new Vector3(2, 0, 0), -2);
        var point:Vector3 = new Vector3();
        a.normalize().projectPoint(Vector3.zero.clone(), point);
        assertEquals(a.distanceToPoint(point), 0);
        assertEquals(a.distanceToPoint(new Vector3(4, 0, 0)), 3);
    }

    public function testDistanceToSphere():Void {
        var a:Plane = new Plane(new Vector3(1, 0, 0), 0);
        var b:Sphere = new Sphere(new Vector3(2, 0, 0), 1);
        assertEquals(a.distanceToSphere(b), 1);

        a.set(new Vector3(1, 0, 0), 2);
        assertEquals(a.distanceToSphere(b), 3);
        a.set(new Vector3(1, 0, 0), -2);
        assertEquals(a.distanceToSphere(b), -1);
    }

    public function testProjectPoint():Void {
        var a:Plane = new Plane(new Vector3(1, 0, 0), 0);
        var point:Vector3 = new Vector3();
        a.projectPoint(new Vector3(10, 0, 0), point);
        assertEquals(point, Vector3.zero);

        a = new Plane(new Vector3(0, 1, 0), -1);
        a.projectPoint(new Vector3(0, 0, 0), point);
        assertEquals(point, new Vector3(0, 1, 0));
    }

    public function testIntersectLine():Void {
        var a:Plane = new Plane(new Vector3(1, 0, 0), 0);
        var point:Vector3 = new Vector3();
        var l1:Line3 = new Line3(new Vector3(-10, 0, 0), new Vector3(10, 0, 0));
        a.intersectLine(l1, point);
        assertEquals(point, new Vector3(0, 0, 0));

        a = new Plane(new Vector3(1, 0, 0), -3);
        a.intersectLine(l1, point);
        assertEquals(point, new Vector3(3, 0, 0));
    }

    public function testIntersectsBox():Void {
        var a:Box3 = new Box3(Vector3.zero.clone(), Vector3.one.clone());
        var b:Plane = new Plane(new Vector3(0, 1, 0), 1);
        var c:Plane = new Plane(new Vector3(0, 1, 0), 1.25);
        var d:Plane = new Plane(new Vector3(0, -1, 0), 1.25);
        var e:Plane = new Plane(new Vector3(0, 1, 0), 0.25);
        var f:Plane = new Plane(new Vector3(0, 1, 0), -0.25);
        var g:Plane = new Plane(new Vector3(0, 1, 0), -0.75);
        var h:Plane = new Plane(new Vector3(0, 1, 0), -1);
        var i:Plane = new Plane(new Vector3(1, 1, 1).normalize(), -1.732);
        var j:Plane = new Plane(new Vector3(1, 1, 1).normalize(), -1.733);

        assertFalse(b.intersectsBox(a));
        assertFalse(c.intersectsBox(a));
        assertFalse(d.intersectsBox(a));
        assertFalse(e.intersectsBox(a));
        assertTrue(f.intersectsBox(a));
        assertTrue(g.intersectsBox(a));
        assertTrue(h.intersectsBox(a));
        assertTrue(i.intersectsBox(a));
        assertFalse(j.intersectsBox(a));
    }

    public function testIntersectsSphere():Void {
        var a:Sphere = new Sphere(Vector3.zero.clone(), 1);
        var b:Plane = new Plane(new Vector3(0, 1, 0), 1);
        var c:Plane = new Plane(new Vector3(0, 1, 0), 1.25);
        var d:Plane = new Plane(new Vector3(0, -1, 0), 1.25);

        assertTrue(b.intersectsSphere(a));
        assertFalse(c.intersectsSphere(a));
        assertFalse(d.intersectsSphere(a));
    }

    public function testCoplanarPoint():Void {
        var point:Vector3 = new Vector3();

        var a:Plane = new Plane(new Vector3(1, 0, 0), 0);
        a.coplanarPoint(point);
        assertEquals(a.distanceToPoint(point), 0);

        a = new Plane(new Vector3(0, 1, 0), -1);
        a.coplanarPoint(point);
        assertEquals(a.distanceToPoint(point), 0);
    }

    public function testApplyMatrix4Translate():Void {
        var a:Plane = new Plane(new Vector3(1, 0, 0), 0);

        var m:Matrix4 = new Matrix4();
        m.makeRotationZ(Math.PI * 0.5);

        assertTrue(comparePlane(a.clone().applyMatrix4(m), new Plane(new Vector3(0, 1, 0), 0)));

        a = new Plane(new Vector3(0, 1, 0), -1);
        assertTrue(comparePlane(a.clone().applyMatrix4(m), new Plane(new Vector3(-1, 0, 0), -1)));

        m.makeTranslation(1, 1, 1);
        assertTrue(comparePlane(a.clone().applyMatrix4(m), a.clone().translate(new Vector3(1, 1, 1))));
    }

    public function testEquals():Void {
        var a:Plane = new Plane(new Vector3(1, 0, 0), 0);
        var b:Plane = new Plane(new Vector3(1, 0, 0), 1);
        var c:Plane = new Plane(new Vector3(0, 1, 0), 0);

        assertTrue(a.normal.equals(b.normal));
        assertFalse(a.normal.equals(c.normal));

        assertFalse(a.constant == b.constant);
        assertTrue(a.constant == c.constant);

        assertFalse(a.equals(b));
        assertFalse(a.equals(c));

        a.copy(b);
        assertTrue(a.normal.equals(b.normal));
        assertTrue(a.constant == b.constant);
        assertTrue(a.equals(b));
    }

    private function comparePlane(a:Plane, b:Plane):Bool {
        var threshold:Float = 0.0001;
        return a.normal.distanceTo(b.normal) < threshold && Math.abs(a.constant - b.constant) < threshold;
    }
}