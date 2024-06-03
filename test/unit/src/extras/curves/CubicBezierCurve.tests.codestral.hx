import three.extras.curves.CubicBezierCurve;
import three.extras.core.Curve;
import three.math.Vector2;

class CubicBezierCurveTests {
    public function new() {
        var curve:CubicBezierCurve = new CubicBezierCurve(
            new Vector2(-10, 0),
            new Vector2(-5, 15),
            new Vector2(20, 15),
            new Vector2(10, 0)
        );

        // INHERITANCE
        var object:CubicBezierCurve = new CubicBezierCurve();
        trace(Std.is(object, Curve), 'CubicBezierCurve extends from Curve');

        // INSTANCING
        var object:CubicBezierCurve = new CubicBezierCurve();
        trace(object != null, 'Can instantiate a CubicBezierCurve.');

        // PROPERTIES
        var object:CubicBezierCurve = new CubicBezierCurve();
        trace(object.type == 'CubicBezierCurve', 'CubicBezierCurve.type should be CubicBezierCurve');

        // TODO: v0, v1, v2, v3
        // Vector2 exists
        // trace(false, 'everything\'s gonna be alright');

        // PUBLIC
        var object:CubicBezierCurve = new CubicBezierCurve();
        trace(object.isCubicBezierCurve, 'CubicBezierCurve.isCubicBezierCurve should be true');

        // TODO: getPoint, copy, toJSON, fromJSON
        // trace(false, 'everything\'s gonna be alright');

        // OTHERS
        var expectedPoints:Array<Vector2> = [
            new Vector2(-10, 0),
            new Vector2(-3.359375, 8.4375),
            new Vector2(5.625, 11.25),
            new Vector2(11.796875, 8.4375),
            new Vector2(10, 0)
        ];

        var points:Array<Vector2> = curve.getPoints(expectedPoints.length - 1);

        trace(points.length == expectedPoints.length, 'Correct number of points');
        trace(points == expectedPoints, 'Correct points calculated');

        // symmetry
        var curveRev:CubicBezierCurve = new CubicBezierCurve(
            curve.v3, curve.v2, curve.v1, curve.v0
        );

        points = curveRev.getPoints(expectedPoints.length - 1);

        trace(points.length == expectedPoints.length, 'Reversed: Correct number of points');
        trace(points == expectedPoints.reverse(), 'Reversed: Correct points curve');

        var length:Float = curve.getLength();
        var expectedLength:Float = 36.64630888504102;

        trace(Math.abs(length - expectedLength) < 0.0001, 'Correct length of curve');

        var expectedLengths:Array<Float> = [
            0,
            10.737285813492393,
            20.15159143794633,
            26.93408340370825,
            35.56079575637337
        ];
        var lengths:Array<Float> = curve.getLengths(expectedLengths.length - 1);

        trace(lengths.length == expectedLengths.length, 'Correct number of segments');

        for (i in 0...lengths.length) {
            trace(Math.abs(lengths[i] - expectedLengths[i]) < 0.0001, 'segment[' + i + '] correct');
        }

        var expectedPoints:Array<Vector2> = [
            new Vector2(-10, 0),
            new Vector2(-3.3188282598022596, 8.463722639089221),
            new Vector2(3.4718554735926617, 11.07899406116314),
            new Vector2(10, 0)
        ];

        var points:Array<Vector2> = [
            curve.getPointAt(0, new Vector2()),
            curve.getPointAt(0.3, new Vector2()),
            curve.getPointAt(0.5, new Vector2()),
            curve.getPointAt(1, new Vector2())
        ];

        trace(points == expectedPoints, 'Correct points');

        var expectedTangents:Array<Vector2> = [
            new Vector2(0.316370061632252, 0.9486358543207215),
            new Vector2(0.838961283088303, 0.5441911111721949),
            new Vector2(1, 0),
            new Vector2(0.47628313192245453, -0.8792919755383518),
            new Vector2(-0.5546041767829665, -0.8321142992972107)
        ];

        var tangents:Array<Vector2> = [
            curve.getTangent(0, new Vector2()),
            curve.getTangent(0.25, new Vector2()),
            curve.getTangent(0.5, new Vector2()),
            curve.getTangent(0.75, new Vector2()),
            curve.getTangent(1, new Vector2())
        ];

        for (i in 0...tangents.length) {
            var tangent:Vector2 = tangents[i];
            var exp:Vector2 = expectedTangents[i];

            trace(Math.abs(tangent.x - exp.x) < 0.0001, 'getTangent #' + i + ': x correct');
            trace(Math.abs(tangent.y - exp.y) < 0.0001, 'getTangent #' + i + ': y correct');
        }

        //

        expectedTangents = [
            new Vector2(0.316370061632252, 0.9486358543207215),
            new Vector2(0.7794223085548987, 0.6264988945935596),
            new Vector2(0.988266153082452, 0.15274164681452052),
            new Vector2(0.5004110404199416, -0.8657879593906534),
            new Vector2(-0.5546041767829665, -0.8321142992972107)
        ];

        tangents = [
            curve.getTangentAt(0, new Vector2()),
            curve.getTangentAt(0.25, new Vector2()),
            curve.getTangentAt(0.5, new Vector2()),
            curve.getTangentAt(0.75, new Vector2()),
            curve.getTangentAt(1, new Vector2())
        ];

        for (i in 0...tangents.length) {
            var tangent:Vector2 = tangents[i];
            var exp:Vector2 = expectedTangents[i];

            trace(Math.abs(tangent.x - exp.x) < 0.0001, 'getTangentAt #' + i + ': x correct');
            trace(Math.abs(tangent.y - exp.y) < 0.0001, 'getTangentAt #' + i + ': y correct');
        }

        var start:Float = curve.getUtoTmapping(0, 0);
        var end:Float = curve.getUtoTmapping(0, curve.getLength());
        var somewhere:Float = curve.getUtoTmapping(0.5, 1);

        var expectedSomewhere:Float = 0.02130029182257093;

        trace(start == 0, 'getUtoTmapping( 0, 0 ) is the starting point');
        trace(end == 1, 'getUtoTmapping( 0, length ) is the ending point');
        trace(Math.abs(somewhere - expectedSomewhere) < 0.0001, 'getUtoTmapping( 0.5, 1 ) is correct');

        var expectedPoints:Array<Vector2> = [
            new Vector2(-10, 0),
            new Vector2(-6.16826457740703, 6.17025727295411),
            new Vector2(-0.058874033259857184, 10.1240558653185),
            new Vector2(7.123523032625162, 11.154913869041575),
            new Vector2(12.301846885754463, 6.808865855469985),
            new Vector2(10, 0)
        ];

        var points:Array<Vector2> = curve.getSpacedPoints();

        trace(points.length == expectedPoints.length, 'Correct number of points');
        trace(points == expectedPoints, 'Correct points calculated');
    }
}