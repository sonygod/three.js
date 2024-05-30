import js.QUnit;
import js.Math.Line3;
import js.Math.Vector3;
import js.Math.Vector4;
import js.Math.Matrix4;

class MathConstants {
    static var x:Float;
    static var y:Float;
    static var z:Float;
    static var zero3:Vector3;
    static var one3:Vector3;
    static var two3:Vector3;
}

class Test {
    static public function main() {
        QUnit.module('Maths', function() {
            QUnit.module('Line3', function() {
                // INSTANCING
                QUnit.test('Instancing', function() {
                    var a = new Line3();
                    QUnit.ok(a.start.equals(MathConstants.zero3), 'Passed!');
                    QUnit.ok(a.end.equals(MathConstants.zero3), 'Passed!');

                    a = new Line3(MathConstants.two3.clone(), MathConstants.one3.clone());
                    QUnit.ok(a.start.equals(MathConstants.two3), 'Passed!');
                    QUnit.ok(a.end.equals(MathConstants.one3), 'Passed!');
                });

                // PUBLIC STUFF
                QUnit.test('set', function() {
                    var a = new Line3();

                    a.set(MathConstants.one3, MathConstants.one3);
                    QUnit.ok(a.start.equals(MathConstants.one3), 'Passed!');
                    QUnit.ok(a.end.equals(MathConstants.one3), 'Passed!');
                });

                QUnit.test('copy/equals', function() {
                    var a = new Line3(MathConstants.zero3.clone(), MathConstants.one3.clone());
                    var b = new Line3().copy(a);
                    QUnit.ok(b.start.equals(MathConstants.zero3), 'Passed!');
                    QUnit.ok(b.end.equals(MathConstants.one3), 'Passed!');

                    // ensure that it is a true copy
                    a.start = MathConstants.zero3;
                    a.end = MathConstants.one3;
                    QUnit.ok(b.start.equals(MathConstants.zero3), 'Passed!');
                    QUnit.ok(b.end.equals(MathConstants.one3), 'Passed!');
                });

                QUnit.test('clone/equal', function() {
                    var a = new Line3();
                    var b = new Line3(MathConstants.zero3, new Vector3(1, 1, 1));
                    var c = new Line3(MathConstants.zero3, new Vector3(1, 1, 0));

                    QUnit.notOk(a.equals(b), 'Check a and b aren\'t equal');
                    QUnit.notOk(a.equals(c), 'Check a and c aren\'t equal');
                    QUnit.notOk(b.equals(c), 'Check b and c aren\'t equal');

                    a = b.clone();
                    QUnit.ok(a.equals(b), 'Check a and b are equal after clone()');
                    QUnit.notOk(a.equals(c), 'Check a and c aren\'t equal after clone()');

                    a.set(MathConstants.zero3, MathConstants.zero3);
                    QUnit.notOk(a.equals(b), 'Check a and b are not equal after modification');
                });

                QUnit.test('getCenter', function() {
                    var center = new Vector3();

                    var a = new Line3(MathConstants.zero3.clone(), MathConstants.two3.clone());
                    QUnit.ok(a.getCenter(center).equals(MathConstants.one3.clone()), 'Passed');
                });

                QUnit.test('delta', function() {
                    var delta = new Vector3();

                    var a = new Line3(MathConstants.zero3.clone(), MathConstants.two3.clone());
                    QUnit.ok(a.delta(delta).equals(MathConstants.two3.clone()), 'Passed');
                });

                QUnit.test('distanceSq', function() {
                    var a = new Line3(MathConstants.zero3, MathConstants.zero3);
                    var b = new Line3(MathConstants.zero3, MathConstants.one3);
                    var c = new Line3(MathConstants.one3.clone().negate(), MathConstants.one3);
                    var d = new Line3(MathConstants.two3.clone().multiplyScalar(-2), MathConstants.two3.clone().negate());

                    QUnit.numEqual(a.distanceSq(), 0, 'Check squared distance for zero-length line');
                    QUnit.numEqual(b.distanceSq(), 3, 'Check squared distance for simple line');
                    QUnit.numEqual(c.distanceSq(), 12, 'Check squared distance for negative to positive endpoints');
                    QUnit.numEqual(d.distanceSq(), 12, 'Check squared distance for negative to negative endpoints');
                });

                QUnit.test('distance', function() {
                    var a = new Line3(MathConstants.zero3, MathConstants.zero3);
                    var b = new Line3(MathConstants.zero3, MathConstants.one3);
                    var c = new Line3(MathConstants.one3.clone().negate(), MathConstants.one3);
                    var d = new Line3(MathConstants.two3.clone().multiplyScalar(-2), MathConstants.two3.clone().negate());

                    QUnit.numEqual(a.distance(), 0, 'Check distance for zero-length line');
                    QUnit.numEqual(b.distance(), Std.sqrt(3), 'Check distance for simple line');
                    QUnit.numEqual(c.distance(), Std.sqrt(12), 'Check distance for negative to positive endpoints');
                    QUnit.numEqual(d.distance(), Std.sqrt(12), 'Check distance for negative to negative endpoints');
                });

                QUnit.test('at', function() {
                    var a = new Line3(MathConstants.one3.clone(), new Vector3(1, 1, 2));
                    var point = new Vector3();

                    a.at(-1, point);
                    QUnit.ok(point.distanceTo(new Vector3(1, 1, 0)) < 0.0001, 'Passed!');
                    a.at(0, point);
                    QUnit.ok(point.distanceTo(MathConstants.one3.clone()) < 0.0001, 'Passed!');
                    a.at(1, point);
                    QUnit.ok(point.distanceTo(new Vector3(1, 1, 2)) < 0.0001, 'Passed!');
                    a.at(2, point);
                    QUnit.ok(point.distanceTo(new Vector3(1, 1, 3)) < 0.0001, 'Passed!');
                });

                QUnit.test('closestPointToPoint/closestPointToPointParameter', function() {
                    var a = new Line3(MathConstants.one3.clone(), new Vector3(1, 1, 2));
                    var point = new Vector3();

                    // nearby the ray
                    QUnit.ok(a.closestPointToPointParameter(MathConstants.zero3.clone(), true) == 0, 'Passed!');
                    a.closestPointToPoint(MathConstants.zero3.clone(), true, point);
                    QUnit.ok(point.distanceTo(new Vector3(1, 1, 1)) < 0.0001, 'Passed!');

                    // nearby the ray
                    QUnit.ok(a.closestPointToPointParameter(MathConstants.zero3.clone(), false) == -1, 'Passed!');
                    a.closestPointToPoint(MathConstants.zero3.clone(), false, point);
                    QUnit.ok(point.distanceTo(new Vector3(1, 1, 0)) < 0.0001, 'Passed!');

                    // nearby the ray
                    QUnit.ok(a.closestPointToPointParameter(new Vector3(1, 1, 5), true) == 1, 'Passed!');
                    a.closestPointToPoint(new Vector3(1, 1, 5), true, point);
                    QUnit.ok(point.distanceTo(new Vector3(1, 1, 2)) < 0.0001, 'Passed!');

                    // exactly on the ray
                    QUnit.ok(a.closestPointToPointParameter(MathConstants.one3.clone(), true) == 0, 'Passed!');
                    a.closestPointToPoint(MathConstants.one3.clone(), true, point);
                    QUnit.ok(point.distanceTo(MathConstants.one3.clone()) < 0.0001, 'Passed!');
                });

                QUnit.test('applyMatrix4', function() {
                    var a = new Line3(MathConstants.zero3.clone(), MathConstants.two3.clone());
                    var b = new Vector4(MathConstants.two3.x, MathConstants.two3.y, MathConstants.two3.z, 1);
                    var m = new Matrix4().makeTranslation(MathConstants.x, MathConstants.y, MathConstants.z);
                    var v = new Vector3(MathConstants.x, MathConstants.y, MathConstants.z);

                    a.applyMatrix4(m);
                    QUnit.ok(a.start.equals(v), 'Translation: check start');
                    QUnit.ok(a.end.equals(new Vector3(2 + MathConstants.x, 2 + MathConstants.y, 2 + MathConstants.z)), 'Translation: check start');

                    // reset starting conditions
                    a.set(MathConstants.zero3.clone(), MathConstants.two3.clone());
                    m.makeRotationX(Math.PI);

                    a.applyMatrix4(m);
                    b.applyMatrix4(m);

                    QUnit.ok(a.start.equals(MathConstants.zero3), 'Rotation: check start');
                    QUnit.numEqual(a.end.x, b.x / b.w, 'Rotation: check end.x');
                    QUnit.numEqual(a.end.y, b.y / b.w, 'Rotation: check end.y');
                    QUnit.numEqual(a.end.z, b.z / b.w, 'Rotation: check end.z');

                    // reset starting conditions
                    a.set(MathConstants.zero3.clone(), MathConstants.two3.clone());
                    b.set(MathConstants.two3.x, MathConstants.two3.y, MathConstants.two3.z, 1);
                    m.setPosition(v);

                    a.applyMatrix4(m);
                    b.applyMatrix4(m);

                    QUnit.ok(a.start.equals(v), 'Both: check start');
                    QUnit.numEqual(a.end.x, b.x / b.w, 'Both: check end.x');
                    QUnit.numEqual(a.end.y, b.y / b.w, 'Both: check end.y');
                    QUnit.numEqual(a.end.z, b.z / b.w, 'Both: check end.z');
                });

                QUnit.test('equals', function() {
                    var a = new Line3(MathConstants.zero3.clone(), MathConstants.zero3.clone());
                    var b = new Line3();
                    QUnit.ok(a.equals(b), 'Passed');
                });
            });
        });
    }
}