package math;

import haxe.unit.TestRunner;
import math.MathUtils;

class MathTests {
    public function new() {}

    public static function main() {
        var runner = new TestRunner();
        runner.addTest(new MathTests());
        runner.run();
    }

    public function testGenerateUUID() {
        var a = MathUtils.generateUUID();
        var regex = ~/[A-Z0-9]{8}-[A-Z0-9]{4}-4[A-Z0-9]{3}-[A-Z0-9]{4}-[A-Z0-9]{12}/i;
        assertTrue(regex.match(a), 'Generated UUID matches the expected pattern');
    }

    public function testClamp() {
        assertEquals(MathUtils.clamp(0.5, 0, 1), 0.5, 'Value already within limits');
        assertEquals(MathUtils.clamp(0, 0, 1), 0, 'Value equal to one limit');
        assertEquals(MathUtils.clamp(-0.1, 0, 1), 0, 'Value too low');
        assertEquals(MathUtils.clamp(1.1, 0, 1), 1, 'Value too high');
    }

    public function testEuclideanModulo() {
        assertTrue(Math.isNaN(MathUtils.euclideanModulo(6, 0)), 'Division by zero returns NaN');
        assertEquals(MathUtils.euclideanModulo(6, 1), 0, 'Divison by trivial divisor');
        assertEquals(MathUtils.euclideanModulo(6, 2), 0, 'Divison by non-trivial divisor');
        assertEquals(MathUtils.euclideanModulo(6, 5), 1, 'Divison by itself - 1');
        assertEquals(MathUtils.euclideanModulo(6, 6), 0, 'Divison by itself');
        assertEquals(MathUtils.euclideanModulo(6, 7), 6, 'Divison by itself + 1');
    }

    public function testMapLinear() {
        assertEquals(MathUtils.mapLinear(0.5, 0, 1, 0, 10), 5, 'Value within range');
        assertEquals(MathUtils.mapLinear(0.0, 0, 1, 0, 10), 0, 'Value equal to lower boundary');
        assertEquals(MathUtils.mapLinear(1.0, 0, 1, 0, 10), 10, 'Value equal to upper boundary');
    }

    public function testInverseLerp() {
        assertEquals(MathUtils.inverseLerp(1, 2, 1.5), 0.5, '50% Percentage');
        assertEquals(MathUtils.inverseLerp(1, 2, 2), 1, '100% Percentage');
        assertEquals(MathUtils.inverseLerp(1, 2, 1), 0, '0% Percentage');
        assertEquals(MathUtils.inverseLerp(1, 1, 1), 0, '0% Percentage, no NaN value');
    }

    public function testLerp() {
        assertEquals(MathUtils.lerp(1, 2, 0), 1, 'Value equal to lower boundary');
        assertEquals(MathUtils.lerp(1, 2, 1), 2, 'Value equal to upper boundary');
        assertEquals(MathUtils.lerp(1, 2, 0.4), 1.4, 'Value within range');
    }

    public function testDamp() {
        assertEquals(MathUtils.damp(1, 2, 0, 0.016), 1, 'Value equal to lower boundary');
        assertEquals(MathUtils.damp(1, 2, 10, 0.016), 1.1478562110337887, 'Value within range');
    }

    public function testPingPong() {
        assertEquals(MathUtils.pingpong(2.5), 0.5, 'Value at 2.5 is 0.5');
        assertEquals(MathUtils.pingpong(2.5, 2), 1.5, 'Value at 2.5 with length of 2 is 1.5');
        assertEquals(MathUtils.pingpong(-1.5), 0.5, 'Value at -1.5 is 0.5');
    }

    public function testSmoothstep() {
        assertEquals(MathUtils.smoothstep(-1, 0, 2), 0, 'Value lower than minimum');
        assertEquals(MathUtils.smoothstep(0, 0, 2), 0, 'Value equal to minimum');
        assertEquals(MathUtils.smoothstep(0.5, 0, 2), 0.15625, 'Value within limits');
        assertEquals(MathUtils.smoothstep(1, 0, 2), 0.5, 'Value within limits');
        assertEquals(MathUtils.smoothstep(1.5, 0, 2), 0.84375, 'Value within limits');
        assertEquals(MathUtils.smoothstep(2, 0, 2), 1, 'Value equal to maximum');
        assertEquals(MathUtils.smoothstep(3, 0, 2), 1, 'Value highter than maximum');
    }

    public function testSmootherstep() {
        assertEquals(MathUtils.smootherstep(-1, 0, 2), 0, 'Value lower than minimum');
        assertEquals(MathUtils.smootherstep(0, 0, 2), 0, 'Value equal to minimum');
        assertEquals(MathUtils.smootherstep(0.5, 0, 2), 0.103515625, 'Value within limits');
        assertEquals(MathUtils.smootherstep(1, 0, 2), 0.5, 'Value within limits');
        assertEquals(MathUtils.smootherstep(1.5, 0, 2), 0.896484375, 'Value within limits');
        assertEquals(MathUtils.smootherstep(2, 0, 2), 1, 'Value equal to maximum');
        assertEquals(MathUtils.smootherstep(3, 0, 2), 1, 'Value highter than maximum');
    }

    public function testRandInt() {
        var low = 1;
        var high = 3;
        var a = MathUtils.randInt(low, high);
        assertTrue(a >= low, 'Value equal to or higher than lower limit');
        assertTrue(a <= high, 'Value equal to or lower than upper limit');
    }

    public function testRandFloat() {
        var low = 1;
        var high = 3;
        var a = MathUtils.randFloat(low, high);
        assertTrue(a >= low, 'Value equal to or higher than lower limit');
        assertTrue(a <= high, 'Value equal to or lower than upper limit');
    }

    public function testRandFloatSpread() {
        var a = MathUtils.randFloatSpread(3);
        assertTrue(a > -3/2, 'Value higher than lower limit');
        assertTrue(a < 3/2, 'Value lower than upper limit');
    }

    public function todoSeededRandom() {
        // seededRandom( s ) // interval [ 0, 1 ]
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testDegToRad() {
        assertEquals(MathUtils.degToRad(0), 0, '0 degrees');
        assertEquals(MathUtils.degToRad(90), Math.PI / 2, '90 degrees');
        assertEquals(MathUtils.degToRad(180), Math.PI, '180 degrees');
        assertEquals(MathUtils.degToRad(360), Math.PI * 2, '360 degrees');
    }

    public function testRadToDeg() {
        assertEquals(MathUtils.radToDeg(0), 0, '0 radians');
        assertEquals(MathUtils.radToDeg(Math.PI / 2), 90, 'Math.PI / 2 radians');
        assertEquals(MathUtils.radToDeg(Math.PI), 180, 'Math.PI radians');
        assertEquals(MathUtils.radToDeg(Math.PI * 2), 360, 'Math.PI * 2 radians');
    }

    public function testIsPowerOfTwo() {
        assertFalse(MathUtils.isPowerOfTwo(0), '0 is not a PoT');
        assertTrue(MathUtils.isPowerOfTwo(1), '1 is a PoT');
        assertTrue(MathUtils.isPowerOfTwo(2), '2 is a PoT');
        assertFalse(MathUtils.isPowerOfTwo(3), '3 is not a PoT');
        assertTrue(MathUtils.isPowerOfTwo(4), '4 is a PoT');
    }

    public function testCeilPowerOfTwo() {
        assertEquals(MathUtils.ceilPowerOfTwo(1), 1, 'Closest higher PoT to 1 is 1');
        assertEquals(MathUtils.ceilPowerOfTwo(3), 4, 'Closest higher PoT to 3 is 4');
        assertEquals(MathUtils.ceilPowerOfTwo(4), 4, 'Closest higher PoT to 4 is 4');
    }

    public function testFloorPowerOfTwo() {
        assertEquals(MathUtils.floorPowerOfTwo(1), 1, 'Closest lower PoT to 1 is 1');
        assertEquals(MathUtils.floorPowerOfTwo(3), 2, 'Closest lower PoT to 3 is 2');
        assertEquals(MathUtils.floorPowerOfTwo(4), 4, 'Closest lower PoT to 4 is 4');
    }

    public function todoSetQuaternionFromProperEuler() {
        // setQuaternionFromProperEuler( q, a, b, c, order )
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoDenormalize() {
        // denormalize( value, array )
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoNormalize() {
        // normalize( value, array )
        assertTrue(false, 'everything\'s gonna be alright');
    }
}