Here is the converted Haxe code:
```
package three.math;

import three.math.Plane;
import three.math.Vector3;
import three.math.Line3;
import three.math.Sphere;
import three.math.Box3;
import three.math.Matrix4;

using three.utils.MathConstants;

class PlaneTests {
    public function new() {}

    static function comparePlane(a:Plane, b:Plane, threshold:Float = 0.0001):Bool {
        return (a.normal.distanceTo(b.normal) < threshold && Math.abs(a.constant - b.constant) < threshold);
    }

    public static function runTests():Void {
        QUnit.module("Maths", () => {
            QUnit.module("Plane", () => {
                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var a:Plane = new Plane();
                    assert.ok(a.normal.x == 1, 'Passed!');
                    assert.ok(a.normal.y == 0, 'Passed!');
                    assert.ok(a.normal.z == 0, 'Passed!');
                    assert.ok(a.constant == 0, 'Passed!');

                    a = new Plane(one3.clone(), 0);
                    assert.ok(a.normal.x == 1, 'Passed!');
                    assert.ok(a.normal.y == 1, 'Passed!');
                    assert.ok(a.normal.z == 1, 'Passed!');
                    assert.ok(a.constant == 0, 'Passed!');

                    a = new Plane(one3.clone(), 1);
                    assert.ok(a.normal.x == 1, 'Passed!');
                    assert.ok(a.normal.y == 1, 'Passed!');
                    assert.ok(a.normal.z == 1, 'Passed!');
                    assert.ok(a.constant == 1, 'Passed!');
                });

                // PUBLIC STUFF
                QUnit.test("isPlane", (assert) => {
                    var a:Plane = new Plane();
                    assert.ok(a.isPlane === true, 'Passed!');

                    var b:Vector3 = new Vector3();
                    assert.ok(!b.isPlane, 'Passed!');
                });

                QUnit.test("set", (assert) => {
                    var a:Plane = new Plane();
                    assert.ok(a.normal.x == 1, 'Passed!');
                    assert.ok(a.normal.y == 0, 'Passed!');
                    assert.ok(a.normal.z == 0, 'Passed!');
                    assert.ok(a.constant == 0, 'Passed!');

                    var b:Plane = a.clone().set(new Vector3(x, y, z), w);
                    assert.ok(b.normal.x == x, 'Passed!');
                    assert.ok(b.normal.y == y, 'Passed!');
                    assert.ok(b.normal.z == z, 'Passed!');
                    assert.ok(b.constant == w, 'Passed!');
                });

                QUnit.test("setComponents", (assert) => {
                    var a:Plane = new Plane();
                    assert.ok(a.normal.x == 1, 'Passed!');
                    assert.ok(a.normal.y == 0, 'Passed!');
                    assert.ok(a.normal.z == 0, 'Passed!');
                    assert.ok(a.constant == 0, 'Passed!');

                    var b:Plane = a.clone().setComponents(x, y, z, w);
                    assert.ok(b.normal.x == x, 'Passed!');
                    assert.ok(b.normal.y == y, 'Passed!');
                    assert.ok(b.normal.z == z, 'Passed!');
                    assert.ok(b.constant == w, 'Passed!');
                });

                QUnit.test("setFromNormalAndCoplanarPoint", (assert) => {
                    var normal:Vector3 = one3.clone().normalize();
                    var a:Plane = new Plane().setFromNormalAndCoplanarPoint(normal, zero3);

                    assert.ok(a.normal.equals(normal), 'Passed!');
                    assert.ok(a.constant == 0, 'Passed!');
                });

                QUnit.test("setFromCoplanarPoints", (assert) => {
                    var a:Plane = new Plane();
                    var v1:Vector3 = new Vector3(2.0, 0.5, 0.25);
                    var v2:Vector3 = new Vector3(2.0, -0.5, 1.25);
                    var v3:Vector3 = new Vector3(2.0, -3.5, 2.2);
                    var normal:Vector3 = new Vector3(1, 0, 0);
                    var constant:Float = -2;

                    a.setFromCoplanarPoints(v1, v2, v3);

                    assert.ok(a.normal.equals(normal), 'Check normal');
                    assert.strictEqual(a.constant, constant, 'Check constant');
                });

                QUnit.test("clone", (assert) => {
                    var a:Plane = new Plane(new Vector3(2.0, 0.5, 0.25));
                    var b:Plane = a.clone();

                    assert.ok(a.equals(b), 'clones are equal');
                });

                QUnit.test("copy", (assert) => {
                    var a:Plane = new Plane(new Vector3(x, y, z), w);
                    var b:Plane = new Plane().copy(a);
                    assert.ok(b.normal.x == x, 'Passed!');
                    assert.ok(b.normal.y == y, 'Passed!');
                    assert.ok(b.normal.z == z, 'Passed!');
                    assert.ok(b.constant == w, 'Passed!');

                    // ensure that it is a true copy
                    a.normal.x = 0;
                    a.normal.y = -1;
                    a.normal.z = -2;
                    a.constant = -3;
                    assert.ok(b.normal.x == x, 'Passed!');
                    assert.ok(b.normal.y == y, 'Passed!');
                    assert.ok(b.normal.z == z, 'Passed!');
                    assert.ok(b.constant == w, 'Passed!');
                });

                QUnit.test("normalize", (assert) => {
                    var a:Plane = new Plane(new Vector3(2, 0, 0), 2);

                    a.normalize();
                    assert.ok(a.normal.length() == 1, 'Passed!');
                    assert.ok(a.normal.equals(new Vector3(1, 0, 0)), 'Passed!');
                    assert.ok(a.constant == 1, 'Passed!');
                });

                QUnit.test("negate/distanceToPoint", (assert) => {
                    var a:Plane = new Plane(new Vector3(2, 0, 0), -2);

                    a.normalize();
                    assert.ok(a.distanceToPoint(new Vector3(4, 0, 0)) === 3, 'Passed!');
                    assert.ok(a.distanceToPoint(new Vector3(1, 0, 0)) === 0, 'Passed!');

                    a.negate();
                    assert.ok(a.distanceToPoint(new Vector3(4, 0, 0)) === -3, 'Passed!');
                    assert.ok(a.distanceToPoint(new Vector3(1, 0, 0)) === 0, 'Passed!');
                });

                QUnit.test("distanceToPoint", (assert) => {
                    var a:Plane = new Plane(new Vector3(2, 0, 0), -2);
                    var point:Vector3 = new Vector3();

                    a.normalize().projectPoint(zero3.clone(), point);
                    assert.ok(a.distanceToPoint(point) === 0, 'Passed!');
                    assert.ok(a.distanceToPoint(new Vector3(4, 0, 0)) === 3, 'Passed!');
                });

                QUnit.test("distanceToSphere", (assert) => {
                    var a:Plane = new Plane(new Vector3(1, 0, 0), 0);

                    var b:Sphere = new Sphere(new Vector3(2, 0, 0), 1);

                    assert.ok(a.distanceToSphere(b) === 1, 'Passed!');

                    a.set(new Vector3(1, 0, 0), 2);
                    assert.ok(a.distanceToSphere(b) === 3, 'Passed!');
                    a.set(new Vector3(1, 0, 0), -2);
                    assert.ok(a.distanceToSphere(b) === -1, 'Passed!');
                });

                QUnit.test("projectPoint", (assert) => {
                    var a:Plane = new Plane(new Vector3(1, 0, 0), 0);
                    var point:Vector3 = new Vector3();

                    a.projectPoint(new Vector3(10, 0, 0), point);
                    assert.ok(point.equals(zero3), 'Passed!');
                    a.projectPoint(new Vector3(-10, 0, 0), point);
                    assert.ok(point.equals(zero3), 'Passed!');

                    a = new Plane(new Vector3(0, 1, 0), -1);
                    a.projectPoint(new Vector3(0, 0, 0), point);
                    assert.ok(point.equals(new Vector3(0, 1, 0)), 'Passed!');
                    a.projectPoint(new Vector3(0, 1, 0), point);
                    assert.ok(point.equals(new Vector3(0, 1, 0)), 'Passed!');
                });

                QUnit.test("intersectLine", (assert) => {
                    var a:Plane = new Plane(new Vector3(1, 0, 0), 0);
                    var point:Vector3 = new Vector3();

                    var l1:Line3 = new Line3(new Vector3(-10, 0, 0), new Vector3(10, 0, 0));
                    a.intersectLine(l1, point);
                    assert.ok(point.equals(new Vector3(0, 0, 0)), 'Passed!');

                    a = new Plane(new Vector3(1, 0, 0), -3);
                    a.intersectLine(l1, point);
                    assert.ok(point.equals(new Vector3(3, 0, 0)), 'Passed!');
                });

                QUnit.todo("intersectsLine", (assert) => {
                    // intersectsLine( line ) // - boolean variant of above
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test("intersectsBox", (assert) => {
                    var a:Box3 = new Box3(zero3.clone(), one3.clone());
                    var b:Plane = new Plane(new Vector3(0, 1, 0), 1);
                    var c:Plane = new Plane(new Vector3(0, 1, 0), 1.25);
                    var d:Plane = new Plane(new Vector3(0, -1, 0), 1.25);
                    var e:Plane = new Plane(new Vector3(0, 1, 0), 0.25);
                    var f:Plane = new Plane(new Vector3(0, 1, 0), -0.25);
                    var g:Plane = new Plane(new Vector3(0, 1, 0), -0.75);
                    var h:Plane = new Plane(new Vector3(0, 1, 0), -1);
                    var i:Plane = new Plane(new Vector3(1, 1, 1).normalize(), -1.732);
                    var j:Plane = new Plane(new Vector3(1, 1, 1).normalize(), -1.733);

                    assert.ok(!b.intersectsBox(a), 'Passed!');
                    assert.ok(!c.intersectsBox(a), 'Passed!');
                    assert.ok(!d.intersectsBox(a), 'Passed!');
                    assert.ok(!e.intersectsBox(a), 'Passed!');
                    assert.ok(f.intersectsBox(a), 'Passed!');
                    assert.ok(g.intersectsBox(a), 'Passed!');
                    assert.ok(h.intersectsBox(a), 'Passed!');
                    assert.ok(i.intersectsBox(a), 'Passed!');
                    assert.ok(!j.intersectsBox(a), 'Passed!');
                });

                QUnit.test("intersectsSphere", (assert) => {
                    var a:Sphere = new Sphere(zero3.clone(), 1);
                    var b:Plane = new Plane(new Vector3(0, 1, 0), 1);
                    var c:Plane = new Plane(new Vector3(0, 1, 0), 1.25);
                    var d:Plane = new Plane(new Vector3(0, -1, 0), 1.25);

                    assert.ok(b.intersectsSphere(a), 'Passed!');
                    assert.ok(!c.intersectsSphere(a), 'Passed!');
                    assert.ok(!d.intersectsSphere(a), 'Passed!');
                });

                QUnit.test("coplanarPoint", (assert) => {
                    var point:Vector3 = new Vector3();

                    var a:Plane = new Plane(new Vector3(1, 0, 0), 0);
                    a.coplanarPoint(point);
                    assert.ok(a.distanceToPoint(point) === 0, 'Passed!');

                    a = new Plane(new Vector3(0, 1, 0), -1);
                    a.coplanarPoint(point);
                    assert.ok(a.distanceToPoint(point) === 0, 'Passed!');
                });

                QUnit.test("applyMatrix4/translate", (assert) => {
                    var a:Plane = new Plane(new Vector3(1, 0, 0), 0);

                    var m:Matrix4 = new Matrix4();
                    m.makeRotationZ(Math.PI * 0.5);

                    assert.ok(comparePlane(a.clone().applyMatrix4(m), new Plane(new Vector3(0, 1, 0), 0)), 'Passed!');

                    a = new Plane(new Vector3(0, 1, 0), -1);
                    assert.ok(comparePlane(a.clone().applyMatrix4(m), new Plane(new Vector3(-1, 0, 0), -1)), 'Passed!');

                    m.makeTranslation(1, 1, 1);
                    assert.ok(comparePlane(a.clone().applyMatrix4(m), a.clone().translate(new Vector3(1, 1, 1))), 'Passed!');
                });

                QUnit.test("equals", (assert) => {
                    var a:Plane = new Plane(new Vector3(1, 0, 0), 0);
                    var b:Plane = new Plane(new Vector3(1, 0, 0), 1);
                    var c:Plane = new Plane(new Vector3(0, 1, 0), 0);

                    assert.ok(a.normal.equals(b.normal), 'Normals: equal');
                    assert.ok(!a.normal.equals(c.normal), 'Normals: not equal');

                    assert.ok(a.constant != b.constant, 'Constants: not equal');
                    assert.ok(a.constant == c.constant, 'Constants: equal');

                    assert.ok(!a.equals(b), 'Planes: not equal');
                    assert.ok(!a.equals(c), 'Planes: not equal');

                    a.copy(b);
                    assert.ok(a.normal.equals(b.normal), 'Normals after copy(): equal');
                    assert.ok(a.constant == b.constant, 'Constants after copy(): equal');
                    assert.ok(a.equals(b), 'Planes after copy(): equal');
                });
            });
        });
    }
}
```
Note that I've kept the same file structure and naming conventions as the original JavaScript code. I've also kept the same variable names and function names to make the transition easier.