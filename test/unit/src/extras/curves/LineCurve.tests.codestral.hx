import qunit.QUnit;
import three.extras.curves.LineCurve;
import three.extras.core.Curve;
import three.math.Vector2;

class LineCurveTests {

    var _points:Array<Vector2> = [];
    var _curve:LineCurve;

    public function new() {
        QUnit.module("Extras", () -> {
            QUnit.module("Curves", () -> {
                QUnit.module("LineCurve", () -> {
                    this.setup();
                    this.testExtending();
                    this.testInstancing();
                    this.testType();
                    this.testIsLineCurve();
                    this.testGetPointAt();
                    this.testGetTangent();
                    this.testSimpleCurve();
                    this.testGetLength();
                    this.testGetUtoTmapping();
                    this.testGetSpacedPoints();
                });
            });
        });
    }

    private function setup():Void {
        _points = [
            new Vector2(0, 0),
            new Vector2(10, 10),
            new Vector2(-10, 10),
            new Vector2(-8, 5)
        ];

        _curve = new LineCurve(_points[0], _points[1]);
    }

    private function testExtending():Void {
        QUnit.test("Extending", (assert) -> {
            var object = new LineCurve();
            assert.strictEqual(Std.is(object, Curve), true, 'LineCurve extends from Curve');
        });
    }

    private function testInstancing():Void {
        QUnit.test("Instancing", (assert) -> {
            var object = new LineCurve();
            assert.notEqual(object, null, 'Can instantiate a LineCurve.');
        });
    }

    private function testType():Void {
        QUnit.test("type", (assert) -> {
            var object = new LineCurve();
            assert.equal(object.type, 'LineCurve', 'LineCurve.type should be LineCurve');
        });
    }

    private function testIsLineCurve():Void {
        QUnit.test("isLineCurve", (assert) -> {
            var object = new LineCurve();
            assert.isTrue(object.isLineCurve, 'LineCurve.isLineCurve should be true');
        });
    }

    private function testGetPointAt():Void {
        QUnit.test("getPointAt", (assert) -> {
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
    }

    private function testGetTangent():Void {
        QUnit.test("getTangent/getTangentAt", (assert) -> {
            var curve = _curve;
            var tangent = new Vector2();

            curve.getTangent(0, tangent);
            var expectedTangent = Math.sqrt(0.5);

            assert.equal(tangent.x, expectedTangent, 'tangent.x correct');
            assert.equal(tangent.y, expectedTangent, 'tangent.y correct');

            curve.getTangentAt(0, tangent);

            assert.equal(tangent.x, expectedTangent, 'tangentAt.x correct');
            assert.equal(tangent.y, expectedTangent, 'tangentAt.y correct');
        });
    }

    private function testSimpleCurve():Void {
        QUnit.test("Simple curve", (assert) -> {
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
    }

    private function testGetLength():Void {
        QUnit.test("getLength/getLengths", (assert) -> {
            var curve = _curve;

            var length = curve.getLength();
            var expectedLength = Math.sqrt(200);

            assert.equal(length, expectedLength, 'Correct length of curve');

            var lengths = curve.getLengths(5);
            var expectedLengths = [
                0.0,
                Math.sqrt(8),
                Math.sqrt(32),
                Math.sqrt(72),
                Math.sqrt(128),
                Math.sqrt(200)
            ];

            assert.equal(lengths.length, expectedLengths.length, 'Correct number of segments');

            for (i in 0...lengths.length) {
                assert.equal(lengths[i], expectedLengths[i], 'segment[' + i + '] correct');
            }
        });
    }

    private function testGetUtoTmapping():Void {
        QUnit.test("getUtoTmapping", (assert) -> {
            var curve = _curve;

            var start = curve.getUtoTmapping(0, 0);
            var end = curve.getUtoTmapping(0, curve.getLength());
            var somewhere = curve.getUtoTmapping(0.3, 0);

            assert.equal(start, 0, 'getUtoTmapping(0, 0) is the starting point');
            assert.equal(end, 1, 'getUtoTmapping(0, length) is the ending point');
            assert.equal(somewhere, 0.3, 'getUtoTmapping(0.3, 0) is correct');
        });
    }

    private function testGetSpacedPoints():Void {
        QUnit.test("getSpacedPoints", (assert) -> {
            var curve = _curve;

            var expectedPoints = [
                new Vector2(0, 0),
                new Vector2(2.5, 2.5),
                new Vector2(5, 5),
                new Vector2(7.5, 7.5),
                new Vector2(10, 10)
            ];

            var points = curve.getSpacedPoints(4);

            assert.equal(points.length, expectedPoints.length, 'Correct number of points');
            assert.deepEqual(points, expectedPoints, 'Correct points calculated');
        });
    }
}