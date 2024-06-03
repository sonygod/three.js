import three.math.Spherical;
import three.math.Vector3;

class SphericalTests {
    public function new() {
        testInstancing();
        testSet();
        testClone();
        testCopy();
        testMakeSafe();
        testSetFromVector3();
        testSetFromCartesianCoords();
    }

    private function testInstancing():Void {
        var a = new Spherical();
        var radius = 10.0;
        var phi = Math.acos(-0.5);
        var theta = Math.sqrt(Math.PI) * phi;

        haxe.unit.Assert.equals(a.radius, 1.0, 'Default values: check radius');
        haxe.unit.Assert.equals(a.phi, 0, 'Default values: check phi');
        haxe.unit.Assert.equals(a.theta, 0, 'Default values: check theta');

        a = new Spherical(radius, phi, theta);
        haxe.unit.Assert.equals(a.radius, radius, 'Custom values: check radius');
        haxe.unit.Assert.equals(a.phi, phi, 'Custom values: check phi');
        haxe.unit.Assert.equals(a.theta, theta, 'Custom values: check theta');
    }

    private function testSet():Void {
        var a = new Spherical();
        var radius = 10.0;
        var phi = Math.acos(-0.5);
        var theta = Math.sqrt(Math.PI) * phi;

        a.set(radius, phi, theta);
        haxe.unit.Assert.equals(a.radius, radius, 'Check radius');
        haxe.unit.Assert.equals(a.phi, phi, 'Check phi');
        haxe.unit.Assert.equals(a.theta, theta, 'Check theta');
    }

    private function testClone():Void {
        var radius = 10.0;
        var phi = Math.acos(-0.5);
        var theta = Math.sqrt(Math.PI) * phi;
        var a = new Spherical(radius, phi, theta);
        var b = a.clone();

        haxe.unit.Assert.isTrue(a == b, 'Check a and b are equal after clone()');

        a.radius = 2.0;
        haxe.unit.Assert.isFalse(a == b, 'Check a and b are not equal after modification');
    }

    private function testCopy():Void {
        var radius = 10.0;
        var phi = Math.acos(-0.5);
        var theta = Math.sqrt(Math.PI) * phi;
        var a = new Spherical(radius, phi, theta);
        var b = new Spherical().copy(a);

        haxe.unit.Assert.isTrue(a == b, 'Check a and b are equal after copy()');

        a.radius = 2.0;
        haxe.unit.Assert.isFalse(a == b, 'Check a and b are not equal after modification');
    }

    private function testMakeSafe():Void {
        var EPS = 0.000001;
        var tooLow = 0.0;
        var tooHigh = Math.PI;
        var justRight = 1.5;
        var a = new Spherical(1, tooLow, 0);

        a.makeSafe();
        haxe.unit.Assert.equals(a.phi, EPS, 'Check if small values are set to EPS');

        a.set(1, tooHigh, 0);
        a.makeSafe();
        haxe.unit.Assert.equals(a.phi, Math.PI - EPS, 'Check if high values are set to (Math.PI - EPS)');

        a.set(1, justRight, 0);
        a.makeSafe();
        haxe.unit.Assert.equals(a.phi, justRight, 'Check that valid values don\'t get changed');
    }

    private function testSetFromVector3():Void {
        var a = new Spherical(1, 1, 1);
        var b = new Vector3(0, 0, 0);
        var c = new Vector3(Math.PI, 1, -Math.PI);
        var expected = new Spherical(4.554032147688322, 1.3494066171539107, 2.356194490192345);

        a.setFromVector3(b);
        haxe.unit.Assert.equals(a.radius, 0, 'Zero-length vector: check radius');
        haxe.unit.Assert.equals(a.phi, 0, 'Zero-length vector: check phi');
        haxe.unit.Assert.equals(a.theta, 0, 'Zero-length vector: check theta');

        a.setFromVector3(c);
        haxe.unit.Assert.isTrue(Math.abs(a.radius - expected.radius) <= eps, 'Normal vector: check radius');
        haxe.unit.Assert.isTrue(Math.abs(a.phi - expected.phi) <= eps, 'Normal vector: check phi');
        haxe.unit.Assert.isTrue(Math.abs(a.theta - expected.theta) <= eps, 'Normal vector: check theta');
    }

    private function testSetFromCartesianCoords():Void {
        var a = new Spherical(1, 1, 1);
        var expected = new Spherical(4.554032147688322, 1.3494066171539107, 2.356194490192345);

        a.setFromCartesianCoords(0, 0, 0);
        haxe.unit.Assert.equals(a.radius, 0, 'Zero-length vector: check radius');
        haxe.unit.Assert.equals(a.phi, 0, 'Zero-length vector: check phi');
        haxe.unit.Assert.equals(a.theta, 0, 'Zero-length vector: check theta');

        a.setFromCartesianCoords(Math.PI, 1, -Math.PI);
        haxe.unit.Assert.isTrue(Math.abs(a.radius - expected.radius) <= eps, 'Normal vector: check radius');
        haxe.unit.Assert.isTrue(Math.abs(a.phi - expected.phi) <= eps, 'Normal vector: check phi');
        haxe.unit.Assert.isTrue(Math.abs(a.theta - expected.theta) <= eps, 'Normal vector: check theta');
    }
}