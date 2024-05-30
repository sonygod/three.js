package three.math;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;
import three.math.Box2;
import three.math.Vector2;

class Box2Test {

    public function new() {}

    public function testInstancing() : Void {
        var a = new Box2();
        assertTrue(a.min.equals(new Vector2(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY)));
        assertTrue(a.max.equals(new Vector2(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY)));

        a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        assertTrue(a.min.equals(new Vector2(0, 0)));
        assertTrue(a.max.equals(new Vector2(0, 0)));

        a = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        assertTrue(a.min.equals(new Vector2(0, 0)));
        assertTrue(a.max.equals(new Vector2(1, 1)));
    }

    public function testIsBox2() : Void {
        var a = new Box2();
        assertTrue(a.isBox2);

        var b = {};
        assertFalse(b.isBox2);
    }

    public function testSet() : Void {
        var a = new Box2();
        a.set(new Vector2(0, 0), new Vector2(1, 1));
        assertTrue(a.min.equals(new Vector2(0, 0)));
        assertTrue(a.max.equals(new Vector2(1, 1)));
    }

    public function testSetFromPoints() : Void {
        var a = new Box2();
        a.setFromPoints([new Vector2(0, 0), new Vector2(1, 1), new Vector2(2, 2)]);
        assertTrue(a.min.equals(new Vector2(0, 0)));
        assertTrue(a.max.equals(new Vector2(2, 2)));

        a.setFromPoints([new Vector2(1, 1)]);
        assertTrue(a.min.equals(new Vector2(1, 1)));
        assertTrue(a.max.equals(new Vector2(1, 1)));

        a.setFromPoints([]);
        assertTrue(a.isEmpty());
    }

    public function testSetFromCenterAndSize() : Void {
        var a = new Box2();
        a.setFromCenterAndSize(new Vector2(0, 0), new Vector2(2, 2));
        assertTrue(a.min.equals(new Vector2(-1, -1)));
        assertTrue(a.max.equals(new Vector2(1, 1)));

        a.setFromCenterAndSize(new Vector2(1, 1), new Vector2(2, 2));
        assertTrue(a.min.equals(new Vector2(0, 0)));
        assertTrue(a.max.equals(new Vector2(2, 2)));

        a.setFromCenterAndSize(new Vector2(0, 0), new Vector2(0, 0));
        assertTrue(a.min.equals(new Vector2(0, 0)));
        assertTrue(a.max.equals(new Vector2(0, 0)));
    }

    public function testClone() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        var b = a.clone();
        assertTrue(b.min.equals(new Vector2(0, 0)));
        assertTrue(b.max.equals(new Vector2(0, 0)));

        a = new Box2();
        b = a.clone();
        assertTrue(b.min.equals(new Vector2(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY)));
        assertTrue(b.max.equals(new Vector2(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY)));
    }

    public function testCopy() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        var b = new Box2().copy(a);
        assertTrue(b.min.equals(new Vector2(0, 0)));
        assertTrue(b.max.equals(new Vector2(1, 1)));

        // ensure that it is a true copy
        a.min = new Vector2(0, 0);
        a.max = new Vector2(1, 1);
        assertTrue(b.min.equals(new Vector2(0, 0)));
        assertTrue(b.max.equals(new Vector2(1, 1)));
    }

    public function testEmptyMakeEmpty() : Void {
        var a = new Box2();
        assertTrue(a.isEmpty());

        a = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        assertFalse(a.isEmpty());

        a.makeEmpty();
        assertTrue(a.isEmpty());
    }

    public function testIsEmpty() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        assertFalse(a.isEmpty());

        a = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        assertFalse(a.isEmpty());

        a = new Box2(new Vector2(2, 2), new Vector2(1, 1));
        assertTrue(a.isEmpty());

        a = new Box2(new Vector2(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY), new Vector2(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY));
        assertTrue(a.isEmpty());
    }

    public function testGetCenter() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        var center = new Vector2();
        assertTrue(a.getCenter(center).equals(new Vector2(0, 0)));

        a = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        center = new Vector2();
        assertTrue(a.getCenter(center).equals(new Vector2(0.5, 0.5)));
    }

    public function testGetSize() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        var size = new Vector2();
        assertTrue(a.getSize(size).equals(new Vector2(0, 0)));

        a = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        size = new Vector2();
        assertTrue(a.getSize(size).equals(new Vector2(1, 1)));
    }

    public function testExpandByPoint() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        var size = new Vector2();
        var center = new Vector2();

        a.expandByPoint(new Vector2(0, 0));
        assertTrue(a.getSize(size).equals(new Vector2(0, 0)));

        a.expandByPoint(new Vector2(1, 1));
        assertTrue(a.getSize(size).equals(new Vector2(1, 1)));
        assertTrue(a.getCenter(center).equals(new Vector2(0.5, 0.5)));

        a.expandByPoint(new Vector2(-1, -1));
        assertTrue(a.getSize(size).equals(new Vector2(2, 2)));
        assertTrue(a.getCenter(center).equals(new Vector2(0, 0)));
    }

    public function testExpandByVector() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        var size = new Vector2();
        var center = new Vector2();

        a.expandByVector(new Vector2(0, 0));
        assertTrue(a.getSize(size).equals(new Vector2(0, 0)));

        a.expandByVector(new Vector2(1, 1));
        assertTrue(a.getSize(size).equals(new Vector2(2, 2)));
        assertTrue(a.getCenter(center).equals(new Vector2(0, 0)));
    }

    public function testExpandByScalar() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        var size = new Vector2();
        var center = new Vector2();

        a.expandByScalar(0);
        assertTrue(a.getSize(size).equals(new Vector2(0, 0)));

        a.expandByScalar(1);
        assertTrue(a.getSize(size).equals(new Vector2(2, 2)));
        assertTrue(a.getCenter(center).equals(new Vector2(0, 0)));
    }

    public function testContainsPoint() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));

        assertTrue(a.containsPoint(new Vector2(0, 0)));
        assertFalse(a.containsPoint(new Vector2(1, 1)));

        a.expandByScalar(1);
        assertTrue(a.containsPoint(new Vector2(0, 0)));
        assertTrue(a.containsPoint(new Vector2(1, 1)));
        assertTrue(a.containsPoint(new Vector2(-1, -1)));
    }

    public function testContainsBox() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        var b = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        var c = new Box2(new Vector2(-1, -1), new Vector2(1, 1));

        assertTrue(a.containsBox(a));
        assertFalse(a.containsBox(b));
        assertFalse(a.containsBox(c));

        assertTrue(b.containsBox(a));
        assertTrue(c.containsBox(a));
        assertFalse(b.containsBox(c));
    }

    public function testGetParameter() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        var b = new Box2(new Vector2(-1, -1), new Vector2(1, 1));

        var parameter = new Vector2();

        a.getParameter(new Vector2(0, 0), parameter);
        assertTrue(parameter.equals(new Vector2(0, 0)));

        a.getParameter(new Vector2(1, 1), parameter);
        assertTrue(parameter.equals(new Vector2(1, 1)));

        b.getParameter(new Vector2(-1, -1), parameter);
        assertTrue(parameter.equals(new Vector2(0, 0)));
        b.getParameter(new Vector2(0, 0), parameter);
        assertTrue(parameter.equals(new Vector2(0.5, 0.5)));
        b.getParameter(new Vector2(1, 1), parameter);
        assertTrue(parameter.equals(new Vector2(1, 1)));
    }

    public function testIntersectsBox() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        var b = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        var c = new Box2(new Vector2(-1, -1), new Vector2(1, 1));

        assertTrue(a.intersectsBox(a));
        assertTrue(a.intersectsBox(b));
        assertTrue(a.intersectsBox(c));

        assertTrue(b.intersectsBox(a));
        assertTrue(c.intersectsBox(a));

        b.translate(new Vector2(2, 2));
        assertFalse(a.intersectsBox(b));
        assertFalse(b.intersectsBox(a));
        assertFalse(b.intersectsBox(c));
    }

    public function testClampPoint() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        var b = new Box2(new Vector2(-1, -1), new Vector2(1, 1));

        var point = new Vector2();

        a.clampPoint(new Vector2(0, 0), point);
        assertTrue(point.equals(new Vector2(0, 0)));

        a.clampPoint(new Vector2(1, 1), point);
        assertTrue(point.equals(new Vector2(0, 0)));

        a.clampPoint(new Vector2(-1, -1), point);
        assertTrue(point.equals(new Vector2(0, 0)));

        b.clampPoint(new Vector2(2, 2), point);
        assertTrue(point.equals(new Vector2(1, 1)));

        b.clampPoint(new Vector2(1, 1), point);
        assertTrue(point.equals(new Vector2(1, 1)));

        b.clampPoint(new Vector2(0, 0), point);
        assertTrue(point.equals(new Vector2(0, 0)));

        b.clampPoint(new Vector2(-1, -1), point);
        assertTrue(point.equals(new Vector2(-1, -1)));

        b.clampPoint(new Vector2(-2, -2), point);
        assertTrue(point.equals(new Vector2(-1, -1)));
    }

    public function testDistanceToPoint() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        var b = new Box2(new Vector2(-1, -1), new Vector2(1, 1));

        assertEquals(a.distanceToPoint(new Vector2(0, 0)), 0);

        assertEquals(a.distanceToPoint(new Vector2(1, 1)), Math.sqrt(2));

        assertEquals(a.distanceToPoint(new Vector2(-1, -1)), Math.sqrt(2));

        assertEquals(b.distanceToPoint(new Vector2(2, 2)), Math.sqrt(2));
        assertEquals(b.distanceToPoint(new Vector2(1, 1)), 0);
        assertEquals(b.distanceToPoint(new Vector2(0, 0)), 0);
        assertEquals(b.distanceToPoint(new Vector2(-1, -1)), 0);
        assertEquals(b.distanceToPoint(new Vector2(-2, -2)), Math.sqrt(2));
    }

    public function testIntersect() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        var b = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        var c = new Box2(new Vector2(-1, -1), new Vector2(1, 1));
        var d = new Box2(new Vector2(-1, -1), new Vector2(0, 0));
        var e = new Box2();

        e = b.intersect(d);
        assertTrue(e.min.equals(new Vector2(0, 0)));
        assertTrue(e.max.equals(new Vector2(0, 0)));
    }

    public function testUnion() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        var b = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        var c = new Box2(new Vector2(-1, -1), new Vector2(1, 1));

        assertTrue(a.union(a).equals(a));
        assertTrue(a.union(b).equals(b));
        assertTrue(a.union(c).equals(c));
        assertTrue(b.union(c).equals(c));
    }

    public function testTranslate() : Void {
        var a = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        var b = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        var c = new Box2(new Vector2(-1, -1), new Vector2(0, 0));

        var aTranslated = a.clone().translate(new Vector2(1, 1));
        assertTrue(aTranslated.equals(new Box2(new Vector2(1, 1), new Vector2(1, 1))));

        aTranslated = a.clone().translate(new Vector2(1, 1)).translate(new Vector2(-1, -1));
        assertTrue(aTranslated.equals(a));

        cTranslated = c.clone().translate(new Vector2(1, 1));
        assertTrue(cTranslated.equals(b));

        bTranslated = b.clone().translate(new Vector2(-1, -1));
        assertTrue(bTranslated.equals(c));
    }

    public function testEquals() : Void {
        var a = new Box2();
        var b = new Box2();
        assertTrue(b.equals(a));
        assertTrue(a.equals(b));

        a = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        b = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        assertTrue(b.equals(a));
        assertTrue(a.equals(b));

        a = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        b = a.clone();
        assertTrue(b.equals(a));
        assertTrue(a.equals(b));

        a = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        b = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        assertFalse(b.equals(a));
        assertFalse(a.equals(b));

        a = new Box2();
        b = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        assertFalse(b.equals(a));
        assertFalse(a.equals(b));

        a = new Box2(new Vector2(0, 0), new Vector2(1, 1));
        b = new Box2(new Vector2(0, 0), new Vector2(0, 0));
        assertFalse(b.equals(a));
        assertFalse(a.equals(b));
    }
}

class TestRunner {
    public static function main() {
        var runner = new TestRunner();
        runner.add(new Box2Test());
        runner.run();
    }
}