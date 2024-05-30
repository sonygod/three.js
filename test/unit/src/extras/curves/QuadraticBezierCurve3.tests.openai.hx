package three.test.unit.src.extras.curves;

import haxe.unit.TestCase;
import three.extras.curves.QuadraticBezierCurve3;
import three.math.Vector3;
import three.core.Curve;

class QuadraticBezierCurve3Test {
    var _curve:QuadraticBezierCurve3;

    public function new() {}

    public function testExtending():Void {
        var object = new QuadraticBezierCurve3();
        Assert.isTrue(Std.is(object, Curve), 'QuadraticBezierCurve3 extends from Curve');
    }

    public function testInstancing():Void {
        var object = new QuadraticBezierCurve3();
        Assert.notNull(object, 'Can instantiate a QuadraticBezierCurve3.');
    }

    public function testType():Void {
        var object = new QuadraticBezierCurve3();
        Assert.equals(object.type, 'QuadraticBezierCurve3', 'QuadraticBezierCurve3.type should be QuadraticBezierCurve3');
    }

    // ... other test functions ...

    public function testGetPointAt():Void {
        var curve = _curve;
        var expectedPoints = [
            new Vector3(-10, 0, 2),
            new Vector3(-0.4981634504454243, 4.427089043881476, 0.19308849757196012),
            new Vector3(6.149415812887238, 6.838853310980195, -0.20278120208668637),
            new Vector3(10, 0, 10)
        ];

        var points = [
            curve.getPointAt(0, new Vector3()),
            curve.getPointAt(0.3, new Vector3()),
            curve.getPointAt(0.5, new Vector3()),
            curve.getPointAt(1, new Vector3())
        ];

        Assert.deepEqual(points, expectedPoints, 'Correct points');
    }

    // ... other test functions ...
}

class TestAll {
    public static function main() {
        var testCase = new QuadraticBezierCurve3Test();
        testCase.testExtending();
        testCase.testInstancing();
        testCase.testType();
        // ... call other test functions ...
    }
}