import MathConsts.MathConsts;
import Vector3.Vector3;
import Line3.Line3;
import Sphere.Sphere;
import Box3.Box3;
import Matrix4.Matrix4;
import Plane.Plane;

function comparePlane(a: Plane, b: Plane, ?threshold: Float = 0.0001): Bool {
    return (a.normal.distanceTo(b.normal) < threshold) && Math.abs(a.constant - b.constant) < threshold;
}

class TestPlane {
    static public function instancing(): Void {
        var a = new Plane();
        trace("normal.x == 1: " + (a.normal.x == 1));
        trace("normal.y == 0: " + (a.normal.y == 0));
        trace("normal.z == 0: " + (a.normal.z == 0));
        trace("constant == 0: " + (a.constant == 0));

        a = new Plane(Vector3.one(), 0);
        trace("normal.x == 1: " + (a.normal.x == 1));
        trace("normal.y == 1: " + (a.normal.y == 1));
        trace("normal.z == 1: " + (a.normal.z == 1));
        trace("constant == 0: " + (a.constant == 0));

        a = new Plane(Vector3.one(), 1);
        trace("normal.x == 1: " + (a.normal.x == 1));
        trace("normal.y == 1: " + (a.normal.y == 1));
        trace("normal.z == 1: " + (a.normal.z == 1));
        trace("constant == 1: " + (a.constant == 1));
    }

    static public function isPlane(): Void {
        var a = new Plane();
        trace("isPlane: " + a.isPlane);

        var b = new Vector3();
        trace("isPlane: " + b.isPlane);
    }

    static public function set(): Void {
        var a = new Plane();
        trace("normal.x == 1: " + (a.normal.x == 1));
        trace("normal.y == 0: " + (a.normal.y == 0));
        trace("normal.z == 0: " + (a.normal.z == 0));
        trace("constant == 0: " + (a.constant == 0));

        var b = a.clone().set(new Vector3(MathConsts.x, MathConsts.y, MathConsts.z), MathConsts.w);
        trace("normal.x == x: " + (b.normal.x == MathConsts.x));
        trace("normal.y == y: " + (b.normal.y == MathConsts.y));
        trace("normal.z == z: " + (b.normal.z == MathConsts.z));
        trace("constant == w: " + (b.constant == MathConsts.w));
    }

    static public function setComponents(): Void {
        var a = new Plane();
        trace("normal.x == 1: " + (a.normal.x == 1));
        trace("normal.y == 0: " + (a.normal.y == 0));
        trace("normal.z == 0: " + (a.normal.z == 0));
        trace("constant == 0: " + (a.constant == 0));

        var b = a.clone().setComponents(MathConsts.x, MathConsts.y, MathConsts.z, MathConsts.w);
        trace("normal.x == x: " + (b.normal.x == MathConsts.x));
        trace("normal.y == y: " + (b.normal.y == MathConsts.y));
        trace("normal.z == z: " + (b.normal.z == MathConsts.z));
        trace("constant == w: " + (b.constant == MathConsts.w));
    }

    static public function setFromNormalAndCoplanarPoint(): Void {
        var normal = Vector3.one().normalize();
        var a = new Plane().setFromNormalAndCoplanarPoint(normal, Vector3.zero());

        trace("normal.equals: " + a.normal.equals(normal));
        trace("constant == 0: " + (a.constant == 0));
    }

    static public function setFromCoplanarPoints(): Void {
        var a = new Plane();
        var v1 = new Vector3(2.0, 0.5, 0.25);
        var v2 = new Vector3(2.0, -0.5, 1.25);
        var v3 = new Vector3(2.0, -3.5, 2.2);
        var normal = new Vector3(1, 0, 0);
        var constant = -2;

        a.setFromCoplanarPoints(v1, v2, v3);

        trace("normal.equals: " + a.normal.equals(normal));
        trace("constant == constant: " + (a.constant == constant));
    }

    static public function clone(): Void {
        var a = new Plane(new Vector3(2.0, 0.5, 0.25));
        var b = a.clone();

        trace("equals: " + a.equals(b));
    }

    static public function copy(): Void {
        var a = new Plane(new Vector3(MathConsts.x, MathConsts.y, MathConsts.z), MathConsts.w);
        var b = new Plane().copy(a);
        trace("normal.x == x: " + (b.normal.x == MathConsts.x));
        trace("normal.y == y: " + (b.normal.y == MathConsts.y));
        trace("normal.z == z: " + (b.normal.z == MathConsts.z));
        trace("constant == w: " + (b.constant == MathConsts.w));

        // ensure that it is a true copy
        a.normal.x = 0;
        a.normal.y = -1;
        a.normal.z = -2;
        a.constant = -3;
        trace("normal.x == x: " + (b.normal.x == MathConsts.x));
        trace("normal.y == y: " + (b.normal.y == MathConsts.y));
        trace("normal.z == z: " + (b.normal.z == MathConsts.z));
        trace("constant == w: " + (b.constant == MathConsts.w));
    }

    static public function normalize(): Void {
        var a = new Plane(new Vector3(2, 0, 0), 2);

        a.normalize();
        trace("normal.length() == 1: " + (a.normal.length() == 1));
        trace("normal.equals: " + a.normal.equals(new Vector3(1, 0, 0)));
        trace("constant == 1: " + (a.constant == 1));
    }

    static public function negateDistanceToPoint(): Void {
        var a = new Plane(new Vector3(2, 0, 0), -2);

        a.normalize();
        trace("distanceToPoint: " + a.distanceToPoint(new Vector3(4, 0, 0)) == 3);
        trace("distanceToPoint: " + a.distanceToPoint(new Vector3(1, 0, 0)) == 0);

        a.negate();
        trace("distanceToPoint: " + a.distanceToPoint(new Vector3(4, 0, 0)) == -3);
        trace("distanceToPoint: " + a.distanceToPoint(new Vector3(1, 0, 0)) == 0);
    }

    static public function distanceToPoint(): Void {
        var a = new Plane(new Vector3(2, 0, 0), -2);
        var point = new Vector3();

        a.normalize().projectPoint(Vector3.zero(), point);
        trace("distanceToPoint: " + a.distanceToPoint(point) == 0);
        trace("distanceToPoint: " + a.distanceToPoint(new Vector3(4, 0, 0)) == 3);
    }

    static public function distanceToSphere(): Void {
        var a = new Plane(new Vector3(1, 0, 0), 0);

        var b = new Sphere(new Vector3(2, 0, 0), 1);

        trace("distanceToSphere: " + a.distanceToSphere(b) == 1);

        a.set(new Vector3(1, 0, 0), 2);
        trace("distanceToSphere: " + a.distanceToSphere(b) == 3);
        a.set(new Vector3(1, 0, 0), -2);
        trace("distanceToSphere: " + a.distanceToSphere(b) == -1);
    }

    static public function projectPoint(): Void {
        var a = new Plane(new Vector3(1, 0, 0), 0);
        var point = new Vector3();

        a.projectPoint(new Vector3(10, 0, 0), point);
        trace("equals: " + point.equals(Vector3.zero()));
        a.projectPoint(new Vector3(-10, 0, 0), point);
        trace("equals: " + point.equals(Vector3.zero()));

        a = new Plane(new Vector3(0, 1, 0), -1);
        a.projectPoint(new Vector3(0, 0, 0), point);
        trace("equals: " + point.equals(new Vector3(0, 1, 0)));
        a.projectPoint(new Vector3(0, 1, 0), point);
        trace("equals: " + point.equals(new Vector3(0, 1, 0)));
    }

    static public function intersectLine(): Void {
        var a = new Plane(new Vector3(1, 0, 0), 0);
        var point = new Vector3();

        var l1 = new Line3(new Vector3(-10, 0, 0), new Vector3(10, 0, 0));
        a.intersectLine(l1, point);
        trace("equals: " + point.equals(new Vector3(0, 0, 0)));

        a = new Plane(new Vector3(1, 0, 0), -3);
        a.intersectLine(l1, point);
        trace("equals: " + point.equals(new Vector3(3, 0, 0)));
    }

    static public function intersectsBox(): Void {
        var a = new Box3(Vector3.zero(), Vector3.one());
        var b = new Plane(new Vector3(0, 1, 0), 1);
        var c = new Plane(new Vector3(0, 1, 0), 1.25);
        var d = new Plane(new Vector3(0, -1, 0), 1.25);
        var e = new Plane(new Vector3(0, 1, 0), 0.25);
        var f = new Plane(new Vector3(0, 1, 0), -0.25);
        var g = new Plane(new Vector3(0, 1, 0), -0.75);
        var h = new Plane(new Vector3(0, 1, 0), -1);
        var i = new Plane(new Vector3(1, 1, 1).normalize(), -1.732);
        var j = new Plane(new Vector3(1, 1, 1).normalize(), -1.733);

        trace("intersectsBox: " + !b.intersectsBox(a));
        trace("intersectsBox: " + !c.intersectsBox(a));
        trace("intersectsBox: " + !d.intersectsBox(a));
        trace("intersectsBox: " + !e.intersectsBox(a));
        trace("intersectsBox: " + f.intersectsBox(a));
        trace("intersectsBox: " + g.intersectsBox(a));
        trace("intersectsBox: " + h.intersectsBox(a));
        trace("intersectsBox: " + i.intersectsBox(a));
        trace("intersectsBox: " + !j.intersectsBox(a));
    }

    static public function intersectsSphere(): Void {
        var a = new Sphere(Vector3.zero(), 1);
        var b = new Plane(new Vector3(0, 1, 0), 1);
        var c = new Plane(new Vector3(0, 1, 0), 1.25);
        var d = new Plane(new Vector3(0, -1, 0), 1.25);

        trace("intersectsSphere: " + b.intersectsSphere(a));
        trace("intersectsSphere: " + !c.intersectsSphere(a));
        trace("intersectsSphere: " + !d.intersectsSphere(a));
    }

    static public function coplanarPoint(): Void {
        var point = new Vector3();

        var a = new Plane(new Vector3(1, 0, 0), 0);
        a.coplanarPoint(point);
        trace("distanceToPoint: " + a.distanceToPoint(point) == 0);

        a = new Plane(new Vector3(0, 1, 0), -1);
        a.coplanarPoint(point);
        trace("distanceToPoint: " + a.distanceToPoint(point) == 0);
    }

    static public function applyMatrix4Translate(): Void {
        var a = new Plane(new Vector3(1, 0, 0), 0);

        var m = new Matrix4();
        m.makeRotationZ(Math.PI * 0.5);

        trace("comparePlane: " + comparePlane(a.clone().applyMatrix4(m), new Plane(new Vector3(0, 1, 0), 0)));

        a = new Plane(new Vector3(0, 1, 0), -1);
        trace("comparePlane: " + comparePlane(a.clone().applyMatrix4(m), new Plane(new Vector3(-1, 0, 0), -1)));

        m.makeTranslation(1, 1, 1);
        trace("comparePlane: " + comparePlane(a.clone().applyMatrix4(m), a.clone().translate(new Vector3(1, 1, 1))));
    }

    static public function equals(): Void {
        var a = new Plane(new Vector3(1, 0, 0), 0);
        var b = new Plane(new Vector3(1, 0, 0), 1);
        var c = new Plane(new Vector3(0, 1, 0), 0);

        trace("normal.equals: " + a.normal.equals(b.normal));
        trace("normal.equals: " + !a.normal.equals(c.normal));

        trace("constant == constant: " + (a.constant != b.constant));
        trace("constant == constant: " + (a.constant == c.constant));

        trace("equals: " + !a.equals(b));
        trace("equals: " + !a.equals(c));

        a.copy(b);
        trace("normal.equals: " + a.normal.equals(b.normal));
        trace("constant == constant: " + (a.constant == b.constant));
        trace("equals: " + a.equals(b));
    }
}

class TestPlaneMain {
    static public function main(): Void {
        TestPlane.instancing();
        TestPlane.isPlane();
        TestPlane.set();
        TestPlane.setComponents();
        TestPlane.setFromNormalAndCoplanarPoint();
        TestPlane.setFromCoplanarPoints();
        TestPlane.clone();
        TestPlane.copy();
        TestPlane.normalize();
        TestPlane.negateDistanceToPoint();
        TestPlane.distanceToPoint();
        TestPlane.distanceToSphere();
        TestPlane.projectPoint();
        TestPlane.intersectLine();
        TestPlane.intersectsBox();
        TestPlane.intersectsSphere();
        TestPlane.coplanarPoint();
        TestPlane.applyMatrix4Translate();
        TestPlane.equals();
    }
}

TestPlaneMain.main();