package;

import three.math.Box3;
import three.math.Vector3;
import three.math.Sphere;
import three.math.Plane;
import three.math.Matrix4;
import three.utils.math_constants;

class SphereTests {

    static function main() {

        var a = new Sphere();
        trace(a.center.equals(math_constants.zero3), 'Passed!');
        trace(a.radius == -1, 'Passed!');

        a = new Sphere(math_constants.one3.clone(), 1);
        trace(a.center.equals(math_constants.one3), 'Passed!');
        trace(a.radius == 1, 'Passed!');

        var b = new Box3();
        trace(!b.isSphere, 'Passed!');

        a.set(math_constants.one3, 1);
        trace(a.center.equals(math_constants.one3), 'Passed!');
        trace(a.radius == 1, 'Passed!');

        var expectedCenter = new Vector3(0.9330126941204071, 0, 0);
        var expectedRadius = 1.3676668773461689;
        var optionalCenter = new Vector3(1, 1, 1);
        var points = [
            new Vector3(1, 1, 0), new Vector3(1, 1, 0),
            new Vector3(1, 1, 0), new Vector3(1, 1, 0),
            new Vector3(1, 1, 0), new Vector3(0.8660253882408142, 0.5, 0),
            new Vector3(-0, 0.5, 0.8660253882408142), new Vector3(1.8660253882408142, 0.5, 0),
            new Vector3(0, 0.5, -0), new Vector3(0.8660253882408142, 0.5, -0),
            new Vector3(0.8660253882408142, -0.5, 0), new Vector3(-0, -0.5, 0.8660253882408142),
            new Vector3(1.8660253882408142, -0.5, 0), new Vector3(0, -0.5, -0),
            new Vector3(0.8660253882408142, -0.5, -0), new Vector3(-0, -1, 0),
            new Vector3(-0, -1, 0), new Vector3(0, -1, 0),
            new Vector3(0, -1, -0), new Vector3(-0, -1, -0),
        ];

        a.setFromPoints(points);
        trace(Math.abs(a.center.x - expectedCenter.x) <= math_constants.eps, 'Default center: check center.x');
        trace(Math.abs(a.center.y - expectedCenter.y) <= math_constants.eps, 'Default center: check center.y');
        trace(Math.abs(a.center.z - expectedCenter.z) <= math_constants.eps, 'Default center: check center.z');
        trace(Math.abs(a.radius - expectedRadius) <= math_constants.eps, 'Default center: check radius');

        expectedRadius = 2.5946195770400102;
        a.setFromPoints(points, optionalCenter);
        trace(Math.abs(a.center.x - optionalCenter.x) <= math_constants.eps, 'Optional center: check center.x');
        trace(Math.abs(a.center.y - optionalCenter.y) <= math_constants.eps, 'Optional center: check center.y');
        trace(Math.abs(a.center.z - optionalCenter.z) <= math_constants.eps, 'Optional center: check center.z');
        trace(Math.abs(a.radius - expectedRadius) <= math_constants.eps, 'Optional center: check radius');

        var c = new Sphere();
        c.copy(a);
        trace(c.center.equals(a.center), 'Passed!');
        trace(c.radius == a.radius, 'Passed!');

        a.makeEmpty();
        trace(a.isEmpty(), 'Passed!');
        trace(a.center.equals(math_constants.zero3), 'Passed!');

        a.set(math_constants.one3, 1);
        trace(a.containsPoint(math_constants.zero3), 'Passed!');
        trace(a.containsPoint(math_constants.one3), 'Passed!');

        trace(Math.abs(a.distanceToPoint(math_constants.zero3) - 0.7320) < 0.001, 'Passed!');
        trace(a.distanceToPoint(math_constants.one3) == -1, 'Passed!');

        var d = new Sphere(math_constants.one3, 1);
        trace(a.intersectsSphere(d), 'Passed!');
        trace(!a.intersectsSphere(c), 'Passed!');

        var e = new Sphere(math_constants.zero3, 1);
        var f = new Sphere(new Vector3(-5, -5, -5), 1);
        var box = new Box3(math_constants.zero3, math_constants.one3);
        trace(e.intersectsBox(box), 'Check unit sphere');
        trace(!f.intersectsBox(box), 'Check shifted sphere');

        var g = new Plane(new Vector3(0, 1, 0), 1);
        var h = new Plane(new Vector3(0, 1, 0), 1.25);
        var i = new Plane(new Vector3(0, -1, 0), 1.25);
        trace(e.intersectsPlane(g), 'Passed!');
        trace(!e.intersectsPlane(h), 'Passed!');
        trace(!e.intersectsPlane(i), 'Passed!');

        var point = new Vector3();
        e.clampPoint(new Vector3(1, 1, 3), point);
        trace(point.equals(new Vector3(1, 1, 1)), 'Passed!');
        e.clampPoint(new Vector3(1, 1, -3), point);
        trace(point.equals(new Vector3(1, 1, 0)), 'Passed!');

        var aabb = new Box3();
        e.getBoundingBox(aabb);
        trace(aabb.equals(new Box3(math_constants.zero3, math_constants.one3)), 'Passed!');
        e.set(math_constants.zero3, 0);
        e.getBoundingBox(aabb);
        trace(aabb.equals(new Box3(math_constants.zero3, math_constants.zero3)), 'Passed!');
        e.makeEmpty();
        e.getBoundingBox(aabb);
        trace(aabb.isEmpty(), 'Passed!');

        var m = new Matrix4().makeTranslation(1, -2, 1);
        var aabb1 = new Box3();
        var aabb2 = new Box3();
        e.clone().applyMatrix4(m).getBoundingBox(aabb1);
        e.getBoundingBox(aabb2);
        trace(aabb1.equals(aabb2.applyMatrix4(m)), 'Passed!');

        e.translate(math_constants.one3.clone().negate());
        trace(e.center.equals(math_constants.zero3), 'Passed!');

        e.expandByPoint(new Vector3(2, 0, 0));
        trace(e.containsPoint(new Vector3(2, 0, 0)), 'Passed!');
        trace(e.center.equals(new Vector3(1, 0, 0)), 'Passed!');
        trace(e.radius == 2, 'Passed!');

        var j = new Sphere(math_constants.zero3, 1);
        var k = new Sphere(new Vector3(2, 0, 0), 1);
        j.union(k);
        trace(j.center.equals(new Vector3(1, 0, 0)), 'Passed!');
        trace(j.radius == 2, 'Passed!');

        var l = new Sphere(math_constants.zero3, 1);
        var m = new Sphere(math_constants.zero3, 4);
        l.union(m);
        trace(l.center.equals(math_constants.zero3), 'Passed!');
        trace(l.radius == 4, 'Passed!');

        var n = new Sphere();
        var o = new Sphere();
        trace(n.equals(o), 'Passed!');
        n.copy(o);
        trace(n.equals(o), 'Passed!');
    }
}