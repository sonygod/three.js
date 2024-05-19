Here is the converted Haxe code:
```
package three.test.unit.math;

import three.math.Box2;
import three.math.Vector2;
import three.utils.MathConstants;

class Box2Tests {
    public function new() {}

    public function testBox2():Void {
        // INSTANCING
        assertEquals(new Box2().min, MathConstants.negInf2);
        assertEquals(new Box2().max, MathConstants.posInf2);

        var a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        assertEquals(a.min, Vector2.zero);
        assertEquals(a.max, Vector2.zero);

        a = new Box2(Vector2.zero.clone(), Vector2.one.clone());
        assertEquals(a.min, Vector2.zero);
        assertEquals(a.max, Vector2.one);

        // PUBLIC STUFF
        assertEquals(new Box2().isBox2, true);
        var b:Dynamic = {};
        assertEquals(b.isBox2, false);

        // set
        a = new Box2();
        a.set(Vector2.zero, Vector2.one);
        assertEquals(a.min, Vector2.zero);
        assertEquals(a.max, Vector2.one);

        // setFromPoints
        a = new Box2();
        a.setFromPoints([Vector2.zero, Vector2.one, Vector2.two]);
        assertEquals(a.min, Vector2.zero);
        assertEquals(a.max, Vector2.two);

        a.setFromPoints([Vector2.one]);
        assertEquals(a.min, Vector2.one);
        assertEquals(a.max, Vector2.one);

        a.setFromPoints([]);
        assertTrue(a.isEmpty());

        // setFromCenterAndSize
        a = new Box2();
        a.setFromCenterAndSize(Vector2.zero, Vector2.two);
        assertEquals(a.min, Vector2.negOne2);
        assertEquals(a.max, Vector2.one);

        a.setFromCenterAndSize(Vector2.one, Vector2.two);
        assertEquals(a.min, Vector2.zero);
        assertEquals(a.max, Vector2.two);

        a.setFromCenterAndSize(Vector2.zero, Vector2.zero);
        assertEquals(a.min, Vector2.zero);
        assertEquals(a.max, Vector2.zero);

        // clone
        a = new Box2(Vector2.zero, Vector2.zero);
        var b = a.clone();
        assertEquals(b.min, Vector2.zero);
        assertEquals(b.max, Vector2.zero);

        a = new Box2();
        b = a.clone();
        assertEquals(b.min, MathConstants.posInf2);
        assertEquals(b.max, MathConstants.negInf2);

        // copy
        a = new Box2(Vector2.zero.clone(), Vector2.one.clone());
        b = new Box2().copy(a);
        assertEquals(b.min, Vector2.zero);
        assertEquals(b.max, Vector2.one);

        a.min = Vector2.zero;
        a.max = Vector2.one;
        assertEquals(b.min, Vector2.zero);
        assertEquals(b.max, Vector2.one);

        // empty/makeEmpty
        a = new Box2();
        assertTrue(a.isEmpty());

        a = new Box2(Vector2.zero.clone(), Vector2.one.clone());
        assertFalse(a.isEmpty());

        a.makeEmpty();
        assertTrue(a.isEmpty());

        // isEmpty
        a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        assertFalse(a.isEmpty());

        a = new Box2(Vector2.zero.clone(), Vector2.one.clone());
        assertFalse(a.isEmpty());

        a = new Box2(Vector2.two.clone(), Vector2.one.clone());
        assertTrue(a.isEmpty());

        a = new Box2(MathConstants.posInf2.clone(), MathConstants.negInf2.clone());
        assertTrue(a.isEmpty());

        // getCenter
        a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        var center = new Vector2();
        assertEquals(a.getCenter(center), Vector2.zero);

        a = new Box2(Vector2.zero, Vector2.one);
        var midpoint = Vector2.one.clone().multiplyScalar(0.5);
        assertEquals(a.getCenter(center), midpoint);

        // getSize
        a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        var size = new Vector2();
        assertEquals(a.getSize(size), Vector2.zero);

        a = new Box2(Vector2.zero.clone(), Vector2.one.clone());
        assertEquals(a.getSize(size), Vector2.one);

        // expandByPoint
        a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        size = new Vector2();
        center = new Vector2();

        a.expandByPoint(Vector2.zero);
        assertEquals(a.getSize(size), Vector2.zero);

        a.expandByPoint(Vector2.one);
        assertEquals(a.getSize(size), Vector2.one);

        a.expandByPoint(Vector2.one.clone().negate());
        assertEquals(a.getSize(size), Vector2.one.clone().multiplyScalar(2));
        assertEquals(a.getCenter(center), Vector2.zero);

        // expandByVector
        a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        size = new Vector2();
        center = new Vector2();

        a.expandByVector(Vector2.zero);
        assertEquals(a.getSize(size), Vector2.zero);

        a.expandByVector(Vector2.one);
        assertEquals(a.getSize(size), Vector2.one.clone().multiplyScalar(2));
        assertEquals(a.getCenter(center), Vector2.zero);

        // expandByScalar
        a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        size = new Vector2();
        center = new Vector2();

        a.expandByScalar(0);
        assertEquals(a.getSize(size), Vector2.zero);

        a.expandByScalar(1);
        assertEquals(a.getSize(size), Vector2.one.clone().multiplyScalar(2));
        assertEquals(a.getCenter(center), Vector2.zero);

        // containsPoint
        a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        assertTrue(a.containsPoint(Vector2.zero));

        assertFalse(a.containsPoint(Vector2.one));

        a.expandByScalar(1);
        assertTrue(a.containsPoint(Vector2.zero));
        assertTrue(a.containsPoint(Vector2.one));
        assertTrue(a.containsPoint(Vector2.one.clone().negate()));

        // containsBox
        a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        var b = new Box2(Vector2.zero.clone(), Vector2.one.clone());
        var c = new Box2(Vector2.one.clone().negate(), Vector2.one.clone());

        assertTrue(a.containsBox(a));
        assertFalse(a.containsBox(b));
        assertFalse(a.containsBox(c));

        assertTrue(b.containsBox(a));
        assertTrue(c.containsBox(a));
        assertFalse(b.containsBox(c));

        // getParameter
        a = new Box2(Vector2.zero.clone(), Vector2.one.clone());
        b = new Box2(Vector2.one.clone().negate(), Vector2.one.clone());
        var parameter = new Vector2();

        a.getParameter(Vector2.zero, parameter);
        assertEquals(parameter, Vector2.zero);

        a.getParameter(Vector2.one, parameter);
        assertEquals(parameter, Vector2.one);

        b.getParameter(Vector2.one.clone().negate(), parameter);
        assertEquals(parameter, Vector2.zero);

        b.getParameter(Vector2.zero, parameter);
        assertEquals(parameter, new Vector2(0.5, 0.5));

        b.getParameter(Vector2.one, parameter);
        assertEquals(parameter, Vector2.one);

        // intersectsBox
        a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        b = new Box2(Vector2.zero.clone(), Vector2.one.clone());
        c = new Box2(Vector2.one.clone().negate(), Vector2.one.clone());

        assertTrue(a.intersectsBox(a));
        assertTrue(a.intersectsBox(b));
        assertTrue(a.intersectsBox(c));

        assertTrue(b.intersectsBox(a));
        assertTrue(c.intersectsBox(a));
        assertTrue(b.intersectsBox(c));

        b.translate(Vector2.two);
        assertFalse(a.intersectsBox(b));
        assertFalse(b.intersectsBox(a));
        assertFalse(b.intersectsBox(c));

        // clampPoint
        a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        b = new Box2(Vector2.one.clone().negate(), Vector2.one.clone());
        var point = new Vector2();

        a.clampPoint(Vector2.zero, point);
        assertEquals(point, new Vector2(0, 0));

        a.clampPoint(Vector2.one, point);
        assertEquals(point, new Vector2(0, 0));

        a.clampPoint(Vector2.one.clone().negate(), point);
        assertEquals(point, new Vector2(0, 0));

        b.clampPoint(Vector2.two, point);
        assertEquals(point, new Vector2(1, 1));

        b.clampPoint(Vector2.one, point);
        assertEquals(point, new Vector2(1, 1));

        b.clampPoint(Vector2.zero, point);
        assertEquals(point, new Vector2(0, 0));

        b.clampPoint(Vector2.one.clone().negate(), point);
        assertEquals(point, new Vector2(-1, -1));

        b.clampPoint(Vector2.two.clone().negate(), point);
        assertEquals(point, new Vector2(-1, -1));

        // distanceToPoint
        a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        b = new Box2(Vector2.one.clone().negate(), Vector2.one.clone());

        assertEquals(a.distanceToPoint(new Vector2(0, 0)), 0);

        assertEquals(a.distanceToPoint(new Vector2(1, 1)), Math.sqrt(2));

        assertEquals(a.distanceToPoint(new Vector2(-1, -1)), Math.sqrt(2));

        assertEquals(b.distanceToPoint(new Vector2(2, 2)), Math.sqrt(2));

        assertEquals(b.distanceToPoint(new Vector2(1, 1)), 0);

        assertEquals(b.distanceToPoint(new Vector2(0, 0)), 0);

        assertEquals(b.distanceToPoint(new Vector2(-1, -1)), 0);

        assertEquals(b.distanceToPoint(new Vector2(-2, -2)), Math.sqrt(2));

        // intersect
        a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        b = new Box2(Vector2.zero.clone(), Vector2.one.clone());
        c = new Box2(Vector2.one.clone().negate(), Vector2.one.clone());

        assertEquals(a.clone().intersect(a), a);
        assertEquals(a.clone().intersect(b), a);
        assertEquals(b.clone().intersect(b), b);
        assertEquals(a.clone().intersect(c), a);
        assertEquals(b.clone().intersect(c), b);
        assertEquals(c.clone().intersect(c), c);

        var d = new Box2(Vector2.one.clone().negate(), Vector2.zero.clone());
        var e = new Box2(Vector2.one.clone(), Vector2.two.clone()).intersect(d);

        assertEquals(e.min, MathConstants.posInf2);
        assertEquals(e.max, MathConstants.negInf2);

        // union
        a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        b = new Box2(Vector2.zero.clone(), Vector2.one.clone());
        c = new Box2(Vector2.one.clone().negate(), Vector2.one.clone());

        assertEquals(a.clone().union(a), a);
        assertEquals(a.clone().union(b), b);
        assertEquals(a.clone().union(c), c);
        assertEquals(b.clone().union(c), c);

        // translate
        a = new Box2(Vector2.zero.clone(), Vector2.zero.clone());
        b = new Box2(Vector2.zero.clone(), Vector2.one.clone());
        c = new Box2(Vector2.one.clone().negate(), Vector2.zero.clone());

        assertEquals(a.clone().translate(Vector2.one), new Box2(Vector2.one, Vector2.one));
        assertEquals(a.clone().translate(Vector2.one).translate(Vector2.one.clone().negate()), a);

        assertEquals(c.clone().translate(Vector2.one), b);
        assertEquals(b.clone().translate(Vector2.one.clone().negate()), c);

        // equals
        a = new Box2();
        b = new Box2();
        assertTrue(b.equals(a));
        assertTrue(a.equals(b));

        a = new Box2(Vector2.one, Vector2.two);
        b = new Box2(Vector2.one, Vector2.two);
        assertTrue(b.equals(a));
        assertTrue(a.equals(b));

        a = new Box2(Vector2.one, Vector2.two);
        b = a.clone();
        assertTrue(b.equals(a));
        assertTrue(a.equals(b));

        a = new Box2(Vector2.one, Vector2.two);
        b = new Box2(Vector2.one, Vector2.one);
        assertFalse(b.equals(a));
        assertFalse(a.equals(b));

        a = new Box2();
        b = new Box2(Vector2.one, Vector2.one);
        assertFalse(b.equals(a));
        assertFalse(a.equals(b));

        a = new Box2(Vector2.one, Vector2.two);
        b = new Box2(Vector2.one, Vector2.one);
        assertFalse(b.equals(a));
        assertFalse(a.equals(b));
    }
}
```
Note that I had to make some assumptions about the Haxe syntax and libraries, as I'm not familiar with them. Please review the code carefully to ensure it is correct.