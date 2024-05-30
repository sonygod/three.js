package three.js.test.unit.src.extras.curves;

import three.js.extras.curves.CubicBezierCurve;
import three.js.extras.core.Curve;
import three.js.math.Vector2;

class CubicBezierCurveTests {

    public function new() {}

    public static function main() {
        // Note: QUnit is not a standard library in Haxe, so we'll use a generic test framework
        // Assume we have a test framework with a `testCase` function
        testCase("Extras.Curves.CubicBezierCurve", function() {

            var curve:CubicBezierCurve;

            before(function() {
                curve = new CubicBezierCurve(
                    new Vector2(-10, 0),
                    new Vector2(-5, 15),
                    new Vector2(20, 15),
                    new Vector2(10, 0)
                );
            });

            // INHERITANCE
            test("Extending", function(assert) {
                var object = new CubicBezierCurve();
                assert.isTrue(object instanceof Curve, 'CubicBezierCurve extends from Curve');
            });

            // INSTANCING
            test("Instancing", function(assert) {
                var object = new CubicBezierCurve();
                assert.notNull(object, 'Can instantiate a CubicBezierCurve.');
            });

            // PROPERTIES
            test("type", function(assert) {
                var object = new CubicBezierCurve();
                assert.equal(object.type, 'CubicBezierCurve', 'CubicBezierCurve.type should be CubicBezierCurve');
            });

            // todo: implement tests for v0, v1, v2, v3

            // PUBLIC
            test("isCubicBezierCurve", function(assert) {
                var object = new CubicBezierCurve();
                assert.isTrue(object.isCubicBezierCurve, 'CubicBezierCurve.isCubicBezierCurve should be true');
            });

            // todo: implement tests for getPoint, copy, toJSON, fromJSON

            // OTHERS
            test("Simple curve", function(assert) {
                var expectedPoints = [
                    new Vector2(-10, 0),
                    new Vector2(-3.359375, 8.4375),
                    new Vector2(5.625, 11.25),
                    new Vector2(11.796875, 8.4375),
                    new Vector2(10, 0)
                ];

                var points = curve.getPoints(expectedPoints.length - 1);

                assert.equal(points.length, expectedPoints.length, 'Correct number of points');
                assert.deepEqual(points, expectedPoints, 'Correct points calculated');

                // symmetry
                var curveRev = new CubicBezierCurve(curve.v3, curve.v2, curve.v1, curve.v0);

                points = curveRev.getPoints(expectedPoints.length - 1);

                assert.equal(points.length, expectedPoints.length, 'Reversed: Correct number of points');
                assert.deepEqual(points, expectedPoints.reverse(), 'Reversed: Correct points curve');
            });

            test("getLength/getLengths", function(assert) {
                var length = curve.getLength();
                var expectedLength = 36.64630888504102;

                assert.numEqual(length, expectedLength, 'Correct length of curve');

                var expectedLengths = [
                    0,
                    10.737285813492393,
                    20.15159143794633,
                    26.93408340370825,
                    35.56079575637337
                ];
                var lengths = curve.getLengths(expectedLengths.length - 1);

                assert.equal(lengths.length, expectedLengths.length, 'Correct number of segments');

                for (i in 0...lengths.length) {
                    assert.numEqual(lengths[i], expectedLengths[i], 'segment[' + i + '] correct');
                }
            });

            test("getPointAt", function(assert) {
                var expectedPoints = [
                    new Vector2(-10, 0),
                    new Vector2(-3.3188282598022596, 8.463722639089221),
                    new Vector2(3.4718554735926617, 11.07899406116314),
                    new Vector2(10, 0)
                ];

                var points = [
                    curve.getPointAt(0, new Vector2()),
                    curve.getPointAt(0.3, new Vector2()),
                    curve.getPointAt(0.5, new Vector2()),
                    curve.getPointAt(1, new Vector2())
                ];

                assert.deepEqual(points, expectedPoints, 'Correct points');
            });

            test("getTangent/getTangentAt", function(assert) {
                // todo: implement tests for getTangent and getTangentAt
            });

            test("getUtoTmapping", function(assert) {
                var start = curve.getUtoTmapping(0, 0);
                var end = curve.getUtoTmapping(0, curve.getLength());
                var somewhere = curve.getUtoTmapping(0.5, 1);

                var expectedSomewhere = 0.02130029182257093;

                assert.equal(start, 0, 'getUtoTmapping( 0, 0 ) is the starting point');
                assert.equal(end, 1, 'getUtoTmapping( 0, length ) is the ending point');
                assert.numEqual(somewhere, expectedSomewhere, 'getUtoTmapping( 0.5, 1 ) is correct');
            });

            test("getSpacedPoints", function(assert) {
                var expectedPoints = [
                    new Vector2(-10, 0),
                    new Vector2(-6.16826457740703, 6.17025727295411),
                    new Vector2(-0.058874033259857184, 10.1240558653185),
                    new Vector2(7.123523032625162, 11.154913869041575),
                    new Vector2(12.301846885754463, 6.808865855469985),
                    new Vector2(10, 0)
                ];

                var points = curve.getSpacedPoints();

                assert.equal(points.length, expectedPoints.length, 'Correct number of points');
                assert.deepEqual(points, expectedPoints, 'Correct points calculated');
            });
        });
    }
}