import js.Browser.window;
import js.Browser.document;

import js.three.extras.curves.LineCurve3;
import js.three.extras.core.Curve;
import js.three.math.Vector3;

class TestLineCurve3 {
    static function main() {
        var qunit = window.QUnit;
        qunit.module('Extras', function () {
            qunit.module('Curves', function () {
                qunit.module('LineCurve3', function () {
                    var _points = [];
                    var _curve = null;

                    function before() {
                        _points = [
                            new Vector3(0, 0, 0),
                            new Vector3(10, 10, 10),
                            new Vector3(-10, 10, -10),
                            new Vector3(-8, 5, -7)
                        ];
                        _curve = new LineCurve3(_points[0], _points[1]);
                    }

                    // INHERITANCE
                    function testExtending() {
                        var object = new LineCurve3();
                        qunit.strictEqual(object instanceof Curve, true, 'LineCurve3 extends from Curve');
                    }

                    // INSTANCING
                    function testInstancing() {
                        var object = new LineCurve3();
                        qunit.ok(object, 'Can instantiate a LineCurve3.');
                    }

                    // PROPERTIES
                    function testType() {
                        var object = new LineCurve3();
                        qunit.ok(object.type == 'LineCurve3', 'LineCurve3.type should be LineCurve3');
                    }

                    // PUBLIC
                    function testIsLineCurve3() {
                        var object = new LineCurve3();
                        qunit.ok(object.isLineCurve3, 'LineCurve3.isLineCurve3 should be true');
                    }

                    function testGetPointAt() {
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
                        qunit.deepEqual(points, expectedPoints, 'Correct getPointAt points');
                    }

                    // OTHERS
                    function testSimpleCurve() {
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
                        qunit.deepEqual(points, expectedPoints, 'Correct points for first curve');

                        curve = new LineCurve3(_points[1], _points[2]);
                        expectedPoints = [
                            new Vector3(10, 10, 10),
                            new Vector3(6, 10, 6),
                            new Vector3(2, 10, 2),
                            new Vector3(-2, 10, -2),
                            new Vector3(-6, 10, -6),
                            new Vector3(-10, 10, -10)
                        ];
                        points = curve.getPoints();
                        qunit.deepEqual(points, expectedPoints, 'Correct points for second curve');
                    }

                    function testGetLengthAndGetLengths() {
                        var curve = _curve;
                        var length = curve.getLength();
                        var expectedLength = Math.sqrt(300);
                        qunit.numEqual(length, expectedLength, 'Correct length of curve');

                        var lengths = curve.getLengths(5);
                        var expectedLengths = [
                            0.0,
                            Math.sqrt(12),
                            Math.sqrt(48),
                            Math.sqrt(108),
                            Math.sqrt(192),
                            Math.sqrt(300)
                        ];
                        qunit.strictEqual(lengths.length, expectedLengths.length, 'Correct number of segments');

                        for (var i = 0; i < lengths.length; i++) {
                            qunit.numEqual(lengths[i], expectedLengths[i], 'segment[' + i + '] correct');
                        }
                    }

                    function testGetTangentAndGetTangentAt() {
                        var curve = _curve;
                        var tangent = new Vector3();
                        curve.getTangent(0.5, tangent);
                        var expectedTangent = Math.sqrt(1 / 3);
                        qunit.numEqual(tangent.x, expectedTangent, 'tangent.x correct');
                        qunit.numEqual(tangent.y, expectedTangent, 'tangent.y correct');
                        qunit.numEqual(tangent.z, expectedTangent, 'tangent.z correct');

                        tangent = curve.getTangentAt(0.5);
                        qunit.numEqual(tangent.x, expectedTangent, 'tangentAt.x correct');
                        qunit.numEqual(tangent.y, expectedTangent, 'tangentAt.y correct');
                        qunit.numEqual(tangent.z, expectedTangent, 'tangentAt.z correct');
                    }

                    function testComputeFrenetFrames() {
                        var curve = _curve;
                        var expected = {
                            binormals: new Vector3(-0.5 * Math.sqrt(2), 0.5 * Math.sqrt(2), 0),
                            normals: new Vector3(Math.sqrt(1 / 6), Math.sqrt(1 / 6), -Math.sqrt(2 / 3)),
                            tangents: new Vector3(Math.sqrt(1 / 3), Math.sqrt(1 / 3), Math.sqrt(1 / 3))
                        };
                        var frames = curve.computeFrenetFrames(1, false);

                        for (var val in expected) {
                            qunit.numEqual(frames[val][0].x, expected[val].x, 'Frenet frames ' + val + '.x correct');
                            qunit.numEqual(frames[val][0].y, expected[val].y, 'Frenet frames ' + val + '.y correct');
                            qunit.numEqual(frames[val][0].z, expected[val].z, 'Frenet frames ' + val + '.z correct');
                        }
                    }

                    function testGetUtoTmapping() {
                        var curve = _curve;
                        var start = curve.getUtoTmapping(0, 0);
                        var end = curve.getUtoTmapping(0, curve.getLength());
                        var somewhere = curve.getUtoTmapping(0.7, 0);
                        qunit.strictEqual(start, 0, 'getUtoTmapping( 0, 0 ) is the starting point');
                        qunit.strictEqual(end, 1, 'getUtoTmapping( 0, length ) is the ending point');
                        qunit.numEqual(somewhere, 0.7, 'getUtoTmapping( 0.7, 0 ) is correct');
                    }

                    function testGetSpacedPoints() {
                        var curve = _curve;
                        var expectedPoints = [
                            new Vector3(0, 0, 0),
                            new Vector3(2.5, 2.5, 2.5),
                            new Vector3(5, 5, 5),
                            new Vector3(7.5, 7.5, 7.5),
                            new Vector3(10, 10, 10)
                        ];
                        var points = curve.getSpacedPoints(4);
                        qunit.strictEqual(points.length, expectedPoints.length, 'Correct number of points');
                        qunit.deepEqual(points, expectedPoints, 'Correct points calculated');
                    }
                });
            });
        });
    }
}

TestLineCurve3.main();