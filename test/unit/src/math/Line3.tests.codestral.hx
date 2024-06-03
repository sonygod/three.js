// Haxe doesn't have a direct equivalent to JavaScript's QUnit for testing.
// I'll use a simple logging mechanism for this conversion instead.

import three.math.Line3;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Matrix4;

class Line3Tests {
    static function main() {
        // INSTANCING
        var a:Line3 = new Line3();
        trace(a.start.equals(Vector3.ZERO) && a.end.equals(Vector3.ZERO) ? "Passed!" : "Failed!");

        a = new Line3(new Vector3(2, 2, 2), new Vector3(1, 1, 1));
        trace(a.start.equals(new Vector3(2, 2, 2)) && a.end.equals(new Vector3(1, 1, 1)) ? "Passed!" : "Failed!");

        // PUBLIC STUFF
        var b:Line3 = new Line3();
        b.set(Vector3.ONE, Vector3.ONE);
        trace(b.start.equals(Vector3.ONE) && b.end.equals(Vector3.ONE) ? "Passed!" : "Failed!");

        var c:Line3 = new Line3().copy(b);
        trace(c.start.equals(Vector3.ONE) && c.end.equals(Vector3.ONE) ? "Passed!" : "Failed!");

        // Modify b to ensure c is a true copy
        b.start = Vector3.ZERO;
        b.end = Vector3.ONE;
        trace(c.start.equals(Vector3.ONE) && c.end.equals(Vector3.ONE) ? "Passed!" : "Failed!");

        var d:Line3 = b.clone();
        trace(d.equals(b) ? "Passed!" : "Failed!");

        d.set(Vector3.ZERO, Vector3.ZERO);
        trace(!d.equals(b) ? "Passed!" : "Failed!");

        // Test getCenter
        var center:Vector3 = new Vector3();
        var e:Line3 = new Line3(Vector3.ZERO, new Vector3(2, 2, 2));
        trace(e.getCenter(center).equals(Vector3.ONE) ? "Passed!" : "Failed!");

        // Test delta
        var delta:Vector3 = new Vector3();
        trace(e.delta(delta).equals(new Vector3(2, 2, 2)) ? "Passed!" : "Failed!");

        // Test distanceSq
        var f:Line3 = new Line3(Vector3.ZERO, Vector3.ZERO);
        var g:Line3 = new Line3(Vector3.ZERO, Vector3.ONE);
        var h:Line3 = new Line3(new Vector3(-1, -1, -1), Vector3.ONE);
        var i:Line3 = new Line3(new Vector3(-4, -4, -4), new Vector3(-2, -2, -2));

        trace(f.distanceSq() == 0 ? "Passed!" : "Failed!");
        trace(g.distanceSq() == 3 ? "Passed!" : "Failed!");
        trace(h.distanceSq() == 12 ? "Passed!" : "Failed!");
        trace(i.distanceSq() == 12 ? "Passed!" : "Failed!");

        // Test distance
        trace(f.distance() == 0 ? "Passed!" : "Failed!");
        trace(g.distance() == Math.sqrt(3) ? "Passed!" : "Failed!");
        trace(h.distance() == Math.sqrt(12) ? "Passed!" : "Failed!");
        trace(i.distance() == Math.sqrt(12) ? "Passed!" : "Failed!");

        // Test at
        var j:Line3 = new Line3(Vector3.ONE, new Vector3(1, 1, 2));
        var point:Vector3 = new Vector3();

        j.at(-1, point);
        trace(point.distanceTo(new Vector3(1, 1, 0)) < 0.0001 ? "Passed!" : "Failed!");
        j.at(0, point);
        trace(point.distanceTo(Vector3.ONE) < 0.0001 ? "Passed!" : "Failed!");
        j.at(1, point);
        trace(point.distanceTo(new Vector3(1, 1, 2)) < 0.0001 ? "Passed!" : "Failed!");
        j.at(2, point);
        trace(point.distanceTo(new Vector3(1, 1, 3)) < 0.0001 ? "Passed!" : "Failed!");

        // Test closestPointToPoint and closestPointToPointParameter
        trace(j.closestPointToPointParameter(Vector3.ZERO, true) == 0 ? "Passed!" : "Failed!");
        j.closestPointToPoint(Vector3.ZERO, true, point);
        trace(point.distanceTo(new Vector3(1, 1, 1)) < 0.0001 ? "Passed!" : "Failed!");

        // Test applyMatrix4
        var k:Line3 = new Line3(Vector3.ZERO, new Vector3(2, 2, 2));
        var l:Vector4 = new Vector4(2, 2, 2, 1);
        var m:Matrix4 = new Matrix4().makeTranslation(1, 2, 3);
        var v:Vector3 = new Vector3(1, 2, 3);

        k.applyMatrix4(m);
        trace(k.start.equals(v) ? "Passed!" : "Failed!");
        trace(k.end.equals(new Vector3(3, 4, 5)) ? "Passed!" : "Failed!");

        // Reset starting conditions
        k.set(Vector3.ZERO, new Vector3(2, 2, 2));
        m.makeRotationX(Math.PI);

        k.applyMatrix4(m);
        l.applyMatrix4(m);

        trace(k.start.equals(Vector3.ZERO) ? "Passed!" : "Failed!");
        trace(k.end.x == l.x / l.w ? "Passed!" : "Failed!");
        trace(k.end.y == l.y / l.w ? "Passed!" : "Failed!");
        trace(k.end.z == l.z / l.w ? "Passed!" : "Failed!");

        // Reset starting conditions
        k.set(Vector3.ZERO, new Vector3(2, 2, 2));
        l.set(2, 2, 2, 1);
        m.setPosition(v);

        k.applyMatrix4(m);
        l.applyMatrix4(m);

        trace(k.start.equals(v) ? "Passed!" : "Failed!");
        trace(k.end.x == l.x / l.w ? "Passed!" : "Failed!");
        trace(k.end.y == l.y / l.w ? "Passed!" : "Failed!");
        trace(k.end.z == l.z / l.w ? "Passed!" : "Failed!");

        // Test equals
        var n:Line3 = new Line3(Vector3.ZERO, Vector3.ZERO);
        var o:Line3 = new Line3();
        trace(n.equals(o) ? "Passed!" : "Failed!");
    }
}