package;

import js.QUnit;
import js.extras.curves.LineCurve;
import js.extras.core.Curve;
import js.math.Vector2;

class _Main {
    static function main() {
        QUnit.module('Extras', function() {
            QUnit.module('Curves', function() {
                QUnit.module('LineCurve', function(hooks) {
                    var _points:Array<Vector2> = [];
                    var _curve:LineCurve = null;

                    hooks.before(function() {
                        _points = [
                            new Vector2(0, 0),
                            new Vector2(10, 10),
                            new Vector2(-10, 10),
                            new Vector2(-8, 5)
                        ];

                        _curve = new LineCurve(_points[0], _points[1]);
                    });

                    // INHERITANCE
                    QUnit.test('Extending', function(assert) {
                        var object = new LineCurve();
                        assert.strictEqual(object instanceof Curve, true, 'LineCurve extends from Curve');
                    });

                    // INSTANCING
                    QUnit.test('Instancing', function(assert) {
                        var object = new LineCurve();
                        assert.ok(object, 'Can instantiate a LineCurve.');
                    });

                    // PROPERTIES
                    QUnit.test('type', function(assert) {
                        var object = new LineCurve();
                        assert.ok(object.type == 'LineCurve', 'LineCurve.type should be LineCurve');
                    });

                    QUnit.todo('v1', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('v2', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    // PUBLIC
                    QUnit.test('isLineCurve', function(assert) {
                        var object = new LineCurve();
                        assert.ok(object.isLineCurve, 'LineCurve.isLineCurve should be true');
                    });

                    QUnit.todo('getPoint', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.test('getPointAt', function(assert) {
                        var curve = new LineCurve(_points[0], _points[3]);

                        var expectedPoints = [
                            new Vector2(0, 0),
                            new Vector2(-2.4, 1.5),
                            new Vector2(-4, 2.5),
                            new Vector2(-8, 5)
                        ];

                        var points = [
                            curve.getPointAt(0, new Vector2()),
                            curve.getPointAt(0.3, new Vector2()),
                            curve.getPointAt(0.5, new Vector2()),
                            curve.getPointAt(1, new Vector2())
                        ];

                        assert.deepEqual(points, expectedPoints, 'Correct points');
                    });

                    QUnit.test('getTangent/getTangentAt', function(assert) {
                        var curve = _curve;
                        var tangent = new Vector2();

                        curve.getTangent(0, tangent);
                        var expectedTangent = Math.sqrt(0.5);

                        assert.numEqual(tangent.x, expectedTangent, 'tangent.x correct');
                        assert.numEqual(tangent.y, expectedTangent, 'tangent.y correct');

                        curve.getTangentAt(0, tangent);

                        assert.numEqual(tangent.x, expectedTangent, 'tangentAt.x correct');
                        assert.numEqual(tangent.y, expectedTangent, 'tangentAt.y correct');
                    });

                    QUnit.todo('copy', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('toJSON', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnit.todo('fromJSON', function(assert) {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    // OTHERS
                    QUnit.test('Simple curve', function(assert) {
                        var curve = _curve;

                        var expectedPoints = [
                            new Vector2(0, 0),
                            new Vector2(2, 2),
                            new Vector2(4, 4),
                            new Vector2(6, 6),
                            new Vector2(8, 8),
                            new Vector2(10, 10)
                        ];

                        var points = curve.getPoints();

                        assert.deepEqual(points, expectedPoints, 'Correct points for first curve');

                        //

                        curve = new LineCurve(_points[1], _points[2]);

                        expectedPoints = [
                            new Vector2(10, 10),
                            new Vector2(6, 10),
                            new Vector2(2, 10),
                            new Vector2(-2, 10),
                            new Vector2(-6, 10),
                            new Vector2(-10, 10)
                        ];

                        points = curve.getPoints();

                        assert.deepEqual(points, expectedPoints, 'Correct points for second curve');
                    });

                    QUnit.test('getLength/getLengths', function(assert) {
                        var curve = _curve;

                        var length = curve.getLength();
                        var expectedLength = Math.sqrt(200);

                        assert.numEqual(length, expectedLength, 'Correct length of curve');

                        var lengths = curve.getLengths(5);
                        var expectedLengths = [
                            0.0,
                            Math.sqrt(8),
                            Math.sqrt(32),
                            Math.sqrt(72),
                            Math.sqrt(128),
                            Math.sqrt(200)
                        ];

                        assert.strictEqual(lengths.length, expectedLengths.length, 'Correct number of segments');

                        for (i in 0...lengths.length) {
                            assert.numEqual(lengths[i], expectedLengths[i], 'segment[' + i + '] correct');
                        }
                    });

                    QUnit.test('getUtoTmapping', function(assert) {
                        var curve = _curve;

                        var start = curve.getUtoTmapping(0, 0);
                        var end = curve.getUtoTmapping(0, curve.getLength());
                        var somewhere = curve.getUtoTmapping(0.3, 0);

                        assert.strictEqual(start, 0, 'getUtoTmapping( 0, 0 ) is the starting point');
                        assert.strictEqual(end, 1, 'getUtoTmapping( 0, length ) is the ending point');
                        assert.numEqual(somewhere, 0.3, 'getUtoTmapping( 0.3, 0 ) is correct');
                    });

                    QUnit.test('getSpacedPoints', function(assert) {
                        var curve = _curve;

                        var expectedPoints = [
                            new Vector2(0, 0),
                            new Vector2(2.5, 2.5),
                            new Vector2(5, 5),
                            new Vector2(7.5, 7.5),
                            new Vector2(10, 10)
                        ];

                        var points = curve.getSpacedPoints(4);

                        assert.strictEqual(points.length, expectedPoints.length, 'Correct number of points');
                        assert.deepEqual(points, expectedPoints, 'Correct points calculated');
                    });
                });
            });
        });
    }
}