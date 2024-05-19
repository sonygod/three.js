package three.math;

import haxe.unit.TestCase;
import three.math.Box3;
import three.math.Matrix4;
import three.math.Plane;
import three.math.Sphere;
import three.math.Vector3;

class SphereTests {
    public function new() {}

    public function testSphere():Void {
        TestCase.assertEquals(new Sphere().center.equals(Vector3.ZERO), true, 'Default center');
        TestCase.assertEquals(new Sphere().radius, -1, 'Default radius');

        var a = new Sphere(Vector3.ONE.clone(), 1);
        TestCase.assertEquals(a.center.equals(Vector3.ONE), true, 'Constructed center');
        TestCase.assertEquals(a.radius, 1, 'Constructed radius');

        // PUBLIC
        TestCase.assertEquals(new Sphere().isSphere, true, 'Is sphere');
        TestCase.assertEquals(new Box3().isSphere, false, 'Is not sphere');

        // SET
        var a = new Sphere();
        TestCase.assertEquals(a.center.equals(Vector3.ZERO), true, 'Default center');
        TestCase.assertEquals(a.radius, -1, 'Default radius');

        a.set(Vector3.ONE, 1);
        TestCase.assertEquals(a.center.equals(Vector3.ONE), true, 'Set center');
        TestCase.assertEquals(a.radius, 1, 'Set radius');

        // SET FROM POINTS
        a = new Sphere();
        var expectedCenter = new Vector3(0.9330126941204071, 0, 0);
        var expectedRadius = 1.3676668773461689;
        var optionalCenter = new Vector3(1, 1, 1);
        var points = [
            new Vector3(1, 1, 0), new Vector3(1, 1, 0),
            new Vector3(1, 1, 0), new Vector3(1, 1, 0),
            new Vector3(1, 1, 0), new Vector3(0.8660253882408142, 0.5, 0),
            new Vector3(-0, 0.5, 0.8660253882408142), new Vector3(1.8660253882408142, 0.5, 0),
            new Vector3(0, 0.5, -0.8660253882408142), new Vector3(0.8660253882408142, 0.5, -0),
            new Vector3(0.8660253882408142, -0.5, 0), new Vector3(-0, -0.5, 0.8660253882408142),
            new Vector3(1.8660253882408142, -0.5, 0), new Vector3(0, -0.5, -0.8660253882408142),
            new Vector3(0.8660253882408142, -0.5, -0), new Vector3(-0, -1, 0),
            new Vector3(-0, -1, 0), new Vector3(0, -1, 0),
            new Vector3(0, -1, -0), new Vector3(-0, -1, -0),
        ];

        a.setFromPoints(points);
        TestCase.assertTrue(Math.isClose(a.center.x, expectedCenter.x, MathConstants.EPSILON));
        TestCase.assertTrue(Math.isClose(a.center.y, expectedCenter.y, MathConstants.EPSILON));
        TestCase.assertTrue(Math.isClose(a.center.z, expectedCenter.z, MathConstants.EPSILON));
        TestCase.assertTrue(Math.isClose(a.radius, expectedRadius, MathConstants.EPSILON));

        expectedRadius = 2.5946195770400102;
        a.setFromPoints(points, optionalCenter);
        TestCase.assertTrue(Math.isClose(a.center.x, optionalCenter.x, MathConstants.EPSILON));
        TestCase.assertTrue(Math.isClose(a.center.y, optionalCenter.y, MathConstants.EPSILON));
        TestCase.assertTrue(Math.isClose(a.center.z, optionalCenter.z, MathConstants.EPSILON));
        TestCase.assertTrue(Math.isClose(a.radius, expectedRadius, MathConstants.EPSILON));

        // TODO: implement clone test

        // COPY
        a = new Sphere(Vector3.ONE.clone(), 1);
        var b = new Sphere().copy(a);

        TestCase.assertEquals(b.center.equals(Vector3.ONE), true, 'Copied center');
        TestCase.assertEquals(b.radius, 1, 'Copied radius');

        a.center = Vector3.ZERO;
        a.radius = 0;
        TestCase.assertEquals(b.center.equals(Vector3.ONE), true, 'Copied center is unchanged');
        TestCase.assertEquals(b.radius, 1, 'Copied radius is unchanged');

        // IS EMPTY
        a = new Sphere();
        TestCase.assertEquals(a.isEmpty(), true, 'Default is empty');

        a.set(Vector3.ONE, 1);
        TestCase.assertEquals(a.isEmpty(), false, 'Non-empty');

        a.set(Vector3.ONE, -1);
        TestCase.assertEquals(a.isEmpty(), true, 'Negative radius is empty');

        a.set(Vector3.ONE, 0);
        TestCase.assertEquals(a.isEmpty(), false, 'Zero radius is not empty');

        // MAKE EMPTY
        a = new Sphere(Vector3.ONE.clone(), 1);

        TestCase.assertEquals(a.isEmpty(), false, 'Not empty');
        a.makeEmpty();
        TestCase.assertEquals(a.isEmpty(), true, 'Made empty');
        TestCase.assertEquals(a.center.equals(Vector3.ZERO), true, 'Center reset');

        // CONTAINS POINT
        a = new Sphere(Vector3.ONE.clone(), 1);

        TestCase.assertEquals(a.containsPoint(Vector3.ZERO), false, 'Does not contain');
        TestCase.assertEquals(a.containsPoint(Vector3.ONE), true, 'Contains');

        a.set(Vector3.ZERO, 0);
        TestCase.assertEquals(a.containsPoint(a.center), true, 'Contains center');

        // DISTANCE TO POINT
        a = new Sphere(Vector3.ONE.clone(), 1);

        TestCase.assertTrue(Math.isClose(a.distanceToPoint(Vector3.ZERO), 0.7320, MathConstants.EPSILON));
        TestCase.assertEquals(a.distanceToPoint(Vector3.ONE), -1, 'Distance to center');

        // INTERSECTS SPHERE
        a = new Sphere(Vector3.ONE.clone(), 1);
        var b = new Sphere(Vector3.ZERO.clone(), 1);
        var c = new Sphere(Vector3.ZERO.clone(), 0.25);

        TestCase.assertEquals(a.intersectsSphere(b), true, 'Intersects');
        TestCase.assertEquals(a.intersectsSphere(c), false, 'Does not intersect');

        // INTERSECTS BOX
        a = new Sphere(Vector3.ZERO.clone(), 1);
        b = new Sphere(new Vector3(-5, -5, -5), 1);
        var box = new Box3(Vector3.ZERO, Vector3.ONE);

        TestCase.assertEquals(a.intersectsBox(box), true, 'Intersects box');
        TestCase.assertEquals(b.intersectsBox(box), false, 'Does not intersect box');

        // INTERSECTS PLANE
        a = new Sphere(Vector3.ZERO.clone(), 1);
        var plane = new Plane(new Vector3(0, 1, 0), 1);
        var plane2 = new Plane(new Vector3(0, 1, 0), 1.25);
        var plane3 = new Plane(new Vector3(0, -1, 0), 1.25);

        TestCase.assertEquals(a.intersectsPlane(plane), true, 'Intersects plane');
        TestCase.assertEquals(a.intersectsPlane(plane2), false, 'Does not intersect plane');
        TestCase.assertEquals(a.intersectsPlane(plane3), false, 'Does not intersect plane');

        // CLAMP POINT
        a = new Sphere(Vector3.ONE.clone(), 1);
        var point = new Vector3();

        a.clampPoint(new Vector3(1, 1, 3), point);
        TestCase.assertEquals(point.equals(new Vector3(1, 1, 2)), true, 'Clamped point');

        a.clampPoint(new Vector3(1, 1, -3), point);
        TestCase.assertEquals(point.equals(new Vector3(1, 1, 0)), true, 'Clamped point');

        // GET BOUNDING BOX
        a = new Sphere(Vector3.ONE.clone(), 1);
        var aabb = new Box3();

        a.getBoundingBox(aabb);
        TestCase.assertEquals(aabb.equals(new Box3(Vector3.ZERO, Vector3.TWO)), true, 'Bounding box');

        a.set(Vector3.ZERO, 0);
        a.getBoundingBox(aabb);
        TestCase.assertEquals(aabb.equals(new Box3(Vector3.ZERO, Vector3.ZERO)), true, 'Bounding box');

        a.makeEmpty();
        a.getBoundingBox(aabb);
        TestCase.assertEquals(aabb.isEmpty(), true, 'Empty bounding box');

        // APPLY MATRIX 4
        a = new Sphere(Vector3.ONE.clone(), 1);
        var m = new Matrix4().makeTranslation(1, -2, 1);
        var aabb1 = new Box3();
        var aabb2 = new Box3();

        a.clone().applyMatrix4(m).getBoundingBox(aabb1);
        a.getBoundingBox(aabb2);

        TestCase.assertEquals(aabb1.equals(aabb2.applyMatrix4(m)), true, 'Applied matrix');

        // TRANSLATE
        a = new Sphere(Vector3.ONE.clone(), 1);

        a.translate(Vector3.ONE.clone().negate());
        TestCase.assertEquals(a.center.equals(Vector3.ZERO), true, 'Translated center');

        // EXPAND BY POINT
        a = new Sphere(Vector3.ZERO.clone(), 1);
        var p = new Vector3(2, 0, 0);

        TestCase.assertEquals(a.containsPoint(p), false, 'Does not contain point');

        a.expandByPoint(p);

        TestCase.assertEquals(a.containsPoint(p), true, 'Contains point');
        TestCase.assertEquals(a.center.equals(new Vector3(0.5, 0, 0)), true, 'New center');
        TestCase.assertEquals(a.radius, 1.5, 'New radius');

        // UNION
        a = new Sphere(Vector3.ZERO.clone(), 1);
        b = new Sphere(new Vector3(2, 0, 0), 1);

        a.union(b);

        TestCase.assertEquals(a.center.equals(new Vector3(1, 0, 0)), true, 'New center');
        TestCase.assertEquals(a.radius, 2, 'New radius');

        // EQUALS
        a = new Sphere();
        b = new Sphere(new Vector3(1, 0, 0));
        c = new Sphere(new Vector3(1, 0, 0), 1.0);

        TestCase.assertEquals(a.equals(b), false, 'a does not equal b');
        TestCase.assertEquals(a.equals(c), false, 'a does not equal c');
        TestCase.assertEquals(b.equals(c), false, 'b does not equal c');

        a.copy(b);
        TestCase.assertEquals(a.equals(b), true, 'a equals b after copy()');
    }
}