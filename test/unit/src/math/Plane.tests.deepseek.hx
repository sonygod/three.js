package three.test.unit.src.math;

import three.src.math.Plane;
import three.src.math.Vector3;
import three.src.math.Line3;
import three.src.math.Sphere;
import three.src.math.Box3;
import three.src.math.Matrix4;
import three.utils.math_constants;

class PlaneTests {

    static function comparePlane(a:Plane, b:Plane, threshold:Float):Bool {

        threshold = if (threshold == null) 0.0001 else threshold;
        return (a.normal.distanceTo(b.normal) < threshold && Math.abs(a.constant - b.constant) < threshold);

    }

    public static function main() {

        // INSTANCING
        var a = new Plane();
        trace(a.normal.x == 1, 'Passed!');
        trace(a.normal.y == 0, 'Passed!');
        trace(a.normal.z == 0, 'Passed!');
        trace(a.constant == 0, 'Passed!');

        a = new Plane(math_constants.one3.clone(), 0);
        trace(a.normal.x == 1, 'Passed!');
        trace(a.normal.y == 1, 'Passed!');
        trace(a.normal.z == 1, 'Passed!');
        trace(a.constant == 0, 'Passed!');

        a = new Plane(math_constants.one3.clone(), 1);
        trace(a.normal.x == 1, 'Passed!');
        trace(a.normal.y == 1, 'Passed!');
        trace(a.normal.z == 1, 'Passed!');
        trace(a.constant == 1, 'Passed!');

        // PUBLIC STUFF
        var b = a.clone();
        trace(a.equals(b), 'clones are equal');

        a = new Plane();
        var c = a.clone().set(new Vector3(math_constants.x, math_constants.y, math_constants.z), math_constants.w);
        trace(c.normal.x == math_constants.x, 'Passed!');
        trace(c.normal.y == math_constants.y, 'Passed!');
        trace(c.normal.z == math_constants.z, 'Passed!');
        trace(c.constant == math_constants.w, 'Passed!');

        a = new Plane();
        var d = a.clone().setComponents(math_constants.x, math_constants.y, math_constants.z, math_constants.w);
        trace(d.normal.x == math_constants.x, 'Passed!');
        trace(d.normal.y == math_constants.y, 'Passed!');
        trace(d.normal.z == math_constants.z, 'Passed!');
        trace(d.constant == math_constants.w, 'Passed!');

        a = new Plane();
        var e = a.clone().setFromNormalAndCoplanarPoint(math_constants.one3.clone().normalize(), math_constants.zero3);
        trace(e.normal.equals(math_constants.one3.clone().normalize()), 'Passed!');
        trace(e.constant == 0, 'Passed!');

        a = new Plane();
        var v1 = new Vector3(2.0, 0.5, 0.25);
        var v2 = new Vector3(2.0, -0.5, 1.25);
        var v3 = new Vector3(2.0, -3.5, 2.2);
        var normal = new Vector3(1, 0, 0);
        var constant = -2;
        var f = a.clone().setFromCoplanarPoints(v1, v2, v3);
        trace(f.normal.equals(normal), 'Check normal');
        trace(f.constant == constant, 'Check constant');

        a = new Plane();
        var g = a.clone().copy(f);
        trace(g.normal.x == math_constants.x, 'Passed!');
        trace(g.normal.y == math_constants.y, 'Passed!');
        trace(g.normal.z == math_constants.z, 'Passed!');
        trace(g.constant == math_constants.w, 'Passed!');

        a = new Plane();
        var h = a.clone().normalize();
        trace(h.normal.length() == 1, 'Passed!');
        trace(h.normal.equals(new Vector3(1, 0, 0)), 'Passed!');
        trace(h.constant == 1, 'Passed!');

        a = new Plane();
        var i = a.clone().negate();
        trace(i.distanceToPoint(new Vector3(4, 0, 0)) == -3, 'Passed!');
        trace(i.distanceToPoint(new Vector3(1, 0, 0)) == 0, 'Passed!');

        a = new Plane();
        var j = a.clone().distanceToPoint(math_constants.zero3);
        trace(j == 0, 'Passed!');

        a = new Plane();
        var k = a.clone().distanceToSphere(new Sphere(new Vector3(2, 0, 0), 1));
        trace(k == 1, 'Passed!');

        a = new Plane();
        var l = a.clone().projectPoint(math_constants.zero3, new Vector3());
        trace(l.equals(math_constants.zero3), 'Passed!');

        a = new Plane();
        var m = a.clone().intersectLine(new Line3(new Vector3(-10, 0, 0), new Vector3(10, 0, 0)), new Vector3());
        trace(m.equals(math_constants.zero3), 'Passed!');

        a = new Plane();
        var n = a.clone().intersectsBox(new Box3(math_constants.zero3.clone(), math_constants.one3.clone()));
        trace(!n, 'Passed!');

        a = new Plane();
        var o = a.clone().intersectsSphere(new Sphere(math_constants.zero3.clone(), 1));
        trace(o, 'Passed!');

        a = new Plane();
        var p = a.clone().coplanarPoint(new Vector3());
        trace(p.distanceToPoint(new Vector3()) == 0, 'Passed!');

        a = new Plane();
        var q = a.clone().applyMatrix4(new Matrix4().makeRotationZ(Math.PI * 0.5));
        trace(comparePlane(q, new Plane(new Vector3(0, 1, 0), 0), 0.0001), 'Passed!');

        a = new Plane();
        var r = a.clone().translate(new Vector3(1, 1, 1));
        trace(comparePlane(r, a.clone().applyMatrix4(new Matrix4().makeTranslation(1, 1, 1)), 0.0001), 'Passed!');

        a = new Plane();
        var s = a.clone().equals(new Plane());
        trace(s, 'Passed!');

    }

}