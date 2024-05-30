package;

import utest.Assert;
import math.Cylindrical;
import math.Vector3;
import utils.MathConstants;

class CylindricalTests {

    public function new() {}

    public function testInstancing() {
        var a = new Cylindrical();
        var radius = 10.0;
        var theta = Math.PI;
        var y = 5;

        Assert.equals(1.0, a.radius);
        Assert.equals(0.0, a.theta);
        Assert.equals(0.0, a.y);

        a = new Cylindrical(radius, theta, y);
        Assert.equals(radius, a.radius);
        Assert.equals(theta, a.theta);
        Assert.equals(y, a.y);
    }

    public function testSet() {
        var a = new Cylindrical();
        var radius = 10.0;
        var theta = Math.PI;
        var y = 5;

        a.set(radius, theta, y);
        Assert.equals(radius, a.radius);
        Assert.equals(theta, a.theta);
        Assert.equals(y, a.y);
    }

    public function testClone() {
        var radius = 10.0;
        var theta = Math.PI;
        var y = 5;
        var a = new Cylindrical(radius, theta, y);
        var b = a.clone();

        Assert.equals(a, b);

        a.radius = 1;
        Assert.notEquals(a, b);
    }

    public function testCopy() {
        var radius = 10.0;
        var theta = Math.PI;
        var y = 5;
        var a = new Cylindrical(radius, theta, y);
        var b = new Cylindrical().copy(a);

        Assert.equals(a, b);

        a.radius = 1;
        Assert.notEquals(a, b);
    }

    public function testSetFromVector3() {
        var a = new Cylindrical(1, 1, 1);
        var b = new Vector3(0, 0, 0);
        var c = new Vector3(3, -1, -3);
        var expected = new Cylindrical(Math.sqrt(9 + 9), Math.atan2(3, -3), -1);

        a.setFromVector3(b);
        Assert.equals(0.0, a.radius);
        Assert.equals(0.0, a.theta);
        Assert.equals(0.0, a.y);

        a.setFromVector3(c);
        Assert.isTrue(Math.abs(a.radius - expected.radius) <= MathConstants.eps);
        Assert.isTrue(Math.abs(a.theta - expected.theta) <= MathConstants.eps);
        Assert.isTrue(Math.abs(a.y - expected.y) <= MathConstants.eps);
    }

    public function testSetFromCartesianCoords() {
        // todo implement me!
        Assert.fail("todo: implement setFromCartesianCoords");
    }

}