package three.math;

import haxe.unit.TestCase;
import three.math.Cylindrical;
import three.math.Vector3;
import three.utils.MathConstants;

class CylindricalTests {

    public static function new() {}

    public static function main() {
        TestCase.createTestSuite(CylindricalTests);
    }

    public function testInstancing() {
        var a = new Cylindrical();
        var radius = 10.0;
        var theta = Math.PI;
        var y = 5.0;

        assertEquals(a.radius, 1.0, 'Default values: check radius');
        assertEquals(a.theta, 0.0, 'Default values: check theta');
        assertEquals(a.y, 0.0, 'Default values: check y');

        a = new Cylindrical(radius, theta, y);
        assertEquals(a.radius, radius, 'Custom values: check radius');
        assertEquals(a.theta, theta, 'Custom values: check theta');
        assertEquals(a.y, y, 'Custom values: check y');
    }

    public function testSet() {
        var a = new Cylindrical();
        var radius = 10.0;
        var theta = Math.PI;
        var y = 5.0;

        a.set(radius, theta, y);
        assertEquals(a.radius, radius, 'Check radius');
        assertEquals(a.theta, theta, 'Check theta');
        assertEquals(a.y, y, 'Check y');
    }

    public function testClone() {
        var radius = 10.0;
        var theta = Math.PI;
        var y = 5.0;
        var a = new Cylindrical(radius, theta, y);
        var b = a.clone();

        assertDeepEquals(a, b, 'Check a and b are equal after clone()');

        a.radius = 1;
        assertNotEquals(a, b, 'Check a and b are not equal after modification');
    }

    public function testCopy() {
        var radius = 10.0;
        var theta = Math.PI;
        var y = 5.0;
        var a = new Cylindrical(radius, theta, y);
        var b = new Cylindrical().copy(a);

        assertDeepEquals(a, b, 'Check a and b are equal after copy()');

        a.radius = 1;
        assertNotEquals(a, b, 'Check a and b are not equal after modification');
    }

    public function testSetFromVector3() {
        var a = new Cylindrical(1, 1, 1);
        var b = new Vector3(0, 0, 0);
        var c = new Vector3(3, -1, -3);
        var expected = new Cylindrical(Math.sqrt(9 + 9), Math.atan2(3, -3), -1);

        a.setFromVector3(b);
        assertEquals(a.radius, 0, 'Zero-length vector: check radius');
        assertEquals(a.theta, 0, 'Zero-length vector: check theta');
        assertEquals(a.y, 0, 'Zero-length vector: check y');

        a.setFromVector3(c);
        assertTrue(Math.abs(a.radius - expected.radius) <= MathConstants.EPSILON, 'Normal vector: check radius');
        assertTrue(Math.abs(a.theta - expected.theta) <= MathConstants.EPSILON, 'Normal vector: check theta');
        assertTrue(Math.abs(a.y - expected.y) <= MathConstants.EPSILON, 'Normal vector: check y');
    }

    public function testSetFromCartesianCoords() {
        // TODO: implement me!
        assertTrue(false, 'everything\'s gonna be alright');
    }

}