import haxe.unit.TestCase;
import three.math.Spherical;
import three.math.Vector3;
import TestUtils;

class SphericalTest {
    public function new() {}

    public function testInstancing():Void {
        var a:Spherical = new Spherical();
        var radius:Float = 10.0;
        var phi:Float = Math.acos(-0.5);
        var theta:Float = Math.sqrt(Math.PI) * phi;

        assertEquals(a.radius, 1.0, 'Default values: check radius');
        assertEquals(a.phi, 0, 'Default values: check phi');
        assertEquals(a.theta, 0, 'Default values: check theta');

        a = new Spherical(radius, phi, theta);
        assertEquals(a.radius, radius, 'Custom values: check radius');
        assertEquals(a.phi, phi, 'Custom values: check phi');
        assertEquals(a.theta, theta, 'Custom values: check theta');
    }

    public function testSet():Void {
        var a:Spherical = new Spherical();
        var radius:Float = 10.0;
        var phi:Float = Math.acos(-0.5);
        var theta:Float = Math.sqrt(Math.PI) * phi;

        a.set(radius, phi, theta);
        assertEquals(a.radius, radius, 'Check radius');
        assertEquals(a.phi, phi, 'Check phi');
        assertEquals(a.theta, theta, 'Check theta');
    }

    public function testClone():Void {
        var radius:Float = 10.0;
        var phi:Float = Math.acos(-0.5);
        var theta:Float = Math.sqrt(Math.PI) * phi;
        var a:Spherical = new Spherical(radius, phi, theta);
        var b:Spherical = a.clone();

        assertEqual(a, b, 'Check a and b are equal after clone()');

        a.radius = 2.0;
        assertNotEqual(a, b, 'Check a and b are not equal after modification');
    }

    public function testCopy():Void {
        var radius:Float = 10.0;
        var phi:Float = Math.acos(-0.5);
        var theta:Float = Math.sqrt(Math.PI) * phi;
        var a:Spherical = new Spherical(radius, phi, theta);
        var b:Spherical = new Spherical().copy(a);

        assertEqual(a, b, 'Check a and b are equal after copy()');

        a.radius = 2.0;
        assertNotEqual(a, b, 'Check a and b are not equal after modification');
    }

    public function testMakeSafe():Void {
        var EPS:Float = 0.000001;
        var tooLow:Float = 0.0;
        var tooHigh:Float = Math.PI;
        var justRight:Float = 1.5;
        var a:Spherical = new Spherical(1, tooLow, 0);

        a.makeSafe();
        assertEquals(a.phi, EPS, 'Check if small values are set to EPS');

        a.set(1, tooHigh, 0);
        a.makeSafe();
        assertEquals(a.phi, Math.PI - EPS, 'Check if high values are set to (Math.PI - EPS)');

        a.set(1, justRight, 0);
        a.makeSafe();
        assertEquals(a.phi, justRight, 'Check that valid values don\'t get changed');
    }

    public function testSetFromVector3():Void {
        var a:Spherical = new Spherical(1, 1, 1);
        var b:Vector3 = new Vector3(0, 0, 0);
        var c:Vector3 = new Vector3(Math.PI, 1, -Math.PI);
        var expected:Spherical = new Spherical(4.554032147688322, 1.3494066171539107, 2.356194490192345);

        a.setFromVector3(b);
        assertEquals(a.radius, 0, 'Zero-length vector: check radius');
        assertEquals(a.phi, 0, 'Zero-length vector: check phi');
        assertEquals(a.theta, 0, 'Zero-length vector: check theta');

        a.setFromVector3(c);
        assertTrue(Math.abs(a.radius - expected.radius) <= eps, 'Normal vector: check radius');
        assertTrue(Math.abs(a.phi - expected.phi) <= eps, 'Normal vector: check phi');
        assertTrue(Math.abs(a.theta - expected.theta) <= eps, 'Normal vector: check theta');
    }

    public function testSetFromCartesianCoords():Void {
        var a:Spherical = new Spherical(1, 1, 1);
        var expected:Spherical = new Spherical(4.554032147688322, 1.3494066171539107, 2.356194490192345);

        a.setFromCartesianCoords(0, 0, 0);
        assertEquals(a.radius, 0, 'Zero-length vector: check radius');
        assertEquals(a.phi, 0, 'Zero-length vector: check phi');
        assertEquals(a.theta, 0, 'Zero-length vector: check theta');

        a.setFromCartesianCoords(Math.PI, 1, -Math.PI);
        assertTrue(Math.abs(a.radius - expected.radius) <= eps, 'Normal vector: check radius');
        assertTrue(Math.abs(a.phi - expected.phi) <= eps, 'Normal vector: check phi');
        assertTrue(Math.abs(a.theta - expected.theta) <= eps, 'Normal vector: check theta');
    }
}