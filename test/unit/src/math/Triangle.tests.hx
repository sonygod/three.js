Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.math;

import haxe.unit.TestCase;

class TriangleTests {

    public function new() {}

    public static function main():Void {
        TestCase.createTest(TriangleTests);
    }

    public function testInstancing():Void {
        var a:Triangle = new Triangle();
        Assert.isTrue(a.a.equals(zero3));
        Assert.isTrue(a.b.equals(zero3));
        Assert.isTrue(a.c.equals(zero3));

        a = new Triangle(one3.clone().negate(), one3.clone(), two3.clone());
        Assert.isTrue(a.a.equals(one3.clone().negate()));
        Assert.isTrue(a.b.equals(one3));
        Assert.isTrue(a.c.equals(two3));
    }

    public function testGetNormal():Void {
        Assert.fail("not implemented");
    }

    public function testGetBarycoord():Void {
        Assert.fail("not implemented");
    }

    public function testContainsPoint():Void {
        Assert.fail("not implemented");
    }

    public function testGetInterpolation():Void {
        Assert.fail("not implemented");
    }

    public function testIsFrontFacing():Void {
        Assert.fail("not implemented");
    }

    public function testSet():Void {
        var a:Triangle = new Triangle();
        a.set(one3.clone().negate(), one3, two3);
        Assert.isTrue(a.a.equals(one3.clone().negate()));
        Assert.isTrue(a.b.equals(one3));
        Assert.isTrue(a.c.equals(two3));
    }

    public function testSetFromPointsAndIndices():Void {
        var a:Triangle = new Triangle();
        var points:Array<Vector3> = [one3, one3.clone().negate(), two3];
        a.setFromPointsAndIndices(points, 1, 0, 2);
        Assert.isTrue(a.a.equals(one3.clone().negate()));
        Assert.isTrue(a.b.equals(one3));
        Assert.isTrue(a.c.equals(two3));
    }

    public function testSetFromAttributeAndIndices():Void {
        var a:Triangle = new Triangle();
        var attribute:BufferAttribute = new BufferAttribute(new Float32Array([1, 1, 1, -1, -1, -1, 2, 2, 2]), 3);
        a.setFromAttributeAndIndices(attribute, 1, 0, 2);
        Assert.isTrue(a.a.equals(one3.clone().negate()));
        Assert.isTrue(a.b.equals(one3));
        Assert.isTrue(a.c.equals(two3));
    }

    public function testClone():Void {
        Assert.fail("not implemented");
    }

    public function testCopy():Void {
        var a:Triangle = new Triangle(one3.clone().negate(), one3.clone(), two3.clone());
        var b:Triangle = new Triangle().copy(a);
        Assert.isTrue(b.a.equals(one3.clone().negate()));
        Assert.isTrue(b.b.equals(one3));
        Assert.isTrue(b.c.equals(two3));

        a.a = one3;
        a.b = zero3;
        a.c = zero3;
        Assert.isTrue(b.a.equals(one3.clone().negate()));
        Assert.isTrue(b.b.equals(one3));
        Assert.isTrue(b.c.equals(two3));
    }

    public function testGetArea():Void {
        var a:Triangle = new Triangle();
        Assert.isTrue(a.getArea() == 0);

        a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        Assert.isTrue(a.getArea() == 0.5);

        a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
        Assert.isTrue(a.getArea() == 2);

        a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(3, 0, 0));
        Assert.isTrue(a.getArea() == 0);
    }

    public function testGetMidpoint():Void {
        var a:Triangle = new Triangle();
        var midpoint:Vector3 = new Vector3();
        Assert.isTrue(a.getMidpoint(midpoint).equals(new Vector3(0, 0, 0)));

        a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        Assert.isTrue(a.getMidpoint(midpoint).equals(new Vector3(1 / 3, 1 / 3, 0)));

        a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
        Assert.isTrue(a.getMidpoint(midpoint).equals(new Vector3(2 / 3, 0, 2 / 3)));
    }

    public function testGetNormal():Void {
        var a:Triangle = new Triangle();
        var normal:Vector3 = new Vector3();
        Assert.isTrue(a.getNormal(normal).equals(new Vector3(0, 0, 0)));

        a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        Assert.isTrue(a.getNormal(normal).equals(new Vector3(0, 0, 1)));

        a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
        Assert.isTrue(a.getNormal(normal).equals(new Vector3(0, 1, 0)));
    }

    public function testGetPlane():Void {
        var a:Triangle = new Triangle();
        var plane:Plane = new Plane();
        var normal:Vector3 = new Vector3();
        Assert.isTrue(!Math.isNaN(plane.distanceToPoint(a.a)));
        Assert.isTrue(!Math.isNaN(plane.distanceToPoint(a.b)));
        Assert.isTrue(!Math.isNaN(plane.distanceToPoint(a.c)));
        Assert.isFalse(plane.normal.equals(new Vector3(NaN, NaN, NaN)));

        a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        a.getPlane(plane);
        a.getNormal(normal);
        Assert.isTrue(plane.distanceToPoint(a.a) == 0);
        Assert.isTrue(plane.distanceToPoint(a.b) == 0);
        Assert.isTrue(plane.distanceToPoint(a.c) == 0);
        Assert.isTrue(plane.normal.equals(normal));

        a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
        a.getPlane(plane);
        a.getNormal(normal);
        Assert.isTrue(plane.distanceToPoint(a.a) == 0);
        Assert.isTrue(plane.distanceToPoint(a.b) == 0);
        Assert.isTrue(plane.distanceToPoint(a.c) == 0);
        Assert.isTrue(plane.normal.clone().normalize().equals(normal));
    }

    public function testGetBarycoord():Void {
        var a:Triangle = new Triangle();
        var midpoint:Vector3 = new Vector3();
        var barycoord:Vector3 = new Vector3();

        Assert.isNull(a.getBarycoord(a.a, barycoord));
        Assert.isNull(a.getBarycoord(a.b, barycoord));
        Assert.isNull(a.getBarycoord(a.c, barycoord));

        a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        a.getMidpoint(midpoint);

        a.getBarycoord(a.a, barycoord);
        Assert.isTrue(barycoord.equals(new Vector3(1, 0, 0)));

        a.getBarycoord(a.b, barycoord);
        Assert.isTrue(barycoord.equals(new Vector3(0, 1, 0)));

        a.getBarycoord(a.c, barycoord);
        Assert.isTrue(barycoord.equals(new Vector3(0, 0, 1)));

        a.getBarycoord(midpoint, barycoord);
        Assert.isTrue(barycoord.distanceTo(new Vector3(1 / 3, 1 / 3, 1 / 3)) < 0.0001);
    }

    public function testIntersectsBox():Void {
        var a:Box3 = new Box3(one3.clone(), two3.clone());
        var b:Triangle = new Triangle(new Vector3(1.5, 1.5, 2.5), new Vector3(2.5, 1.5, 1.5), new Vector3(1.5, 2.5, 1.5));
        var c:Triangle = new Triangle(new Vector3(1.5, 1.5, 3.5), new Vector3(3.5, 1.5, 1.5), new Vector3(1.5, 1.5, 1.5));
        var d:Triangle = new Triangle(new Vector3(1.5, 1.75, 3), new Vector3(3, 1.75, 1.5), new Vector3(1.5, 2.5, 1.5));
        var e:Triangle = new Triangle(new Vector3(1.5, 1.8, 3), new Vector3(3, 1.8, 1.5), new Vector3(1.5, 2.5, 1.5));
        var f:Triangle = new Triangle(new Vector3(1.5, 2.5, 3), new Vector3(3, 2.5, 1.5), new Vector3(1.5, 2.5, 1.5));

        Assert.isTrue(b.intersectsBox(a));
        Assert.isTrue(c.intersectsBox(a));
        Assert.isTrue(d.intersectsBox(a));
        Assert.isFalse(e.intersectsBox(a));
        Assert.isFalse(f.intersectsBox(a));
    }

    public function testClosestPointToPoint():Void {
        var a:Triangle = new Triangle(new Vector3(-1, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        var point:Vector3 = new Vector3();

        a.closestPointToPoint(new Vector3(0, 0.5, 0), point);
        Assert.isTrue(point.equals(new Vector3(0, 0.5, 0)));

        a.closestPointToPoint(a.a, point);
        Assert.isTrue(point.equals(a.a));

        a.closestPointToPoint(a.b, point);
        Assert.isTrue(point.equals(a.b));

        a.closestPointToPoint(a.c, point);
        Assert.isTrue(point.equals(a.c));

        a.closestPointToPoint(zero3.clone(), point);
        Assert.isTrue(point.equals(zero3.clone()));

        a.closestPointToPoint(new Vector3(-2, 0, 0), point);
        Assert.isTrue(point.equals(new Vector3(-1, 0, 0)));

        a.closestPointToPoint(new Vector3(2, 0, 0), point);
        Assert.isTrue(point.equals(new Vector3(1, 0, 0)));

        a.closestPointToPoint(new Vector3(0, 2, 0), point);
        Assert.isTrue(point.equals(new Vector3(0, 1, 0)));

        a.closestPointToPoint(new Vector3(0, -2, 0), point);
        Assert.isTrue(point.equals(new Vector3(0, 0, 0)));
    }

    public function testIsFrontFacing():Void {
        var a:Triangle = new Triangle();
        var dir:Vector3 = new Vector3();
        Assert.isFalse(a.isFrontFacing(dir));

        a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
        dir = new Vector3(0, 0, -1);
        Assert.isTrue(a.isFrontFacing(dir));

        a = new Triangle(new Vector3(0, 0, 0), new Vector3(0, 1, 0), new Vector3(1, 0, 0));
        Assert.isFalse(a.isFrontFacing(dir));
    }

    public function testEquals():Void {
        var a:Triangle = new Triangle(new Vector3(1, 0, 0), new Vector3(0, 1, 0), new Vector3(0, 0, 1));
        var b:Triangle = new Triangle(new Vector3(0, 0, 1), new Vector3(0, 1, 0), new Vector3(1, 0, 0));
        var c:Triangle = new Triangle(new Vector3(-1, 0, 0), new Vector3(0, 1, 0), new Vector3(0, 0, 1));

        Assert.isTrue(a.equals(a));
        Assert.isFalse(a.equals(b));
        Assert.isFalse(a.equals(c));
        Assert.isFalse(b.equals(c));

        a.copy(b);
        Assert.isTrue(a.equals(a));
    }
}
```
Note that I've used the `haxe.unit` package for the test case, and I've assumed that the `BufferAttribute`, `Box3`, `Plane`, `Triangle`, and `Vector3` classes are already defined.