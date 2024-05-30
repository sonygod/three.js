import MathConstants.Vector3.*;
import Math.Vector3;
import Math.Ray;
import Math.Box3;
import Math.Sphere;
import Math.Plane;
import Math.Matrix4;

class RayTest {
    static public function main() {
        // INSTANCING
        var a = new Ray();
        trace("Instancing: ${a.origin.equals(zero3)} ${a.direction.equals(new Vector3(0, 0, -1))}");

        a = new Ray(two3.clone(), one3.clone());
        trace("Instancing: ${a.origin.equals(two3)} ${a.direction.equals(one3)}");

        // PUBLIC
        a = new Ray();
        a.set(one3, one3);
        trace("Set: ${a.origin.equals(one3)} ${a.direction.equals(one3)}");

        a = new Ray(one3.clone(), new Vector3(0, 0, 1));
        trace("Recast/Clone: ${a.recast(0).equals(a)}");

        var b = a.clone();
        trace("Recast/Clone: ${b.recast(-1).equals(new Ray(new Vector3(1, 1, 0), new Vector3(0, 0, 1)))}");

        var c = a.clone();
        trace("Recast/Clone: ${c.recast(1).equals(new Ray(new Vector3(1, 1, 2), new Vector3(0, 0, 1)))}");

        var d = a.clone();
        var e = d.clone().recast(1);
        trace("Recast/Clone: ${d.equals(a)} ${!e.equals(d)} ${e.equals(c)}");

        var a = new Ray(zero3.clone(), one3.clone());
        var b = new Ray().copy(a);
        trace("Copy/Equals: ${b.origin.equals(zero3)} ${b.direction.equals(one3)}");

        a.origin = zero3;
        a.direction = one3;
        trace("Copy/Equals: ${b.origin.equals(zero3)} ${b.direction.equals(one3)}");

        var a = new Ray(one3.clone(), new Vector3(0, 0, 1));
        var point = new Vector3();
        a.at(0, point);
        trace("At: ${point.equals(one3)}");
        a.at(-1, point);
        trace("At: ${point.equals(new Vector3(1, 1, 0))}");
        a.at(1, point);
        trace("At: ${point.equals(new Vector3(1, 1, 2))}");

        var a = new Ray(two3.clone(), one3.clone());
        var target = one3.clone();
        var expected = target.sub(two3).normalize();
        a.lookAt(target);
        trace("LookAt: ${a.direction.equals(expected)}");

        var a = new Ray(one3.clone(), new Vector3(0, 0, 1));
        var point = new Vector3();
        a.closestPointToPoint(zero3, point);
        trace("ClosestPointToPoint: ${point.equals(one3)}");
        a.closestPointToPoint(new Vector3(0, 0, 50), point);
        trace("ClosestPointToPoint: ${point.equals(new Vector3(1, 1, 50))}");
        a.closestPointToPoint(one3, point);
        trace("ClosestPointToPoint: ${point.equals(one3)}");

        var a = new Ray(one3.clone(), new Vector3(0, 0, 1));
        trace("DistanceToPoint: ${a.distanceToPoint(zero3) == Math.sqrt(3)}");
        trace("DistanceToPoint: ${a.distanceToPoint(new Vector3(0, 0, 50)) == Math.sqrt(2)}");
        trace("DistanceToPoint: ${a.distanceToPoint(one3) == 0}");

        var a = new Ray(one3.clone(), new Vector3(0, 0, 1));
        trace("DistanceSqToPoint: ${a.distanceSqToPoint(zero3) == 3}");
        trace("DistanceSqToPoint: ${a.distanceSqToPoint(new Vector3(0, 0, 50)) == 2}");
        trace("DistanceSqToPoint: ${a.distanceSqToPoint(one3) == 0}");

        var a = new Ray(one3.clone(), new Vector3(0, 0, 1));
        var ptOnLine = new Vector3();
        var ptOnSegment = new Vector3();
        var v0 = new Vector3(3, 5, 50);
        var v1 = new Vector3(50, 50, 50);
        var distSqr = a.distanceSqToSegment(v0, v1, ptOnLine, ptOnSegment);
        trace("DistanceSqToSegment: ${ptOnSegment.distanceTo(v0) < 0.0001} ${ptOnLine.distanceTo(new Vector3(1, 1, 50)) < 0.0001} ${Math.abs(distSqr - 20) < 0.0001}");

        v0 = new Vector3(-50, -50, -50);
        v1 = new Vector3(-3, -5, -4);
        distSqr = a.distanceSqToSegment(v0, v1, ptOnLine, ptOnSegment);
        trace("DistanceSqToSegment: ${ptOnSegment.distanceTo(v1) < 0.0001} ${ptOnLine.distanceTo(one3) < 0.0001} ${Math.abs(distSqr - 77) < 0.0001}");

        v0 = new Vector3(-50, -50, -50);
        v1 = new Vector3(50, 50, 50);
        distSqr = a.distanceSqToSegment(v0, v1, ptOnLine, ptOnSegment);
        trace("DistanceSqToSegment: ${ptOnSegment.distanceTo(one3) < 0.0001} ${ptOnLine.distanceTo(one3) < 0.0001} ${distSqr < 0.0001}");

        var TOL = 0.0001;
        var point = new Vector3();
        var a0 = new Ray(zero3.clone(), new Vector3(0, 0, -1));
        var a1 = new Ray(one3.clone(), new Vector3(-1, 0, 0));
        var b = new Sphere(new Vector3(0, 0, 3), 2);
        a0.intersectSphere(b, point.copy(posInf3));
        trace("IntersectSphere: ${point.equals(posInf3)}");
        b = new Sphere(new Vector3(3, 0, -1), 2);
        a0.intersectSphere(b, point.copy(posInf3));
        trace("IntersectSphere: ${point.equals(posInf3)}");
        b = new Sphere(new Vector3(1, -2, 1), 2);
        a1.intersectSphere(b, point.copy(posInf3));
        trace("IntersectSphere: ${point.equals(posInf3)}");
        b = new Sphere(new Vector3(-1, 1, 1), 1);
        a1.intersectSphere(b, point);
        trace("IntersectSphere: ${point.distanceTo(new Vector3(0, 1, 1)) < TOL}");
        b = new Sphere(new Vector3(0, 0, -2), 1);
        a0.intersectSphere(b, point);
        trace("IntersectSphere: ${point.distanceTo(new Vector3(0, 0, -1)) < TOL}");
        b = new Sphere(new Vector3(2, 0, -1), 2);
        a0.intersectSphere(b, point);
        trace("IntersectSphere: ${point.distanceTo(new Vector3(0, 0, -1)) < TOL}");
        b = new Sphere(new Vector3(2.01, 0, -1), 2);
        a0.intersectSphere(b, point.copy(posInf3));
        trace("IntersectSphere: ${point.equals(posInf3)}");
        b = new Sphere(zero3.clone(), 1);
        a0.intersectSphere(b, point);
        trace("IntersectSphere: ${point.distanceTo(new Vector3(0, 0, -1)) < TOL}");
        b = new Sphere(new Vector3(0, 0, 1), 4);
        a0.intersectSphere(b, point);
        trace("IntersectSphere: ${point.distanceTo(new Vector3(0, 0, -3)) < TOL}");
        b = new Sphere(new Vector3(0, 0, -1), 4);
        a0.intersectSphere(b, point);
        trace("IntersectSphere: ${point.distanceTo(new Vector3(0, 0, -5)) < TOL}");

        var a = new Ray(one3.clone(), new Vector3(0, 0, 1));
        var b = new Sphere(zero3, 0.5);
        var c = new Sphere(zero3, 1.5);
        var d = new Sphere(one3, 0.1);
        var e = new Sphere(two3, 0.1);
        var f = new Sphere(two3, 1);
        trace("IntersectsSphere: ${!a.intersectsSphere(b)} ${!a.intersectsSphere(c)} ${a.intersectsSphere(d)} ${!a.intersectsSphere(e)} ${!a.intersectsSphere(f)}");

        var a = new Ray(one3.clone(), new Vector3(0, 0, 1));
        var point = new Vector3();
        var b = new Plane().setFromNormalAndCoplanarPoint(new Vector3(0, 0, 1), new Vector3(1, 1, -1));
        a.intersectPlane(b, point.copy(posInf3));
        trace("IntersectPlane: ${point.equals(posInf3)}");
        var c = new Plane().setFromNormalAndCoplanarPoint(new Vector3(0, 0, 1), new Vector3(1, 1, 0));
        a.intersectPlane(c, point.copy(posInf3));
        trace("IntersectPlane: ${point.equals(posInf3)}");
        var d = new Plane().setFromNormalAndCoplanarPoint(new Vector3(0, 0, 1), new Vector3(1, 1, 1));
        a.intersectPlane(d, point.copy(posInf3));
        trace("IntersectPlane: ${point.equals(a.origin)}");
        var e = new Plane().setFromNormalAndCoplanarPoint(new Vector3(1, 0, 0), one3);
        a.intersectPlane(e, point.copy(posInf3));
        trace("IntersectPlane: ${point.equals(a.origin)}");
        var f = new Plane().setFromNormalAndCoplanarPoint(new Vector3(1, 0, 0), zero3);
        a.intersectPlane(f, point.copy(posInf3));
        trace("IntersectPlane: ${point.equals(posInf3)}");

        var a = new Ray(one3.clone(), new Vector3(0, 0, 1));
        var b = new Plane().setFromNormalAndCoplanarPoint(new Vector3(0, 0, 1), one3.clone().sub(new Vector3(0, 0, -1)));
        trace("IntersectsPlane: ${a.intersectsPlane(b)}");
        var c = new Plane().setFromNormalAndCoplanarPoint(new Vector3(0, 0, 1), one3.clone().sub(new Vector3(0, 0, 0)));
        trace("IntersectsPlane: ${a.intersectsPlane(c)}");
        var d = new Plane().setFromNormalAndCoplanarPoint(new Vector3(0, 0, 1), one3.clone().sub(new Vector3(0, 0, 1)));
        trace("IntersectsPlane: ${!a.intersectsPlane(d)}");
        var e = new Plane().setFromNormalAndCoplanarPoint(new Vector3(1, 0, 0), one3);
        trace("IntersectsPlane: ${a.intersectsPlane(e)}");
        var f = new Plane().setFromNormalAndCoplanarPoint(new Vector3(1, 0, 0), zero3);
        trace("IntersectsPlane: ${!a.intersectsPlane(f)}");

        var TOL = 0.0001;
        var box = new Box3(new Vector3(-1, -1, -1), new Vector3(1, 1, 1));
        var point = new Vector3();
        var a = new Ray(new Vector3(-2, 0, 0), new Vector3(1, 0, 0));
        trace("IntersectsBox: ${a.intersectsBox(box)}");
        a.intersectBox(box, point);
        trace("IntersectBox: ${point.distanceTo(new Vector3(-1, 0, 0)) < TOL}");
        var b = new Ray(new Vector3(-2, 0, 0), new Vector3(-1, 0, 0));
        trace("IntersectsBox: ${!b.intersectsBox(box)}");
        b.intersectBox(box, point.copy(posInf3));
        trace("IntersectBox: ${point.equals(posInf3)}");
        var c = new Ray(new Vector3(0, 0, 0), new Vector3(1, 0, 0));
        trace("IntersectsBox: ${c.intersectsBox(box)}");
        c.intersectBox(box, point);
        trace("IntersectBox: ${point.distanceTo(new Vector3(1, 0, 0)) < TOL}");
        var d = new Ray(new Vector3(0, 2, 1), new Vector3(0, -1, -1).normalize());
        trace("IntersectsBox: ${d.intersectsBox(box)}");
        d.intersectBox(box, point);
        trace("IntersectBox: ${point.distanceTo(new Vector3(0, 1, 0)) < TOL}");
        var e = new Ray(new Vector3(1, -2, 1), new Vector3(0, 1, 0).normalize());
        trace("IntersectsBox: ${e.intersectsBox(box)}");
        e.intersectBox(box, point);
        trace("IntersectBox: ${point.distanceTo(new Vector3(1, -1, 1)) < TOL}");
        var f = new Ray(new Vector3(1, -2, 0), new Vector3(0, -1, 0).normalize());
        trace("IntersectsBox: ${!f.intersectsBox(box)}");
        f.intersectBox(box, point.copy(posInf3));
        trace("IntersectBox: ${point.equals(posInf3)}");

        var ray = new Ray();
        var a = new Vector3(1, 1, 0);
        var b = new Vector3(0, 1, 1);
        var c = new Vector3(1, 0, 1);
        var point = new Vector3();
        ray.set(ray.origin, zero3.clone());
        ray.intersectTriangle(a, b, c, false, point.copy(posInf3));
        trace("IntersectTriangle: ${point.equals(posInf3)}");
        ray.set(ray.origin, one3.clone());
        ray.intersectTriangle(a, b, c, true, point.copy(posInf3));
        trace("IntersectTriangle: ${point.equals(posInf3)}");
        ray.set(ray.origin, one3.clone());
        ray.intersectTriangle(a, b, c, false, point);
        trace("IntersectTriangle: ${Math.abs(point.x - 2 / 3) <= eps} ${Math.abs(point.y - 2 / 3) <= eps} ${Math.abs(point.z - 2 / 3) <= eps}");
        b.multiplyScalar(-1);
        ray.intersectTriangle(a, b, c, false, point.copy(posInf3));
        trace("IntersectTriangle: ${point.equals(posInf3)}");
        a.multiplyScalar(-1);
        ray.intersectTriangle(a, b, c, false, point.copy(posInf3));
        trace("IntersectTriangle: ${point.equals(posInf3)}");
        b.multiplyScalar(-1);
        ray.intersectTriangle(a, b, c, false, point.copy(posInf3));
        trace("IntersectTriangle: ${point.equals(posInf3)}");
        a.multiplyScalar(-1);
        b.multiplyScalar(-1);
        ray.direction.multiplyScalar(-1);
        ray.intersectTriangle(a, b, c, false, point.copy(posInf3));
        trace("IntersectTriangle: ${point.equals(posInf3)}");

        var a = new Ray(one3
.clone(), new Vector3(0, 0, 1));
        var m = new Matrix4();
        trace("ApplyMatrix4: ${a.clone().applyMatrix4(m).equals(a)}");
        a = new Ray(zero3.clone(), new Vector3(0, 0, 1));
        m.makeRotationZ(Math.PI);
        trace("ApplyMatrix4: ${a.clone().applyMatrix4(m).equals(a)}");
        m.makeRotationX(Math.PI);
        var b = a.clone();
        b.direction.negate();
        var a2 = a.clone().applyMatrix4(m);
        trace("ApplyMatrix4: ${a2.origin.distanceTo(b.origin) < 0.0001} ${a2.direction.distanceTo(b.direction) < 0.0001}");
        a.origin = new Vector3(0, 0, 1);
        b.origin = new Vector3(0, 0, -1);
        a2 = a.clone().applyMatrix4(m);
        trace("ApplyMatrix4: ${a2.origin.distanceTo(b.origin) < 0.0001} ${a2.direction.distanceTo(b.direction) < 0.0001}");
    }
}

trace(RayTest.main());