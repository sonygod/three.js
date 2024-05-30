import js.QUnit;
import js.QuadraticBezierCurve;
import js.Curve;
import js.Vector2;

class QuadraticBezierCurveTest {
    static function main() {
        QUnit.module('Extras', function() {
            QUnit.module('Curves', function() {
                QUnit.module('QuadraticBezierCurve', function(hooks) {
                    var _curve:QuadraticBezierCurve;
                    hooks.before(function() {
                        _curve = new QuadraticBezierCurve(
                            new Vector2(-10, 0),
                            new Vector2(20, 15),
                            new Vector2(10, 0)
                        );
                    });

                    // INHERITANCE
                    function testExtending() {
                        var object = new QuadraticBezierCurve();
                        QUnit.strictEqual(
                            object instanceof Curve, true,
                            'QuadraticBezierCurve extends from Curve'
                        );
                    }

                    // INSTANCING
                    function testInstancing() {
                        var object = new QuadraticBezierCurve();
                        QUnit.ok(object, 'Can instantiate a QuadraticBezierCurve.');
                    }

                    // PROPERTIES
                    function testType() {
                        var object = new QuadraticBezierCurve();
                        QUnit.ok(
                            object.type == 'QuadraticBezierCurve',
                            'QuadraticBezierCurve.type should be QuadraticBezierCurve'
                        );
                    }

                    function testV0() {
                        // Vector2 exists
                        QUnit.ok(false, 'everything\'s gonna be alright');
                    }

                    function testV1() {
                        // Vector2 exists
                        QUnit.ok(false, 'everything\'s gonna be alright');
                    }

                    function testV2() {
                        // Vector2 exists
                        QUnit.ok(false, 'everything\'s gonna be alright');
                    }

                    // PUBLIC
                    function testIsQuadraticBezierCurve() {
                        var object = new QuadraticBezierCurve();
                        QUnit.ok(
                            object.isQuadraticBezierCurve,
                            'QuadraticBezierCurve.isQuadraticBezierCurve should be true'
                        );
                    }

                    function testGetPoint() {
                        QUnit.ok(false, 'everything\'s gonna be alright');
                    }

                    function testCopy() {
                        QUnit.ok(false, 'everything\'s gonna be alright');
                    }

                    function testToJSON() {
                        QUnit.ok(false, 'everything\'s gonna be alright');
                    }

                    function testFromJSON() {
                        QUnit.ok(false, 'everything\'s gonna be alright');
                    }

                    // OTHERS
                    function testSimpleCurve() {
                        var curve = _curve;
                        var expectedPoints = [
                            new Vector2(-10, 0),
                            new Vector2(2.5, 5.625),
                            new Vector2(10, 7.5),
                            new Vector2(12.5, 5.625),
                            new Vector2(10, 0)
                        ];
                        var points = curve.getPoints(expectedPoints.length - 1);
                        QUnit.strictEqual(points.length, expectedPoints.length, 'Correct number of points');
                        QUnit.deepEqual(points, expectedPoints, 'Correct points calculated');
                        // symmetry
                        var curveRev = new QuadraticBezierCurve(
                            curve.v2, curve.v1, curve.v0
                        );
                        points = curveRev.getPoints(expectedPoints.length - 1);
                        QUnit.strictEqual(points.length, expectedPoints.length, 'Reversed: Correct number of points');
                        QUnit.deepEqual(points, expectedPoints.reverse(), 'Reversed: Correct points curve');
                    }

                    function testGetLength_getLengths() {
                        var curve = _curve;
                        var length = curve.getLength();
                        var expectedLength = 31.269026549416683;
                        QUnit.numEqual(length, expectedLength, 'Correct length of curve');
                        var expectedLengths = [
                            0,
                            13.707320124663317,
                            21.43814317269643,
                            24.56314317269643,
                            30.718679298818998
                        ];
                        var lengths = curve.getLengths(expectedLengths.length - 1);
                        QUnit.strictEqual(lengths.length, expectedLengths.length, 'Correct number of segments');
                        for (var i = 0; i < lengths.length; i++) {
                            var segment = lengths[i];
                            var exp = expectedLengths[i];
                            QUnit.numEqual(segment, exp, 'segment[' + i + '] correct');
                        }
                    }

                    function testGetPointAt() {
                        var curve = _curve;
                        var expectedPoints = [
                            new Vector2(-10, 0),
                            new Vector2(-1.5127849599387615, 3.993582003773624),
                            new Vector2(4.310076165722796, 6.269921971403917),
                            new Vector2(10, 0)
                        ];
                        var points = [
                            curve.getPointAt(0, new Vector2()),
                            curve.getPointAt(0.3, new Vector2()),
                            curve.getPointAt(0.5, new Vector2()),
                            curve.getPointAt(1, new Vector2())
                        ];
                        QUnit.deepEqual(points, expectedPoints, 'Correct points');
                    }

                    function testGetTangent_getTangentAt() {
                        var curve = _curve;
                        var expectedTangents = [
                            new Vector2(0.89443315420562, 0.44720166888975904),
                            new Vector2(0.936329177569021, 0.3511234415884543),
                            new Vector2(1, 0),
                            new Vector2(-5.921189464667277e-13, -1),
                            new Vector2(-0.5546617882904897, -0.8320758983472577)
                        ];
                        var tangents = [
                            curve.getTangent(0, new Vector2()),
                            curve.getTangent(0.25, new Vector2()),
                            curve.getTangent(0.5, new Vector2()),
                            curve.getTangent(0.75, new Vector2()),
                            curve.getTangent(1, new Vector2())
                        ];
                        for (var i = 0; i < expectedTangents.length; i++) {
                            var exp = expectedTangents[i];
                            var tangent = tangents[i];
                            QUnit.numEqual(tangent.x, exp.x, 'getTangent #' + i + ': x correct');
                            QUnit.numEqual(tangent.y, exp.y, 'getTangent #' + i + ': y correct');
                        }
                        //
                        expectedTangents = [
                            new Vector2(0.89443315420562, 0.44720166888975904),
                            new Vector2(0.9125211423360805, 0.40902954024086674),
                            new Vector2(0.9480289098765387, 0.3181842014278863),
                            new Vector2(0.7969127189169473, -0.6040944615111106),
                            new Vector2(-0.5546617882904897, -0.8320758983472577)
                        ];
                        tangents = [
                            curve.getTangentAt(0, new Vector2()),
                            curve.getTangentAt(0.25, new Vector2()),
                            curve.getTangentAt(0.5, new Vector2()),
                            curve.getTangentAt(0.75, new Vector2()),
                            curve.getTangentAt(1, new Vector2())
                        ];
                        for (var i = 0; i < expectedTangents.length; i++) {
                            var exp = expectedTangents[i];
                            var tangent = tangents[i];
                            QUnit.numEqual(tangent.x, exp.x, 'getTangentAt #' + i + ': x correct');
                            QUnitUInt.numEqual(tangent.y, exp.y, 'getTangentAt #' + i + ': y correct');
                        }
                    }

                    function testGetUtoTmapping() {
                        var curve = _curve;
                        var start = curve.getUtoTmapping(0, 0);
                        var end = curve.getUtoTmapping(0, curve.getLength());
                        var somewhere = curve.getUtoTmapping(0.5, 1);
                        var expectedSomewhere = 0.015073978276116116;
                        QUnit.strictEqual(start, 0, 'getUtoTmapping( 0, 0 ) is the starting point');
                        QUnit.strictEqual(end, 1, 'getUtoTmapping( 0, length ) is the ending point');
                        QUnit.numEqual(somewhere, expectedSomewhere, 'getUtoTmapping( 0.5, 1 ) is correct');
                    }

                    function testGetSpacedPoints() {
                        var curve = _curve;
                        var expectedPoints = [
                            new Vector2(-10, 0),
                            new Vector2(-4.366603655406173, 2.715408933540383),
                            new Vector2(1.3752241477827831, 5.191972084404416),
                            new Vector2(7.312990279153634, 7.136310044848586),
                            new Vector2(12.499856644824826, 5.653289188715387),
                            new Vector2(10, 0)
                        ];
                        var points = curve.getSpacedPoints();
                        QUnit.strictEqual(points.length, expectedPoints.length, 'Correct number of points');
                        QUnit.deepEqual(points, expectedPoints, 'Correct points calculated');
                    }
                });
            });
        });
    }
}

QuadraticBezierCurveTest.main();