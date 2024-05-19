import haxe.unit.TestRunner;
import three.math.Line3;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Matrix4;

class Line3Tests {
    public static function main() {
        var runner = new TestRunner();
        runner.addTestCase(new Line3Tests());
        runner.run();
    }

    public function new() {}

    public function testInstancing() {
        var a = new Line3();
        assertEquals(a.start, Vector3.zero3);
        assertEquals(a.end, Vector3.zero3);

        a = new Line3(two3.clone(), one3.clone());
        assertEquals(a.start, two3);
        assertEquals(a.end, one3);
    }

    public function testSet() {
        var a = new Line3();
        a.set(one3, one3);
        assertEquals(a.start, one3);
        assertEquals(a.end, one3);
    }

    public function testCopyEquals() {
        var a = new Line3(zero3.clone(), one3.clone());
        var b = new Line3().copy(a);
        assertEquals(b.start, zero3);
        assertEquals(b.end, one3);

        a.start = zero3;
        a.end = one3;
        assertEquals(b.start, zero3);
        assertEquals(b.end, one3);
    }

    public function testCloneEqual() {
        var a = new Line3();
        var b = new Line3(zero3, new Vector3(1, 1, 1));
        var c = new Line3(zero3, new Vector3(1, 1, 0));

        assertFalse(a.equals(b));
        assertFalse(a.equals(c));
        assertFalse(b.equals(c));

        a = b.clone();
        assertTrue(a.equals(b));
        assertFalse(a.equals(c));

        a.set(zero3, zero3);
        assertFalse(a.equals(b));
    }

    public function testGetCenter() {
        var center = new Vector3();
        var a = new Line3(zero3.clone(), two3.clone());
        assertEquals(a.getCenter(center), one3.clone());
    }

    public function testDelta() {
        var delta = new Vector3();
        var a = new Line3(zero3.clone(), two3.clone());
        assertEquals(a.delta(delta), two3.clone());
    }

    public function testDistanceSq() {
        var a = new Line3(zero3, zero3);
        var b = new Line3(zero3, one3);
        var c = new Line3(one3.clone().negate(), one3);
        var d = new Line3(two3.clone().multiplyScalar(-2), two3.clone().negate());

        assertEquals(a.distanceSq(), 0);
        assertEquals(b.distanceSq(), 3);
        assertEquals(c.distanceSq(), 12);
        assertEquals(d.distanceSq(), 12);
    }

    public function testDistance() {
        var a = new Line3(zero3, zero3);
        var b = new Line3(zero3, one3);
        var c = new Line3(one3.clone().negate(), one3);
        var d = new Line3(two3.clone().multiplyScalar(-2), two3.clone().negate());

        assertEquals(a.distance(), 0);
        assertEquals(b.distance(), Math.sqrt(3));
        assertEquals(c.distance(), Math.sqrt(12));
        assertEquals(d.distance(), Math.sqrt(12));
    }

    public function testAt() {
        var a = new Line3(one3.clone(), new Vector3(1, 1, 2));
        var point = new Vector3();

        a.at(-1, point);
        assertEquals(point.distanceTo(new Vector3(1, 1, 0)), 0.0001);
        a.at(0, point);
        assertEquals(point.distanceTo(one3.clone()), 0.0001);
        a.at(1, point);
        assertEquals(point.distanceTo(new Vector3(1, 1, 2)), 0.0001);
        a.at(2, point);
        assertEquals(point.distanceTo(new Vector3(1, 1, 3)), 0.0001);
    }

    public function testClosestPointToPoint() {
        var a = new Line3(one3.clone(), new Vector3(1, 1, 2));
        var point = new Vector3();

        assertEquals(a.closestPointToPointParameter(zero3.clone(), true), 0);
        a.closestPointToPoint(zero3.clone(), true, point);
        assertEquals(point.distanceTo(new Vector3(1, 1, 1)), 0.0001);

        assertEquals(a.closestPointToPointParameter(zero3.clone(), false), -1);
        a.closestPointToPoint(zero3.clone(), false, point);
        assertEquals(point.distanceTo(new Vector3(1, 1, 0)), 0.0001);

        assertEquals(a.closestPointToPointParameter(new Vector3(1, 1, 5), true), 1);
        a.closestPointToPoint(new Vector3(1, 1, 5), true, point);
        assertEquals(point.distanceTo(new Vector3(1, 1, 2)), 0.0001);

        assertEquals(a.closestPointToPointParameter(one3.clone(), true), 0);
        a.closestPointToPoint(one3.clone(), true, point);
        assertEquals(point.distanceTo(one3.clone()), 0.0001);
    }

    public function testApplyMatrix4() {
        var a = new Line3(zero3.clone(), two3.clone());
        var b = new Vector4(two3.x, two3.y, two3.z, 1);
        var m = new Matrix4().makeTranslation(x, y, z);
        var v = new Vector3(x, y, z);

        a.applyMatrix4(m);
        assertEquals(a.start, v);
        assertEquals(a.end, new Vector3(2 + x, 2 + y, 2 + z));

        a.set(zero3.clone(), two3.clone());
        m.makeRotationX(Math.PI);

        a.applyMatrix4(m);
        b.applyMatrix4(m);

        assertEquals(a.start, zero3);
        assertEquals(a.end.x, b.x / b.w);
        assertEquals(a.end.y, b.y / b.w);
        assertEquals(a.end.z, b.z / b.w);

        a.set(zero3.clone(), two3.clone());
        b.set(two3.x, two3.y, two3.z, 1);
        m.setPosition(v);

        a.applyMatrix4(m);
        b.applyMatrix4(m);

        assertEquals(a.start, v);
        assertEquals(a.end.x, b.x / b.w);
        assertEquals(a.end.y, b.y / b.w);
        assertEquals(a.end.z, b.z / b.w);
    }

    public function testEquals() {
        var a = new Line3(zero3.clone(), zero3.clone());
        var b = new Line3();
        assertTrue(a.equals(b));
    }
}