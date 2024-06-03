import js.QUnit;
// import js.three.core.BufferAttribute;
import js.three.math.Triangle;
import js.three.math.Box3;
import js.three.math.Plane;
import js.three.math.Vector3;
import js.three.math.MathConstants;

@:js("default") class TriangleTests {
  public static function main() {
    QUnit.module("Maths", () -> {
      QUnit.module("Triangle", () -> {

        QUnit.test("Instancing", (assert) -> {
          let a = new Triangle();
          assert.ok(a.a.equals(MathConstants.zero3), 'Passed!');
          assert.ok(a.b.equals(MathConstants.zero3), 'Passed!');
          assert.ok(a.c.equals(MathConstants.zero3), 'Passed!');

          a = new Triangle(MathConstants.one3.clone().negate(), MathConstants.one3.clone(), MathConstants.two3.clone());
          assert.ok(a.a.equals(MathConstants.one3.clone().negate()), 'Passed!');
          assert.ok(a.b.equals(MathConstants.one3), 'Passed!');
          assert.ok(a.c.equals(MathConstants.two3), 'Passed!');
        });

        QUnit.test("set", (assert) -> {
          let a = new Triangle();

          a.set(MathConstants.one3.clone().negate(), MathConstants.one3, MathConstants.two3);
          assert.ok(a.a.equals(MathConstants.one3.clone().negate()), 'Passed!');
          assert.ok(a.b.equals(MathConstants.one3), 'Passed!');
          assert.ok(a.c.equals(MathConstants.two3), 'Passed!');
        });

        QUnit.test("setFromPointsAndIndices", (assert) -> {
          let a = new Triangle();

          let points = [MathConstants.one3, MathConstants.one3.clone().negate(), MathConstants.two3];
          a.setFromPointsAndIndices(points, 1, 0, 2);
          assert.ok(a.a.equals(MathConstants.one3.clone().negate()), 'Passed!');
          assert.ok(a.b.equals(MathConstants.one3), 'Passed!');
          assert.ok(a.c.equals(MathConstants.two3), 'Passed!');
        });

        // QUnit.test("setFromAttributeAndIndices", (assert) -> {
        //   let a = new Triangle();
        //   let attribute = new BufferAttribute(new Float32Array([1, 1, 1, -1, -1, -1, 2, 2, 2]), 3);

        //   a.setFromAttributeAndIndices(attribute, 1, 0, 2);
        //   assert.ok(a.a.equals(MathConstants.one3.clone().negate()), 'Passed!');
        //   assert.ok(a.b.equals(MathConstants.one3), 'Passed!');
        //   assert.ok(a.c.equals(MathConstants.two3), 'Passed!');
        // });

        QUnit.test("copy", (assert) -> {
          let a = new Triangle(MathConstants.one3.clone().negate(), MathConstants.one3.clone(), MathConstants.two3.clone());
          let b = new Triangle().copy(a);
          assert.ok(b.a.equals(MathConstants.one3.clone().negate()), 'Passed!');
          assert.ok(b.b.equals(MathConstants.one3), 'Passed!');
          assert.ok(b.c.equals(MathConstants.two3), 'Passed!');

          // ensure that it is a true copy
          a.a = MathConstants.one3;
          a.b = MathConstants.zero3;
          a.c = MathConstants.zero3;
          assert.ok(b.a.equals(MathConstants.one3.clone().negate()), 'Passed!');
          assert.ok(b.b.equals(MathConstants.one3), 'Passed!');
          assert.ok(b.c.equals(MathConstants.two3), 'Passed!');
        });

        QUnit.test("getArea", (assert) -> {
          let a = new Triangle();

          assert.ok(a.getArea() == 0, 'Passed!');

          a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
          assert.ok(a.getArea() == 0.5, 'Passed!');

          a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
          assert.ok(a.getArea() == 2, 'Passed!');

          // colinear triangle.
          a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(3, 0, 0));
          assert.ok(a.getArea() == 0, 'Passed!');
        });

        QUnit.test("getMidpoint", (assert) -> {
          let a = new Triangle();
          let midpoint = new Vector3();

          assert.ok(a.getMidpoint(midpoint).equals(new Vector3(0, 0, 0)), 'Passed!');

          a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
          assert.ok(a.getMidpoint(midpoint).equals(new Vector3(1 / 3, 1 / 3, 0)), 'Passed!');

          a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
          assert.ok(a.getMidpoint(midpoint).equals(new Vector3(2 / 3, 0, 2 / 3)), 'Passed!');
        });

        QUnit.test("getNormal", (assert) -> {
          let a = new Triangle();
          let normal = new Vector3();

          assert.ok(a.getNormal(normal).equals(new Vector3(0, 0, 0)), 'Passed!');

          a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
          assert.ok(a.getNormal(normal).equals(new Vector3(0, 0, 1)), 'Passed!');

          a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
          assert.ok(a.getNormal(normal).equals(new Vector3(0, 1, 0)), 'Passed!');
        });

        QUnit.test("getPlane", (assert) -> {
          let a = new Triangle();
          let plane = new Plane();
          let normal = new Vector3();

          a.getPlane(plane);
          assert.notOk(isNaN(plane.distanceToPoint(a.a)), 'Passed!');
          assert.notOk(isNaN(plane.distanceToPoint(a.b)), 'Passed!');
          assert.notOk(isNaN(plane.distanceToPoint(a.c)), 'Passed!');
          assert.notPropEqual(plane.normal, { x: NaN, y: NaN, z: NaN }, 'Passed!');

          a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
          a.getPlane(plane);
          a.getNormal(normal);
          assert.ok(plane.distanceToPoint(a.a) == 0, 'Passed!');
          assert.ok(plane.distanceToPoint(a.b) == 0, 'Passed!');
          assert.ok(plane.distanceToPoint(a.c) == 0, 'Passed!');
          assert.ok(plane.normal.equals(normal), 'Passed!');

          a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
          a.getPlane(plane);
          a.getNormal(normal);
          assert.ok(plane.distanceToPoint(a.a) == 0, 'Passed!');
          assert.ok(plane.distanceToPoint(a.b) == 0, 'Passed!');
          assert.ok(plane.distanceToPoint(a.c) == 0, 'Passed!');
          assert.ok(plane.normal.clone().normalize().equals(normal), 'Passed!');
        });

        QUnit.test("getBarycoord", (assert) -> {
          let a = new Triangle();

          let barycoord = new Vector3();
          let midpoint = new Vector3();

          assert.ok(a.getBarycoord(a.a, barycoord) === null, 'Passed!');
          assert.ok(a.getBarycoord(a.b, barycoord) === null, 'Passed!');
          assert.ok(a.getBarycoord(a.c, barycoord) === null, 'Passed!');

          a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
          a.getMidpoint(midpoint);

          a.getBarycoord(a.a, barycoord);
          assert.ok(barycoord.equals(new Vector3(1, 0, 0)), 'Passed!');
          a.getBarycoord(a.b, barycoord);
          assert.ok(barycoord.equals(new Vector3(0, 1, 0)), 'Passed!');
          a.getBarycoord(a.c, barycoord);
          assert.ok(barycoord.equals(new Vector3(0, 0, 1)), 'Passed!');
          a.getBarycoord(midpoint, barycoord);
          assert.ok(barycoord.distanceTo(new Vector3(1 / 3, 1 / 3, 1 / 3)) < 0.0001, 'Passed!');

          a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
          a.getMidpoint(midpoint);

          a.getBarycoord(a.a, barycoord);
          assert.ok(barycoord.equals(new Vector3(1, 0, 0)), 'Passed!');
          a.getBarycoord(a.b, barycoord);
          assert.ok(barycoord.equals(new Vector3(0, 1, 0)), 'Passed!');
          a.getBarycoord(a.c, barycoord);
          assert.ok(barycoord.equals(new Vector3(0, 0, 1)), 'Passed!');
          a.getBarycoord(midpoint, barycoord);
          assert.ok(barycoord.distanceTo(new Vector3(1 / 3, 1 / 3, 1 / 3)) < 0.0001, 'Passed!');
        });

        QUnit.test("containsPoint", (assert) -> {
          let a = new Triangle();
          let midpoint = new Vector3();

          assert.ok(!a.containsPoint(a.a), 'Passed!');
          assert.ok(!a.containsPoint(a.b), 'Passed!');
          assert.ok(!a.containsPoint(a.c), 'Passed!');

          a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
          a.getMidpoint(midpoint);
          assert.ok(a.containsPoint(a.a), 'Passed!');
          assert.ok(a.containsPoint(a.b), 'Passed!');
          assert.ok(a.containsPoint(a.c), 'Passed!');
          assert.ok(a.containsPoint(midpoint), 'Passed!');
          assert.ok(!a.containsPoint(new Vector3(-1, -1, -1)), 'Passed!');

          a = new Triangle(new Vector3(2, 0, 0), new Vector3(0, 0, 0), new Vector3(0, 0, 2));
          a.getMidpoint(midpoint);
          assert.ok(a.containsPoint(a.a), 'Passed!');
          assert.ok(a.containsPoint(a.b), 'Passed!');
          assert.ok(a.containsPoint(a.c), 'Passed!');
          assert.ok(a.containsPoint(midpoint), 'Passed!');
          assert.ok(!a.containsPoint(new Vector3(-1, -1, -1)), 'Passed!');
        });

        QUnit.test("intersectsBox", (assert) -> {
          let a = new Box3(MathConstants.one3.clone(), MathConstants.two3.clone());
          let b = new Triangle(new Vector3(1.5, 1.5, 2.5), new Vector3(2.5, 1.5, 1.5), new Vector3(1.5, 2.5, 1.5));
          let c = new Triangle(new Vector3(1.5, 1.5, 3.5), new Vector3(3.5, 1.5, 1.5), new Vector3(1.5, 1.5, 1.5));
          let d = new Triangle(new Vector3(1.5, 1.75, 3), new Vector3(3, 1.75, 1.5), new Vector3(1.5, 2.5, 1.5));
          let e = new Triangle(new Vector3(1.5, 1.8, 3), new Vector3(3, 1.8, 1.5), new Vector3(1.5, 2.5, 1.5));
          let f = new Triangle(new Vector3(1.5, 2.5, 3), new Vector3(3, 2.5, 1.5), new Vector3(1.5, 2.5, 1.5));

          assert.ok(b.intersectsBox(a), 'Passed!');
          assert.ok(c.intersectsBox(a), 'Passed!');
          assert.ok(d.intersectsBox(a), 'Passed!');
          assert.ok(!e.intersectsBox(a), 'Passed!');
          assert.ok(!f.intersectsBox(a), 'Passed!');
        });

        QUnit.test("closestPointToPoint", (assert) -> {
          let a = new Triangle(new Vector3(-1, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
          let point = new Vector3();

          // point lies inside the triangle
          a.closestPointToPoint(new Vector3(0, 0.5, 0), point);
          assert.ok(point.equals(new Vector3(0, 0.5, 0)), 'Passed!');

          // point lies on a vertex
          a.closestPointToPoint(a.a, point);
          assert.ok(point.equals(a.a), 'Passed!');

          a.closestPointToPoint(a.b, point);
          assert.ok(point.equals(a.b), 'Passed!');

          a.closestPointToPoint(a.c, point);
          assert.ok(point.equals(a.c), 'Passed!');

          // point lies on an edge
          a.closestPointToPoint(MathConstants.zero3.clone(), point);
          assert.ok(point.equals(MathConstants.zero3.clone()), 'Passed!');

          // point lies outside the triangle
          a.closestPointToPoint(new Vector3(-2, 0, 0), point);
          assert.ok(point.equals(new Vector3(-1, 0, 0)), 'Passed!');

          a.closestPointToPoint(new Vector3(2, 0, 0), point);
          assert.ok(point.equals(new Vector3(1, 0, 0)), 'Passed!');

          a.closestPointToPoint(new Vector3(0, 2, 0), point);
          assert.ok(point.equals(new Vector3(0, 1, 0)), 'Passed!');

          a.closestPointToPoint(new Vector3(0, -2, 0), point);
          assert.ok(point.equals(new Vector3(0, 0, 0)), 'Passed!');
        });

        QUnit.test("isFrontFacing", (assert) -> {
          let a = new Triangle();
          let dir = new Vector3();
          assert.ok(!a.isFrontFacing(dir), 'Passed!');

          a = new Triangle(new Vector3(0, 0, 0), new Vector3(1, 0, 0), new Vector3(0, 1, 0));
          dir = new Vector3(0, 0, -1);
          assert.ok(a.isFrontFacing(dir), 'Passed!');

          a = new Triangle(new Vector3(0, 0, 0), new Vector3(0, 1, 0), new Vector3(1, 0, 0));
          assert.ok(!a.isFrontFacing(dir), 'Passed!');
        });

        QUnit.test("equals", (assert) -> {
          let a = new Triangle(
            new Vector3(1, 0, 0),
            new Vector3(0, 1, 0),
            new Vector3(0, 0, 1)
          );
          let b = new Triangle(
            new Vector3(0, 0, 1),
            new Vector3(0, 1, 0),
            new Vector3(1, 0, 0)
          );
          let c = new Triangle(
            new Vector3(-1, 0, 0),
            new Vector3(0, 1, 0),
            new Vector3(0, 0, 1)
          );

          assert.ok(a.equals(a), 'a equals a');
          assert.notOk(a.equals(b), 'a does not equal b');
          assert.notOk(a.equals(c), 'a does not equal c');
          assert.notOk(b.equals(c), 'b does not equal c');

          a.copy(b);
          assert.ok(a.equals(a), 'a equals b after copy()');
        });

      });
    });
  }
}