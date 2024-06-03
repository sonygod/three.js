import js.Browser.document;
import js.QUnit;
import three.math.MathUtils;

class MathUtilsTests {
    public static function runTests():Void {
        QUnit.module("Maths", () -> {
            QUnit.module("Math", () -> {

                QUnit.test("generateUUID", (assert:QUnit.Assert) -> {
                    var a = MathUtils.generateUUID();
                    var regex = new EReg("[A-Z0-9]{8}-[A-Z0-9]{4}-4[A-Z0-9]{3}-[A-Z0-9]{4}-[A-Z0-9]{12}", "i");
                    QUnit.assert.ok(regex.match(a), "Generated UUID matches the expected pattern");
                });

                QUnit.test("clamp", (assert:QUnit.Assert) -> {
                    QUnit.assert.strictEqual(MathUtils.clamp(0.5, 0, 1), 0.5, "Value already within limits");
                    QUnit.assert.strictEqual(MathUtils.clamp(0, 0, 1), 0, "Value equal to one limit");
                    QUnit.assert.strictEqual(MathUtils.clamp(-0.1, 0, 1), 0, "Value too low");
                    QUnit.assert.strictEqual(MathUtils.clamp(1.1, 0, 1), 1, "Value too high");
                });

                QUnit.test("euclideanModulo", (assert:QUnit.Assert) -> {
                    QUnit.assert.ok(isNaN(MathUtils.euclideanModulo(6, 0)), "Division by zero returns NaN");
                    QUnit.assert.strictEqual(MathUtils.euclideanModulo(6, 1), 0, "Divison by trivial divisor");
                    QUnit.assert.strictEqual(MathUtils.euclideanModulo(6, 2), 0, "Divison by non-trivial divisor");
                    QUnit.assert.strictEqual(MathUtils.euclideanModulo(6, 5), 1, "Divison by itself - 1");
                    QUnit.assert.strictEqual(MathUtils.euclideanModulo(6, 6), 0, "Divison by itself");
                    QUnit.assert.strictEqual(MathUtils.euclideanModulo(6, 7), 6, "Divison by itself + 1");
                });

                QUnit.test("mapLinear", (assert:QUnit.Assert) -> {
                    QUnit.assert.strictEqual(MathUtils.mapLinear(0.5, 0, 1, 0, 10), 5, "Value within range");
                    QUnit.assert.strictEqual(MathUtils.mapLinear(0.0, 0, 1, 0, 10), 0, "Value equal to lower boundary");
                    QUnit.assert.strictEqual(MathUtils.mapLinear(1.0, 0, 1, 0, 10), 10, "Value equal to upper boundary");
                });

                QUnit.test("inverseLerp", (assert:QUnit.Assert) -> {
                    QUnit.assert.strictEqual(MathUtils.inverseLerp(1, 2, 1.5), 0.5, "50% Percentage");
                    QUnit.assert.strictEqual(MathUtils.inverseLerp(1, 2, 2), 1, "100% Percentage");
                    QUnit.assert.strictEqual(MathUtils.inverseLerp(1, 2, 1), 0, "0% Percentage");
                    QUnit.assert.strictEqual(MathUtils.inverseLerp(1, 1, 1), 0, "0% Percentage, no NaN value");
                });

                QUnit.test("lerp", (assert:QUnit.Assert) -> {
                    QUnit.assert.strictEqual(MathUtils.lerp(1, 2, 0), 1, "Value equal to lower boundary");
                    QUnit.assert.strictEqual(MathUtils.lerp(1, 2, 1), 2, "Value equal to upper boundary");
                    QUnit.assert.strictEqual(MathUtils.lerp(1, 2, 0.4), 1.4, "Value within range");
                });

                QUnit.test("damp", (assert:QUnit.Assert) -> {
                    QUnit.assert.strictEqual(MathUtils.damp(1, 2, 0, 0.016), 1, "Value equal to lower boundary");
                    QUnit.assert.strictEqual(MathUtils.damp(1, 2, 10, 0.016), 1.1478562110337887, "Value within range");
                });

                QUnit.test("pingpong", (assert:QUnit.Assert) -> {
                    QUnit.assert.strictEqual(MathUtils.pingpong(2.5), 0.5, "Value at 2.5 is 0.5");
                    QUnit.assert.strictEqual(MathUtils.pingpong(2.5, 2), 1.5, "Value at 2.5 with length of 2 is 1.5");
                    QUnit.assert.strictEqual(MathUtils.pingpong(-1.5), 0.5, "Value at -1.5 is 0.5");
                });

                QUnit.test("smoothstep", (assert:QUnit.Assert) -> {
                    QUnit.assert.strictEqual(MathUtils.smoothstep(-1, 0, 2), 0, "Value lower than minimum");
                    QUnit.assert.strictEqual(MathUtils.smoothstep(0, 0, 2), 0, "Value equal to minimum");
                    QUnit.assert.strictEqual(MathUtils.smoothstep(0.5, 0, 2), 0.15625, "Value within limits");
                    QUnit.assert.strictEqual(MathUtils.smoothstep(1, 0, 2), 0.5, "Value within limits");
                    QUnit.assert.strictEqual(MathUtils.smoothstep(1.5, 0, 2), 0.84375, "Value within limits");
                    QUnit.assert.strictEqual(MathUtils.smoothstep(2, 0, 2), 1, "Value equal to maximum");
                    QUnit.assert.strictEqual(MathUtils.smoothstep(3, 0, 2), 1, "Value highter than maximum");
                });

                QUnit.test("smootherstep", (assert:QUnit.Assert) -> {
                    QUnit.assert.strictEqual(MathUtils.smootherstep(-1, 0, 2), 0, "Value lower than minimum");
                    QUnit.assert.strictEqual(MathUtils.smootherstep(0, 0, 2), 0, "Value equal to minimum");
                    QUnit.assert.strictEqual(MathUtils.smootherstep(0.5, 0, 2), 0.103515625, "Value within limits");
                    QUnit.assert.strictEqual(MathUtils.smootherstep(1, 0, 2), 0.5, "Value within limits");
                    QUnit.assert.strictEqual(MathUtils.smootherstep(1.5, 0, 2), 0.896484375, "Value within limits");
                    QUnit.assert.strictEqual(MathUtils.smootherstep(2, 0, 2), 1, "Value equal to maximum");
                    QUnit.assert.strictEqual(MathUtils.smootherstep(3, 0, 2), 1, "Value highter than maximum");
                });

                QUnit.test("randInt", (assert:QUnit.Assert) -> {
                    var low = 1, high = 3;
                    var a = MathUtils.randInt(low, high);
                    QUnit.assert.ok(a >= low, "Value equal to or higher than lower limit");
                    QUnit.assert.ok(a <= high, "Value equal to or lower than upper limit");
                });

                QUnit.test("randFloat", (assert:QUnit.Assert) -> {
                    var low = 1, high = 3;
                    var a = MathUtils.randFloat(low, high);
                    QUnit.assert.ok(a >= low, "Value equal to or higher than lower limit");
                    QUnit.assert.ok(a <= high, "Value equal to or lower than upper limit");
                });

                QUnit.test("randFloatSpread", (assert:QUnit.Assert) -> {
                    var a = MathUtils.randFloatSpread(3);
                    QUnit.assert.ok(a > -3 / 2, "Value higher than lower limit");
                    QUnit.assert.ok(a < 3 / 2, "Value lower than upper limit");
                });

                QUnit.test("degToRad", (assert:QUnit.Assert) -> {
                    QUnit.assert.strictEqual(MathUtils.degToRad(0), 0, "0 degrees");
                    QUnit.assert.strictEqual(MathUtils.degToRad(90), Math.PI / 2, "90 degrees");
                    QUnit.assert.strictEqual(MathUtils.degToRad(180), Math.PI, "180 degrees");
                    QUnit.assert.strictEqual(MathUtils.degToRad(360), Math.PI * 2, "360 degrees");
                });

                QUnit.test("radToDeg", (assert:QUnit.Assert) -> {
                    QUnit.assert.strictEqual(MathUtils.radToDeg(0), 0, "0 radians");
                    QUnit.assert.strictEqual(MathUtils.radToDeg(Math.PI / 2), 90, "Math.PI / 2 radians");
                    QUnit.assert.strictEqual(MathUtils.radToDeg(Math.PI), 180, "Math.PI radians");
                    QUnit.assert.strictEqual(MathUtils.radToDeg(Math.PI * 2), 360, "Math.PI * 2 radians");
                });

                QUnit.test("isPowerOfTwo", (assert:QUnit.Assert) -> {
                    QUnit.assert.strictEqual(MathUtils.isPowerOfTwo(0), false, "0 is not a PoT");
                    QUnit.assert.strictEqual(MathUtils.isPowerOfTwo(1), true, "1 is a PoT");
                    QUnit.assert.strictEqual(MathUtils.isPowerOfTwo(2), true, "2 is a PoT");
                    QUnit.assert.strictEqual(MathUtils.isPowerOfTwo(3), false, "3 is not a PoT");
                    QUnit.assert.strictEqual(MathUtils.isPowerOfTwo(4), true, "4 is a PoT");
                });

                QUnit.test("ceilPowerOfTwo", (assert:QUnit.Assert) -> {
                    QUnit.assert.strictEqual(MathUtils.ceilPowerOfTwo(1), 1, "Closest higher PoT to 1 is 1");
                    QUnit.assert.strictEqual(MathUtils.ceilPowerOfTwo(3), 4, "Closest higher PoT to 3 is 4");
                    QUnit.assert.strictEqual(MathUtils.ceilPowerOfTwo(4), 4, "Closest higher PoT to 4 is 4");
                });

                QUnit.test("floorPowerOfTwo", (assert:QUnit.Assert) -> {
                    QUnit.assert.strictEqual(MathUtils.floorPowerOfTwo(1), 1, "Closest lower PoT to 1 is 1");
                    QUnit.assert.strictEqual(MathUtils.floorPowerOfTwo(3), 2, "Closest lower PoT to 3 is 2");
                    QUnit.assert.strictEqual(MathUtils.floorPowerOfTwo(4), 4, "Closest lower PoT to 4 is 4");
                });
            });
        });
    }
}