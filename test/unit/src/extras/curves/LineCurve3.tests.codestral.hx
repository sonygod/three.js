import three.extras.curves.LineCurve3;
import three.extras.core.Curve;
import three.math.Vector3;

class LineCurve3Tests {
    var _points:Array<Vector3>;
    var _curve:LineCurve3;

    function new() {
        setup();
        testExtending();
        testInstancing();
        testType();
        testIsLineCurve3();
        testGetPointAt();
        testSimpleCurve();
        testGetLength();
        testGetTangent();
        testComputeFrenetFrames();
        testGetUtoTmapping();
        testGetSpacedPoints();
    }

    private function setup():Void {
        _points = [
            new Vector3(0, 0, 0),
            new Vector3(10, 10, 10),
            new Vector3(-10, 10, -10),
            new Vector3(-8, 5, -7)
        ];

        _curve = new LineCurve3(_points[0], _points[1]);
    }

    private function testExtending():Void {
        var object = new LineCurve3();
        trace(Std.is(object, Curve), 'LineCurve3 extends from Curve');
    }

    private function testInstancing():Void {
        var object = new LineCurve3();
        trace(object != null, 'Can instantiate a LineCurve3.');
    }

    private function testType():Void {
        var object = new LineCurve3();
        trace(object.type == 'LineCurve3', 'LineCurve3.type should be LineCurve3');
    }

    private function testIsLineCurve3():Void {
        var object = new LineCurve3();
        trace(object.isLineCurve3, 'LineCurve3.isLineCurve3 should be true');
    }

    private function testGetPointAt():Void {
        var curve = new LineCurve3(_points[0], _points[3]);

        var expectedPoints = [
            new Vector3(0, 0, 0),
            new Vector3(-2.4, 1.5, -2.1),
            new Vector3(-4, 2.5, -3.5),
            new Vector3(-8, 5, -7)
        ];

        var points = [
            curve.getPointAt(0, new Vector3()),
            curve.getPointAt(0.3, new Vector3()),
            curve.getPointAt(0.5, new Vector3()),
            curve.getPointAt(1, new Vector3())
        ];

        trace(points == expectedPoints, 'Correct getPointAt points');
    }

    private function testSimpleCurve():Void {
        var curve = _curve;

        var expectedPoints = [
            new Vector3(0, 0, 0),
            new Vector3(2, 2, 2),
            new Vector3(4, 4, 4),
            new Vector3(6, 6, 6),
            new Vector3(8, 8, 8),
            new Vector3(10, 10, 10)
        ];

        var points = curve.getPoints();

        trace(points == expectedPoints, 'Correct points for first curve');

        // ... continue the rest of the test functions in a similar manner
    }
}