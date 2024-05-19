package three.math;

import haxe.unit.TestCase;
import three.math.Spherical;
import three.math.Vector3;
import three.utils.MathConstants;

class SphericalTests {
    public function new() {}

    public static function main() {
        var testCase = new SphericalTests();
        testCase.testInstancing();
        testCase.testSet();
        testCase.testClone();
        testCase.testCopy();
        testCase.testMakeSafe();
        testCase.testSetFromVector3();
        testCase.testSetFromCartesianCoords();
    }

    function testInstancing() {
        var a = new Spherical();
        var radius = 10.0;
        var phi = Math.acos(-0.5);
        var theta = Math.sqrt(Math.PI) * phi;

        TestCase.assertEquals(a.radius, 1.0);
        TestCase.assertEquals(a.phi, 0.0);
        TestCase.assertEquals(a.theta, 0.0);

        a = new Spherical(radius, phi, theta);
        TestCase.assertEquals(a.radius, radius);
        TestCase.assertEquals(a.phi, phi);
        TestCase.assertEquals(a.theta, theta);
    }

    function testSet() {
        var a = new Spherical();
        var radius = 10.0;
        var phi = Math.acos(-0.5);
        var theta = Math.sqrt(Math.PI) * phi;

        a.set(radius, phi, theta);
        TestCase.assertEquals(a.radius, radius);
        TestCase.assertEquals(a.phi, phi);
        TestCase.assertEquals(a.theta, theta);
    }

    function testClone() {
        var radius = 10.0;
        var phi = Math.acos(-0.5);
        var theta = Math.sqrt(Math.PI) * phi;
        var a = new Spherical(radius, phi, theta);
        var b = a.clone();

        TestCase.assertEquals(a, b);
        a.radius = 2.0;
        TestCase.assertNotEquals(a, b);
    }

    function testCopy() {
        var radius = 10.0;
        var phi = Math.acos(-0.5);
        var theta = Math.sqrt(Math.PI) * phi;
        var a = new Spherical(radius, phi, theta);
        var b = new Spherical().copy(a);

        TestCase.assertEquals(a, b);
        a.radius = 2.0;
        TestCase.assertNotEquals(a, b);
    }

    function testMakeSafe() {
        var EPS = 0.000001;
        var tooLow = 0.0;
        var tooHigh = Math.PI;
        var justRight = 1.5;
        var a = new Spherical(1, tooLow, 0);

        a.makeSafe();
        TestCase.assertEquals(a.phi, EPS);

        a.set(1, tooHigh, 0);
        a.makeSafe();
        TestCase.assertEquals(a.phi, Math.PI - EPS);

        a.set(1, justRight, 0);
        a.makeSafe();
        TestCase.assertEquals(a.phi, justRight);
    }

    function testSetFromVector3() {
        var a = new Spherical(1, 1, 1);
        var b = new Vector3(0, 0, 0);
        var c = new Vector3(Math.PI, 1, -Math.PI);
        var expected = new Spherical(4.554032147688322, 1.3494066171539107, 2.356194490192345);

        a.setFromVector3(b);
        TestCase.assertEquals(a.radius, 0.0);
        TestCase.assertEquals(a.phi, 0.0);
        TestCase.assertEquals(a.theta, 0.0);

        a.setFromVector3(c);
        TestCase.assertTrue(Math.abs(a.radius - expected.radius) <= MathConstants.EPS);
        TestCase.assertTrue(Math.abs(a.phi - expected.phi) <= MathConstants.EPS);
        TestCase.assertTrue(Math.abs(a.theta - expected.theta) <= MathConstants.EPS);
    }

    function testSetFromCartesianCoords() {
        var a = new Spherical(1, 1, 1);
        var expected = new Spherical(4.554032147688322, 1.3494066171539107, 2.356194490192345);

        a.setFromCartesianCoords(0, 0, 0);
        TestCase.assertEquals(a.radius, 0.0);
        TestCase.assertEquals(a.phi, 0.0);
        TestCase.assertEquals(a.theta, 0.0);

        a.setFromCartesianCoords(Math.PI, 1, -Math.PI);
        TestCase.assertTrue(Math.abs(a.radius - expected.radius) <= MathConstants.EPS);
        TestCase.assertTrue(Math.abs(a.phi - expected.phi) <= MathConstants.EPS);
        TestCase.assertTrue(Math.abs(a.theta - expected.theta) <= MathConstants.EPS);
    }
}