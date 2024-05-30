import Math.Vector3;
import Math.Vector3Util;
import Math.Matrix4;
import Math.Plane;
import Math.Sphere;
import Math.Triangle;
import Math.AABB;
import Math.Ray;

class Box3Test {
    static public function run() {
        // INSTANCING
        var a = new AABB();
        trace("a.min.equals(posInf3): " + a.min.equals(Vector3Util.posInf3));
        trace("a.max.equals(negInf3): " + a.max.equals(Vector3Util.negInf3));

        a = new AABB(Vector3.zero, Vector3.zero);
        trace("a.min.equals(zero3): " + a.min.equals(Vector3.zero));
        trace("a.max.equals(zero3): " + a.max.equals(Vector3.zero));

        a = new AABB(Vector3.zero, Vector3.one);
        trace("a.min.equals(zero3): " + a.min.equals(Vector3.zero));
        trace("a.max.equals(one3): " + a.max.equals(Vector3.one));

        // PUBLIC STUFF
        trace("isBox3: " + a.isBox3);
        var b = new Sphere();
        trace("b.isBox3: " + b.isBox3);

        a = new AABB();
        a.set(Vector3.zero, Vector3.one);
        trace("a.min.equals(zero3): " + a.min.equals(Vector3.zero));
        trace("a.max.equals(one3): " + a.max.equals(Vector3.one));

        a = new AABB();
        a.setFromArray([0, 0, 0, 1, 1, 1, 2, 2, 2]);
        trace("a.min.equals(zero3): " + a.min.equals(Vector3.zero));
        trace("a.max.equals(two3): " + a.max.equals(Vector3.axisX * 2 + Vector3.axisY * 2 + Vector3.axisZ * 2));

        a = new AABB(Vector3.zero, Vector3.one);
        var bigger = new Array<Float>([
            -2, -2, -2, 2, 2, 2, 1.5, 1.5, 1.5, 0, 0, 0
        ]);
        var smaller = new Array<Float>([
            -0.5, -0.5, -0.5, 0.5, 0.5, 0.5, 0, 0, 0
        ]);
        var newMin = new Vector3(-2, -2, -2);
        var newMax = new Vector3(2, 2, 2);

        a.setFromBufferAttribute(bigger);
        trace("a.min.equals(newMin): " + a.min.equals(newMin));
        trace("a.max.equals(newMax): " + a.max.equals(newMax));

        newMin.set(-0.5, -0.5, -0.5);
        newMax.set(0.5, 0.5, 0.5);

        a.setFromBufferAttribute(smaller);
        trace("a.min.equals(newMin): " + a.min.equals(newMin));
        trace("a.max.equals(newMax): " + a.max.equals(newMax));

        a = new AABB();
        a.setFromPoints([Vector3.zero, Vector3.one, Vector3.axisX * 2 + Vector3.axisY * 2 + Vector3.axisZ * 2]);
        trace("a.min.equals(zero3): " + a.min.equals(Vector3.zero));
        trace("a.max.equals(two3): " + a.max.equals(Vector3.axisX * 2 + Vector3.axisY * 2 + Vector3.axisZ * 2));

        a.setFromPoints([Vector3.one]);
        trace("a.min.equals(one3): " + a.min.equals(Vector3.one));
        trace("a.max.equals(one3): " + a.max.equals(Vector3.one));

        a.setFromPoints([]);
        trace("a.isEmpty(): " + a.isEmpty());

        a = new AABB(Vector3.zero, Vector3.one);
        var b = a.clone();
        var centerA = new Vector3();
        var sizeA = new Vector3();
        var sizeB = new Vector3();
        var newCenter = Vector3.one;
        var newSize = Vector3.axisX * 2 + Vector3.axisY * 2 + Vector3.axisZ * 2;

        a.getCenter(centerA);
        a.getSize(sizeA);
        a.setFromCenterAndSize(centerA, sizeA);
        trace("a.equals(b): " + a.equals(b));

        a.setFromCenterAndSize(newCenter, sizeA);
        a.getCenter(centerA);
        a.getSize(sizeA);
        b.getSize(sizeB);

        trace("centerA.equals(newCenter): " + centerA.equals(newCenter));
        trace("sizeA.equals(sizeB): " + sizeA.equals(sizeB));
        trace("a.equals(b): " + a.equals(b));

        a.setFromCenterAndSize(centerA, newSize);
        a.getCenter(centerA);
        a.getSize(sizeA);
        trace("centerA.equals(newCenter): " + centerA.equals(newCenter));
        trace("sizeA.equals(newSize): " + sizeA.equals(newSize));
        trace("a.equals(b): " + a.equals(b));

        a = new AABB(Vector3.zero, Vector3.one);
        var object = new Mesh(new BoxGeometry(2, 2, 2));
        var child = new Mesh(new BoxGeometry(1, 1, 1));
        object.add(child);

        a.setFromObject(object);
        trace("a.min.equals(new Vector3(-1, -1, -1)): " + a.min.equals(Vector3.axisX * -1 + Vector3.axisY * -1 + Vector3.axisZ * -1));
        trace("a.max.equals(new Vector3(1, 1, 1)): " + a.max.equals(Vector3.one));

        object.rotation.setFromVector3(Vector3.axisZ * Math.PI / 4);

        a.setFromObject(object);
        var rotatedBox = new AABB(
            new Vector3(-2 * Math.sqrt(2), -2 * Math.sqrt(2), -2),
            new Vector3(2 * Math.sqrt(2), 2 * Math.sqrt(2), 2)
        );
        trace("compareBox(a, rotatedBox): " + a.equals(rotatedBox));

        a.setFromObject(object, true);
        var rotatedMinBox = new AABB(
            new Vector3(-2, -2, -2),
            new Vector3(2, 2, 2)
        );
        trace("compareBox(a, rotatedMinBox): " + a.equals(rotatedMinBox));

        a = new AABB(Vector3.zero, Vector3.one);
        b = a.clone();
        trace("b.min.equals(zero3): " + b.min.equals(Vector3.zero));
        trace("b.max.equals(one3): " + b.max.equals(Vector3.one));

        a = new AABB();
        b = a.clone();
        trace("b.min.equals(posInf3): " + b.min.equals(Vector3Util.posInf3));
        trace("b.max.equals(negInf3): " + b.max.equals(Vector3Util.negInf3));

        a = new AABB(Vector3.zero, Vector3.one);
        b = new AABB();
        b.copy(a);
        trace("b.min.equals(zero3): " + b.min.equals(Vector3.zero));
        trace("b.max.equals(one3): " + b.max.equals(Vector3.one));

        // ensure that it is a true copy
        a.min = Vector3.zero;
        a.max = Vector3.one;
        trace("b.min.equals(zero3): " + b.min.equals(Vector3.zero));
        trace("b.max.equals(one3): " + b.max.equals(Vector3.one));

        a = new AABB();
        trace("a.isEmpty(): " + a.isEmpty());

        a = new AABB(Vector3.zero, Vector3.zero);
        trace("!a.isEmpty(): " + !a.isEmpty());

        a = new AABB(Vector3.zero, Vector3.one);
        trace("!a.isEmpty(): " + !a.isEmpty());

        a = new AABB(Vector3.axisX * 2 + Vector3.axisY * 2 + Vector3.axisZ * 2, Vector3.one);
        trace("a.isEmpty(): " + a.isEmpty());

        a = new AABB(Vector3Util.posInf3, Vector3Util.negInf3);
        trace("a.isEmpty(): " + a.isEmpty());

        a = new AABB(Vector3.zero, Vector3.zero);
        center = new Vector3();

        trace("a.getCenter(center).equals(zero3): " + a.getCenter(center).equals(Vector3.zero));

        a = new AABB(Vector3.zero, Vector3.one);
        size = new Vector3();

        trace("a.getSize(size).equals(zero3): " + a.getSize(size).equals(Vector3.zero));

        trace("a.getSize(size).equals(one3): " + a.getSize(size).equals(Vector3.one));

        a = new AABB(Vector3.zero, Vector3.zero);
        center = new Vector3();
        size = new Vector3();

        a.expandByPoint(Vector3.zero);
        trace("a.getSize(size).equals(zero3): " + a.getSize(size).equals(Vector3.zero));

        a.expandByPoint(Vector3.one);
        trace("a.getSize(size).equals(one3): " + a.getSize(size).equals(Vector3.one));

        a.expandByPoint(Vector3.one * -1);
        trace("a.getSize(size).equals(one3.clone().multiplyScalar(2)): " + a.getSize(size).equals(Vector3.one * 2));
        trace("a.getCenter(center).equals(zero3): " + a.getCenter(center).equals(Vector3.zero));

        a = new AABB(Vector3.zero, Vector3.zero);
        center = new Vector3();
        size = new Vector3();

        a.expandByVector(Vector3.zero);
        trace("a.getSize(size).equals(zero3): " + a.getSize(size).equals(Vector3.zero));

        a.expandByVector(Vector3.one);
        trace("a.getSize(size).equals(one3.clone().multiplyScalar(2)): " + a.getSize(size).equals(Vector3.one * 2));
        trace("a.getCenter(center).equals(zero3): " + a.getCenter(center).equals(Vector3.zero));

        a = new AABB(Vector3.zero, Vector3.zero);
        center = new Vector3();
        size = new Vector3();

        a.expandByScalar(0);
        trace("a.getSize(size).equals(zero3): " + a.getSize(size).equals(Vector3.zero));

        a.expandByScalar(1);
        trace("a.getSize(size).equals(one3.clone().multiplyScalar(2)): " + a.getSize(size).equals(Vector3.one * 2));
        trace("a.getCenter(center).equals(zero3): " + a.getCenter(center).equals(Vector3.zero));

        a = new AABB(Vector3.zero, Vector3.one);
        b = a.clone();
        bigger = new Mesh(new BoxGeometry(2, 2, 2));
        smaller = new Mesh(new BoxGeometry(0.5, 0.5, 0.5));
        child = new Mesh(new BoxGeometry(1, 1, 1));

        // just a bigger box to begin with
        a.expandByObject(bigger);
        trace("a.min.equals(new Vector3(-1, -1, -1)): " + a.min.equals(Vector3.axisX * -1 + Vector3.axisY * -1 + Vector3.axisZ * -1));
        trace("a.max.equals(new Vector3(1, 1, 1)): " + a.max.equals(Vector3.one));

        // a translated, bigger box
        a.copy(b);
        bigger.translateX(2);
        a.expandByObject(bigger);
        trace("a.min.equals(new Vector3(0, -1, -1)): " + a.min.equals(Vector3.axisX + Vector3.axisY * -1 + Vector3.axisZ * -1));
        trace("a.max.equals(new Vector3(3, 1, 1)): " + a.max.equals(Vector3.axisX * 3 + Vector3.axisY + Vector3.axisZ));

        // a translated, bigger box with child
        a.copy(b);
        bigger.add(child);
        a.expandByObject(bigger);
        trace("a.min.equals(new Vector3(0, -1, -1)): " + a.min.equals(Vector3.axisX + Vector3.axisY * -1 + Vector3.axisZ * -1));
        trace("a.max.equals(new Vector3(3, 1, 1)): " + a.max.equals(Vector3.axisX * 3 + Vector3.axisY + Vector3.axisZ));

        // a translated, bigger box with a translated child
        a.copy(b);
        child.translateX(2);
        a.expandByObject(bigger);
        trace("a.min.equals(new Vector3(0, -1, -1)): " + a.min.equals(Vector3.axisX + Vector3.axisY * -1 + Vector3.axisZ * -1));
        trace("a.max.equals(new Vector3(4.5, 1, 1)): " + a.max.equals(Vector3.axisX * 4.5 + Vector3.axisY + Vector3.axisZ));

        // a smaller box
        a.copy(b);
        a.expandByObject(smaller);
        trace("a.min.equals(new Vector3(-0.25, -0.25, -0.25)): " + a.min.equals(Vector3.axisX * -0.25 + Vector3.axisY * -0.25 + Vector3.axisZ * -0.25));
        trace("a.max.equals(new Vector3(1, 1, 1)): " + a.max.equals(Vector3.one));

        trace("new Box3().expandByObject(new Mesh()).isEmpty(): " + new AABB().expandByObject(new Mesh()).isEmpty());

        a = new AABB(Vector3.zero, Vector3.zero);

        trace("a.containsPoint(zero3): " + a.containsPoint(Vector3.zero));
        trace("!a.containsPoint(one3): " + !a.containsPoint(Vector3.one));

        a.expandByScalar(1);
        trace("a.containsPoint(zero3): " + a.containsPoint(Vector3.zero));
        trace("a.containsPoint(one3): " + a.containsPoint(Vector3.one));
        trace("a.containsPoint(one3.clone().negate()): " + a.containsPoint(Vector3.one * -1));

        a = new AABB(Vector3.zero, Vector3.zero);
        b = new AABB(Vector3.zero, Vector3.one);
        c = new AABB(Vector3.one * -1, Vector3.one);

        trace("a.containsBox(a): " + a.containsBox(a));
        trace("a.containsBox(b): " + a.containsBox(b));
        trace("a.containsBox(c): " + a.containsBox(c));

        trace("b.containsBox(a): " + b.containsBox(a));
        trace("c.containsBox(a): " + c.containsBox(a));
        trace("!b.containsBox(c): " + !b.containsBox(c));

        a = new AABB(Vector3.zero, Vector3.one);
        b = new AABB(Vector3.one, Vector3.one);
        c = new AABB(Vector3.one * -1, Vector3.one);
        parameter = new Vector3();

        a.getParameter(Vector3.zero, parameter);
        trace("parameter.equals(zero3): " + parameter.equals(Vector3.zero));
        a.getParameter(Vector3.one,