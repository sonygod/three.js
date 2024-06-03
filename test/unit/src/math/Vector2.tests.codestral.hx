import qunit.QUnit;
import three.math.Vector2;
import three.math.Matrix3;
import three.core.BufferAttribute;
import mathconstants.MathConstants;

class Vector2Tests {
    public function new() {
        QUnit.module("Maths", () -> {
            QUnit.module("Vector2", () -> {
                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var a = new Vector2();
                    assert.ok(a.x == 0, "Passed!");
                    assert.ok(a.y == 0, "Passed!");

                    a = new Vector2(MathConstants.x, MathConstants.y);
                    assert.ok(a.x === MathConstants.x, "Passed!");
                    assert.ok(a.y === MathConstants.y, "Passed!");
                });

                // PROPERTIES
                QUnit.test("properties", (assert) -> {
                    var a = new Vector2(0, 0);
                    var width = 100;
                    var height = 200;

                    assert.ok(a.width = width, "Set width");
                    assert.ok(a.height = height, "Set height");

                    a.set(width, height);
                    assert.strictEqual(a.width, width, "Get width");
                    assert.strictEqual(a.height, height, "Get height");
                });

                // PUBLIC STUFF
                QUnit.test("isVector2", (assert) -> {
                    var object = new Vector2();
                    assert.ok(object.isVector2, "Vector2.isVector2 should be true");
                });

                QUnit.test("set", (assert) -> {
                    var a = new Vector2();
                    assert.ok(a.x == 0, "Passed!");
                    assert.ok(a.y == 0, "Passed!");

                    a.set(MathConstants.x, MathConstants.y);
                    assert.ok(a.x == MathConstants.x, "Passed!");
                    assert.ok(a.y == MathConstants.y, "Passed!");
                });

                QUnit.test("copy", (assert) -> {
                    var a = new Vector2(MathConstants.x, MathConstants.y);
                    var b = new Vector2().copy(a);
                    assert.ok(b.x == MathConstants.x, "Passed!");
                    assert.ok(b.y == MathConstants.y, "Passed!");

                    // ensure that it is a true copy
                    a.x = 0;
                    a.y = -1;
                    assert.ok(b.x == MathConstants.x, "Passed!");
                    assert.ok(b.y == MathConstants.y, "Passed!");
                });

                QUnit.test("add", (assert) -> {
                    var a = new Vector2(MathConstants.x, MathConstants.y);
                    var b = new Vector2(-MathConstants.x, -MathConstants.y);

                    a.add(b);
                    assert.ok(a.x == 0, "Passed!");
                    assert.ok(a.y == 0, "Passed!");

                    var c = new Vector2().addVectors(b, b);
                    assert.ok(c.x == -2 * MathConstants.x, "Passed!");
                    assert.ok(c.y == -2 * MathConstants.y, "Passed!");
                });

                QUnit.test("addScaledVector", (assert) -> {
                    var a = new Vector2(MathConstants.x, MathConstants.y);
                    var b = new Vector2(2, 3);
                    var s = 3;

                    a.addScaledVector(b, s);
                    assert.strictEqual(a.x, MathConstants.x + b.x * s, "Check x");
                    assert.strictEqual(a.y, MathConstants.y + b.y * s, "Check y");
                });

                QUnit.test("sub", (assert) -> {
                    var a = new Vector2(MathConstants.x, MathConstants.y);
                    var b = new Vector2(-MathConstants.x, -MathConstants.y);

                    a.sub(b);
                    assert.ok(a.x == 2 * MathConstants.x, "Passed!");
                    assert.ok(a.y == 2 * MathConstants.y, "Passed!");

                    var c = new Vector2().subVectors(a, a);
                    assert.ok(c.x == 0, "Passed!");
                    assert.ok(c.y == 0, "Passed!");
                });

                QUnit.test("applyMatrix3", (assert) -> {
                    var a = new Vector2(MathConstants.x, MathConstants.y);
                    var m = new Matrix3().set(2, 3, 5, 7, 11, 13, 17, 19, 23);

                    a.applyMatrix3(m);
                    assert.strictEqual(a.x, 18, "Check x");
                    assert.strictEqual(a.y, 60, "Check y");
                });

                QUnit.test("negate", (assert) -> {
                    var a = new Vector2(MathConstants.x, MathConstants.y);

                    a.negate();
                    assert.ok(a.x == -MathConstants.x, "Passed!");
                    assert.ok(a.y == -MathConstants.y, "Passed!");
                });

                QUnit.test("dot", (assert) -> {
                    var a = new Vector2(MathConstants.x, MathConstants.y);
                    var b = new Vector2(-MathConstants.x, -MathConstants.y);
                    var c = new Vector2();

                    var result = a.dot(b);
                    assert.ok(result == (-MathConstants.x * MathConstants.x - MathConstants.y * MathConstants.y), "Passed!");

                    result = a.dot(c);
                    assert.ok(result == 0, "Passed!");
                });

                QUnit.test("cross", (assert) -> {
                    var a = new Vector2(MathConstants.x, MathConstants.y);
                    var b = new Vector2(2 * MathConstants.x, -MathConstants.y);
                    var answer = -18;
                    var crossed = a.cross(b);

                    assert.ok(Math.abs(answer - crossed) <= MathConstants.eps, "Check cross");
                });

                QUnit.test("manhattanLength", (assert) -> {
                    var a = new Vector2(MathConstants.x, 0);
                    var b = new Vector2(0, -MathConstants.y);
                    var c = new Vector2();

                    assert.strictEqual(a.manhattanLength(), MathConstants.x, "Positive component");
                    assert.strictEqual(b.manhattanLength(), MathConstants.y, "Negative component");
                    assert.strictEqual(c.manhattanLength(), 0, "Empty component");

                    a.set(MathConstants.x, MathConstants.y);
                    assert.strictEqual(a.manhattanLength(), Math.abs(MathConstants.x) + Math.abs(MathConstants.y), "Two components");
                });

                QUnit.test("normalize", (assert) -> {
                    var a = new Vector2(MathConstants.x, 0);
                    var b = new Vector2(0, -MathConstants.y);

                    a.normalize();
                    assert.ok(a.length() == 1, "Passed!");
                    assert.ok(a.x == 1, "Passed!");

                    b.normalize();
                    assert.ok(b.length() == 1, "Passed!");
                    assert.ok(b.y == -1, "Passed!");
                });

                QUnit.test("angleTo", (assert) -> {
                    var a = new Vector2(-0.18851655680720186, 0.9820700116639124);
                    var b = new Vector2(0.18851655680720186, -0.9820700116639124);

                    assert.equal(a.angleTo(a), 0);
                    assert.equal(a.angleTo(b), Math.PI);

                    var x = new Vector2(1, 0);
                    var y = new Vector2(0, 1);

                    assert.equal(x.angleTo(y), Math.PI / 2);
                    assert.equal(y.angleTo(x), Math.PI / 2);

                    assert.ok(Math.abs(x.angleTo(new Vector2(1, 1)) - (Math.PI / 4)) < 0.0000001);
                });

                QUnit.test("setLength", (assert) -> {
                    var a = new Vector2(MathConstants.x, 0);

                    assert.ok(a.length() == MathConstants.x, "Passed!");
                    a.setLength(MathConstants.y);
                    assert.ok(a.length() == MathConstants.y, "Passed!");

                    a = new Vector2(0, 0);
                    assert.ok(a.length() == 0, "Passed!");
                    a.setLength(MathConstants.y);
                    assert.ok(a.length() == 0, "Passed!");
                    a.setLength();
                    assert.ok(isNaN(a.length()), "Passed!");
                });

                QUnit.test("equals", (assert) -> {
                    var a = new Vector2(MathConstants.x, 0);
                    var b = new Vector2(0, -MathConstants.y);

                    assert.ok(a.x != b.x, "Passed!");
                    assert.ok(a.y != b.y, "Passed!");

                    assert.ok(!a.equals(b), "Passed!");
                    assert.ok(!b.equals(a), "Passed!");

                    a.copy(b);
                    assert.ok(a.x == b.x, "Passed!");
                    assert.ok(a.y == b.y, "Passed!");

                    assert.ok(a.equals(b), "Passed!");
                    assert.ok(b.equals(a), "Passed!");
                });

                QUnit.test("fromArray", (assert) -> {
                    var a = new Vector2();
                    var array = [1, 2, 3, 4];

                    a.fromArray(array);
                    assert.strictEqual(a.x, 1, "No offset: check x");
                    assert.strictEqual(a.y, 2, "No offset: check y");

                    a.fromArray(array, 2);
                    assert.strictEqual(a.x, 3, "With offset: check x");
                    assert.strictEqual(a.y, 4, "With offset: check y");
                });

                QUnit.test("toArray", (assert) -> {
                    var a = new Vector2(MathConstants.x, MathConstants.y);

                    var array = a.toArray();
                    assert.strictEqual(array[0], MathConstants.x, "No array, no offset: check x");
                    assert.strictEqual(array[1], MathConstants.y, "No array, no offset: check y");

                    array = [];
                    a.toArray(array);
                    assert.strictEqual(array[0], MathConstants.x, "With array, no offset: check x");
                    assert.strictEqual(array[1], MathConstants.y, "With array, no offset: check y");

                    array = [];
                    a.toArray(array, 1);
                    assert.strictEqual(array[0], null, "With array and offset: check [0]");
                    assert.strictEqual(array[1], MathConstants.x, "With array and offset: check x");
                    assert.strictEqual(array[2], MathConstants.y, "With array and offset: check y");
                });

                QUnit.test("fromBufferAttribute", (assert) -> {
                    var a = new Vector2();
                    var attr = new BufferAttribute(new Float32Array([1, 2, 3, 4]), 2);

                    a.fromBufferAttribute(attr, 0);
                    assert.strictEqual(a.x, 1, "Offset 0: check x");
                    assert.strictEqual(a.y, 2, "Offset 0: check y");

                    a.fromBufferAttribute(attr, 1);
                    assert.strictEqual(a.x, 3, "Offset 1: check x");
                    assert.strictEqual(a.y, 4, "Offset 1: check y");
                });

                // TODO (Itee) refactor/split
                QUnit.test("setX,setY", (assert) -> {
                    var a = new Vector2();
                    assert.ok(a.x == 0, "Passed!");
                    assert.ok(a.y == 0, "Passed!");

                    a.setX(MathConstants.x);
                    a.setY(MathConstants.y);
                    assert.ok(a.x == MathConstants.x, "Passed!");
                    assert.ok(a.y == MathConstants.y, "Passed!");
                });

                QUnit.test("setComponent,getComponent", (assert) -> {
                    var a = new Vector2();
                    assert.ok(a.x == 0, "Passed!");
                    assert.ok(a.y == 0, "Passed!");

                    a.setComponent(0, 1);
                    a.setComponent(1, 2);
                    assert.ok(a.getComponent(0) == 1, "Passed!");
                    assert.ok(a.getComponent(1) == 2, "Passed!");
                });

                QUnit.test("multiply/divide", (assert) -> {
                    var a = new Vector2(MathConstants.x, MathConstants.y);
                    var b = new Vector2(-MathConstants.x, -MathConstants.y);

                    a.multiplyScalar(-2);
                    assert.ok(a.x == MathConstants.x * -2, "Passed!");
                    assert.ok(a.y == MathConstants.y * -2, "Passed!");

                    b.multiplyScalar(-2);
                    assert.ok(b.x == 2 * MathConstants.x, "Passed!");
                    assert.ok(b.y == 2 * MathConstants.y, "Passed!");

                    a.divideScalar(-2);
                    assert.ok(a.x == MathConstants.x, "Passed!");
                    assert.ok(a.y == MathConstants.y, "Passed!");

                    b.divideScalar(-2);
                    assert.ok(b.x == -MathConstants.x, "Passed!");
                    assert.ok(b.y == -MathConstants.y, "Passed!");
                });

                QUnit.test("min/max/clamp", (assert) -> {
                    var a = new Vector2(MathConstants.x, MathConstants.y);
                    var b = new Vector2(-MathConstants.x, -MathConstants.y);
                    var c = new Vector2();

                    c.copy(a).min(b);
                    assert.ok(c.x == -MathConstants.x, "Passed!");
                    assert.ok(c.y == -MathConstants.y, "Passed!");

                    c.copy(a).max(b);
                    assert.ok(c.x == MathConstants.x, "Passed!");
                    assert.ok(c.y == MathConstants.y, "Passed!");

                    c.set(-2 * MathConstants.x, 2 * MathConstants.y);
                    c.clamp(b, a);
                    assert.ok(c.x == -MathConstants.x, "Passed!");
                    assert.ok(c.y == MathConstants.y, "Passed!");

                    c.set(-2 * MathConstants.x, 2 * MathConstants.x);
                    c.clampScalar(-MathConstants.x, MathConstants.x);
                    assert.equal(c.x, -MathConstants.x, "scalar clamp x");
                    assert.equal(c.y, MathConstants.x, "scalar clamp y");
                });

                QUnit.test("rounding", (assert) -> {
                    assert.deepEqual(new Vector2(-0.1, 0.1).floor(), new Vector2(-1, 0), "floor .1");
                    assert.deepEqual(new Vector2(-0.5, 0.5).floor(), new Vector2(-1, 0), "floor .5");
                    assert.deepEqual(new Vector2(-0.9, 0.9).floor(), new Vector2(-1, 0), "floor .9");

                    assert.deepEqual(new Vector2(-0.1, 0.1).ceil(), new Vector2(0, 1), "ceil .1");
                    assert.deepEqual(new Vector2(-0.5, 0.5).ceil(), new Vector2(0, 1), "ceil .5");
                    assert.deepEqual(new Vector2(-0.9, 0.9).ceil(), new Vector2(0, 1), "ceil .9");

                    assert.deepEqual(new Vector2(-0.1, 0.1).round(), new Vector2(0, 0), "round .1");
                    assert.deepEqual(new Vector2(-0.5, 0.5).round(), new Vector2(0, 1), "round .5");
                    assert.deepEqual(new Vector2(-0.9, 0.9).round(), new Vector2(-1, 1), "round .9");

                    assert.deepEqual(new Vector2(-0.1, 0.1).roundToZero(), new Vector2(0, 0), "roundToZero .1");
                    assert.deepEqual(new Vector2(-0.5, 0.5).roundToZero(), new Vector2(0, 0), "roundToZero .5");
                    assert.deepEqual(new Vector2(-0.9, 0.9).roundToZero(), new Vector2(0, 0), "roundToZero .9");
                    assert.deepEqual(new Vector2(-1.1, 1.1).roundToZero(), new Vector2(-1, 1), "roundToZero 1.1");
                    assert.deepEqual(new Vector2(-1.5, 1.5).roundToZero(), new Vector2(-1, 1), "roundToZero 1.5");
                    assert.deepEqual(new Vector2(-1.9, 1.9).roundToZero(), new Vector2(-1, 1), "roundToZero 1.9");
                });

                QUnit.test("length/lengthSq", (assert) -> {
                    var a = new Vector2(MathConstants.x, 0);
                    var b = new Vector2(0, -MathConstants.y);
                    var c = new Vector2();

                    assert.ok(a.length() == MathConstants.x, "Passed!");
                    assert.ok(a.lengthSq() == MathConstants.x * MathConstants.x, "Passed!");
                    assert.ok(b.length() == MathConstants.y, "Passed!");
                    assert.ok(b.lengthSq() == MathConstants.y * MathConstants.y, "Passed!");
                    assert.ok(c.length() == 0, "Passed!");
                    assert.ok(c.lengthSq() == 0, "Passed!");

                    a.set(MathConstants.x, MathConstants.y);
                    assert.ok(a.length() == Math.sqrt(MathConstants.x * MathConstants.x + MathConstants.y * MathConstants.y), "Passed!");
                    assert.ok(a.lengthSq() == (MathConstants.x * MathConstants.x + MathConstants.y * MathConstants.y), "Passed!");
                });

                QUnit.test("distanceTo/distanceToSquared", (assert) -> {
                    var a = new Vector2(MathConstants.x, 0);
                    var b = new Vector2(0, -MathConstants.y);
                    var c = new Vector2();

                    assert.ok(a.distanceTo(c) == MathConstants.x, "Passed!");
                    assert.ok(a.distanceToSquared(c) == MathConstants.x * MathConstants.x, "Passed!");

                    assert.ok(b.distanceTo(c) == MathConstants.y, "Passed!");
                    assert.ok(b.distanceToSquared(c) == MathConstants.y * MathConstants.y, "Passed!");
                });

                QUnit.test("lerp/clone", (assert) -> {
                    var a = new Vector2(MathConstants.x, 0);
                    var b = new Vector2(0, -MathConstants.y);

                    assert.ok(a.lerp(a, 0).equals(a.lerp(a, 0.5)), "Passed!");
                    assert.ok(a.lerp(a, 0).equals(a.lerp(a, 1)), "Passed!");

                    assert.ok(a.clone().lerp(b, 0).equals(a), "Passed!");

                    assert.ok(a.clone().lerp(b, 0.5).x == MathConstants.x * 0.5, "Passed!");
                    assert.ok(a.clone().lerp(b, 0.5).y == -MathConstants.y * 0.5, "Passed!");

                    assert.ok(a.clone().lerp(b, 1).equals(b), "Passed!");
                });

                QUnit.test("setComponent/getComponent exceptions", (assert) -> {
                    var a = new Vector2(0, 0);

                    try {
                        a.setComponent(2, 0);
                        assert.fail("setComponent with an out of range index should throw Error");
                    } catch (e:Error) {
                        assert.equal(e.message, "index is out of range: 2");
                    }

                    try {
                        a.getComponent(2);
                        assert.fail("getComponent with an out of range index should throw Error");
                    } catch (e:Error) {
                        assert.equal(e.message, "index is out of range: 2");
                    }
                });

                QUnit.test("setScalar/addScalar/subScalar", (assert) -> {
                    var a = new Vector2(1, 1);
                    var s = 3;

                    a.setScalar(s);
                    assert.strictEqual(a.x, s, "setScalar: check x");
                    assert.strictEqual(a.y, s, "setScalar: check y");

                    a.addScalar(s);
                    assert.strictEqual(a.x, 2 * s, "addScalar: check x");
                    assert.strictEqual(a.y, 2 * s, "addScalar: check y");

                    a.subScalar(2 * s);
                    assert.strictEqual(a.x, 0, "subScalar: check x");
                    assert.strictEqual(a.y, 0, "subScalar: check y");
                });

                QUnit.test("multiply/divide", (assert) -> {
                    var a = new Vector2(MathConstants.x, MathConstants.y);
                    var b = new Vector2(2 * MathConstants.x, 2 * MathConstants.y);
                    var c = new Vector2(4 * MathConstants.x, 4 * MathConstants.y);

                    a.multiply(b);
                    assert.strictEqual(a.x, MathConstants.x * b.x, "multiply: check x");
                    assert.strictEqual(a.y, MathConstants.y * b.y, "multiply: check y");

                    b.divide(c);
                    assert.strictEqual(b.x, 0.5, "divide: check x");
                    assert.strictEqual(b.y, 0.5, "divide: check y");
                });
            });
        });
    }
}