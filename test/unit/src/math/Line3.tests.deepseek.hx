package;

import three.math.Line3;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Matrix4;
import three.utils.math_constants;

class Line3Tests {

    static function main() {
        // INSTANCING
        var a = new Line3();
        trace(a.start.equals(math_constants.zero3), 'Passed!');
        trace(a.end.equals(math_constants.zero3), 'Passed!');

        a = new Line3(math_constants.two3.clone(), math_constants.one3.clone());
        trace(a.start.equals(math_constants.two3), 'Passed!');
        trace(a.end.equals(math_constants.one3), 'Passed!');

        // PUBLIC STUFF
        var b = new Line3();
        b.set(math_constants.one3, math_constants.one3);
        trace(b.start.equals(math_constants.one3), 'Passed!');
        trace(b.end.equals(math_constants.one3), 'Passed!');

        var c = new Line3(math_constants.zero3.clone(), new Vector3(1, 1, 1));
        var d = new Line3(math_constants.zero3.clone(), new Vector3(1, 1, 0));
        trace(!a.equals(b), 'Check a and b aren\'t equal');
        trace(!a.equals(c), 'Check a and c aren\'t equal');
        trace(!b.equals(c), 'Check b and c aren\'t equal');

        a = b.clone();
        trace(a.equals(b), 'Check a and b are equal after clone()');
        trace(!a.equals(c), 'Check a and c aren\'t equal after clone()');

        a.set(math_constants.zero3, math_constants.zero3);
        trace(!a.equals(b), 'Check a and b are not equal after modification');

        var center = new Vector3();
        a = new Line3(math_constants.zero3.clone(), math_constants.two3.clone());
        trace(a.getCenter(center).equals(math_constants.one3.clone()), 'Passed');

        var delta = new Vector3();
        trace(a.delta(delta).equals(math_constants.two3.clone()), 'Passed');

        trace(a.distanceSq() == 0, 'Check squared distance for zero-length line');
        a = new Line3(math_constants.zero3, math_constants.one3);
        trace(a.distanceSq() == 3, 'Check squared distance for simple line');
        a = new Line3(math_constants.one3.clone().negate(), math_constants.one3);
        trace(a.distanceSq() == 12, 'Check squared distance for negative to positive endpoints');
        a = new Line3(math_constants.two3.clone().multiplyScalar(-2), math_constants.two3.clone().negate());
        trace(a.distanceSq() == 12, 'Check squared distance for negative to negative endpoints');

        trace(a.distance() == 0, 'Check distance for zero-length line');
        a = new Line3(math_constants.zero3, math_constants.one3);
        trace(a.distance() == Math.sqrt(3), 'Check distance for simple line');
        a = new Line3(math_constants.one3.clone().negate(), math_constants.one3);
        trace(a.distance() == Math.sqrt(12), 'Check distance for negative to positive endpoints');
        a = new Line3(math_constants.two3.clone().multiplyScalar(-2), math_constants.two3.clone().negate());
        trace(a.distance() == Math.sqrt(12), 'Check distance for negative to negative endpoints');

        var point = new Vector3();
        a = new Line3(math_constants.one3.clone(), new Vector3(1, 1, 2));
        a.at(-1, point);
        trace(point.distanceTo(new Vector3(1, 1, 0)) < 0.0001, 'Passed!');
        a.at(0, point);
        trace(point.distanceTo(math_constants.one3.clone()) < 0.0001, 'Passed!');
        a.at(1, point);
        trace(point.distanceTo(new Vector3(1, 1, 2)) < 0.0001, 'Passed!');
        a.at(2, point);
        trace(point.distanceTo(new Vector3(1, 1, 3)) < 0.0001, 'Passed!');

        a = new Line3(math_constants.one3.clone(), new Vector3(1, 1, 2));
        trace(a.closestPointToPointParameter(math_constants.zero3.clone(), true) == 0, 'Passed!');
        a.closestPointToPoint(math_constants.zero3.clone(), true, point);
        trace(point.distanceTo(new Vector3(1, 1, 1)) < 0.0001, 'Passed!');
        trace(a.closestPointToPointParameter(math_constants.zero3.clone(), false) == -1, 'Passed!');
        a.closestPointToPoint(math_constants.zero3.clone(), false, point);
        trace(point.distanceTo(new Vector3(1, 1, 0)) < 0.0001, 'Passed!');
        trace(a.closestPointToPointParameter(new Vector3(1, 1, 5), true) == 1, 'Passed!');
        a.closestPointToPoint(new Vector3(1, 1, 5), true, point);
        trace(point.distanceTo(new Vector3(1, 1, 2)) < 0.0001, 'Passed!');
        trace(a.closestPointToPointParameter(math_constants.one3.clone(), true) == 0, 'Passed!');
        a.closestPointToPoint(math_constants.one3.clone(), true, point);
        trace(point.distanceTo(math_constants.one3.clone()) < 0.0001, 'Passed!');

        a = new Line3(math_constants.zero3.clone(), math_constants.two3.clone());
        var b = new Vector4(math_constants.two3.x, math_constants.two3.y, math_constants.two3.z, 1);
        var m = new Matrix4().makeTranslation(math_constants.x, math_constants.y, math_constants.z);
        var v = new Vector3(math_constants.x, math_constants.y, math_constants.z);
        a.applyMatrix4(m);
        trace(a.start.equals(v), 'Translation: check start');
        trace(a.end.equals(new Vector3(2 + math_constants.x, 2 + math_constants.y, 2 + math_constants.z)), 'Translation: check start');
        a.set(math_constants.zero3.clone(), math_constants.two3.clone());
        m.makeRotationX(Math.PI);
        a.applyMatrix4(m);
        b.applyMatrix4(m);
        trace(a.start.equals(math_constants.zero3), 'Rotation: check start');
        trace(a.end.x == b.x / b.w, 'Rotation: check end.x');
        trace(a.end.y == b.y / b.w, 'Rotation: check end.y');
        trace(a.end.z == b.z / b.w, 'Rotation: check end.z');
        a.set(math_constants.zero3.clone(), math_constants.two3.clone());
        b.set(math_constants.two3.x, math_constants.two3.y, math_constants.two3.z, 1);
        m.setPosition(v);
        a.applyMatrix4(m);
        b.applyMatrix4(m);
        trace(a.start.equals(v), 'Both: check start');
        trace(a.end.x == b.x / b.w, 'Both: check end.x');
        trace(a.end.y == b.y / b.w, 'Both: check end.y');
        trace(a.end.z == b.z / b.w, 'Both: check end.z');

        a = new Line3(math_constants.zero3.clone(), math_constants.zero3.clone());
        b = new Line3();
        trace(a.equals(b), 'Passed');
    }
}