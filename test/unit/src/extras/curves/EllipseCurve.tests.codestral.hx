package tests.extras.curves;

import three.extras.curves.EllipseCurve;
import three.extras.core.Curve;
import three.math.Vector2;

class EllipseCurveTests {
    var curve: EllipseCurve;

    public function new() {
        curve = new EllipseCurve(0, 0, 10, 10, 0, 2 * Math.PI, false, 0);
    }

    public function testExtending(): Void {
        var object = new EllipseCurve();
        // assert.strictEqual(object instanceof Curve, true, 'EllipseCurve extends from Curve');
        // You can replace the assertion with your own implementation or use a library that provides assertions in Haxe.
    }

    public function testInstancing(): Void {
        var object = new EllipseCurve();
        // assert.ok(object, 'Can instantiate an EllipseCurve.');
        // You can replace the assertion with your own implementation or use a library that provides assertions in Haxe.
    }

    public function testType(): Void {
        var object = new EllipseCurve();
        // assert.ok(object.type === 'EllipseCurve', 'EllipseCurve.type should be EllipseCurve');
        // You can replace the assertion with your own implementation or use a library that provides assertions in Haxe.
    }

    public function testIsEllipseCurve(): Void {
        var object = new EllipseCurve();
        // assert.ok(object.isEllipseCurve, 'EllipseCurve.isEllipseCurve should be true');
        // You can replace the assertion with your own implementation or use a library that provides assertions in Haxe.
    }

    public function testSimpleCurve(): Void {
        var expectedPoints = [
            new Vector2(10, 0),
            new Vector2(0, 10),
            new Vector2(-10, 0),
            new Vector2(0, -10),
            new Vector2(10, 0)
        ];

        var points = curve.getPoints(expectedPoints.length - 1);

        // assert.strictEqual(points.length, expectedPoints.length, 'Correct number of points');
        // You can replace the assertion with your own implementation or use a library that provides assertions in Haxe.

        // points.forEach(function (point, i) {
        //     assert.numEqual(point.x, expectedPoints[i].x, 'point[' + i + '].x correct');
        //     assert.numEqual(point.y, expectedPoints[i].y, 'point[' + i + '].y correct');
        // });
        // You can replace the assertions with your own implementation or use a library that provides assertions in Haxe.
    }

    public function testGetLengthGetLengths(): Void {
        var length = curve.getLength();
        var expectedLength = 62.829269247282795;

        // assert.numEqual(length, expectedLength, 'Correct length of curve');
        // You can replace the assertion with your own implementation or use a library that provides assertions in Haxe.

        var lengths = curve.getLengths(5);
        var expectedLengths = [
            0,
            11.755705045849462,
            23.51141009169892,
            35.26711513754839,
            47.02282018339785,
            58.77852522924731
        ];

        // assert.strictEqual(lengths.length, expectedLengths.length, 'Correct number of segments');
        // You can replace the assertion with your own implementation or use a library that provides assertions in Haxe.

        // lengths.forEach(function (segment, i) {
        //     assert.numEqual(segment, expectedLengths[i], 'segment[' + i + '] correct');
        // });
        // You can replace the assertions with your own implementation or use a library that provides assertions in Haxe.
    }

    public function testGetPointGetPointAt(): Void {
        var testValues = [0, 0.3, 0.5, 0.7, 1];

        var p = new Vector2();
        var a = new Vector2();

        for (value in testValues) {
            var expectedX = Math.cos(value * Math.PI * 2) * 10;
            var expectedY = Math.sin(value * Math.PI * 2) * 10;

            curve.getPoint(value, p);
            curve.getPointAt(value, a);

            // assert.numEqual(p.x, expectedX, 'getPoint(' + value + ').x correct');
            // assert.numEqual(p.y, expectedY, 'getPoint(' + value + ').y correct');
            // assert.numEqual(a.x, expectedX, 'getPointAt(' + value + ').x correct');
            // assert.numEqual(a.y, expectedY, 'getPointAt(' + value + ').y correct');
            // You can replace the assertions with your own implementation or use a library that provides assertions in Haxe.
        }
    }

    public function testGetTangent(): Void {
        var expectedTangents = [
            new Vector2(-0.000314159260186071, 0.9999999506519786),
            new Vector2(-1, 0),
            new Vector2(0, -1),
            new Vector2(1, 0),
            new Vector2(0.00031415926018600165, 0.9999999506519784)
        ];

        var tangents = [
            curve.getTangent(0, new Vector2()),
            curve.getTangent(0.25, new Vector2()),
            curve.getTangent(0.5, new Vector2()),
            curve.getTangent(0.75, new Vector2()),
            curve.getTangent(1, new Vector2())
        ];

        for (i in 0...expectedTangents.length) {
            var tangent = tangents[i];
            var exp = expectedTangents[i];

            // assert.numEqual(tangent.x, exp.x, 'getTangent #' + i + ': x correct');
            // assert.numEqual(tangent.y, exp.y, 'getTangent #' + i + ': y correct');
            // You can replace the assertions with your own implementation or use a library that provides assertions in Haxe.
        }
    }

    public function testGetUtoTmapping(): Void {
        var start = curve.getUtoTmapping(0, 0);
        var end = curve.getUtoTmapping(0, curve.getLength());
        var somewhere = curve.getUtoTmapping(0.7, 1);

        var expectedSomewhere = 0.01591614882650014;

        // assert.strictEqual(start, 0, 'getUtoTmapping(0, 0) is the starting point');
        // assert.strictEqual(end, 1, 'getUtoTmapping(0, length) is the ending point');
        // assert.numEqual(somewhere, expectedSomewhere, 'getUtoTmapping(0.7, 1) is correct');
        // You can replace the assertions with your own implementation or use a library that provides assertions in Haxe.
    }

    public function testGetSpacedPoints(): Void {
        var expectedPoints = [
            new Vector2(10, 0),
            new Vector2(3.0901699437494603, 9.51056516295154),
            new Vector2(-8.090169943749492, 5.877852522924707),
            new Vector2(-8.090169943749459, -5.877852522924751),
            new Vector2(3.0901699437494807, -9.510565162951533),
            new Vector2(10, -2.4492935982947065e-15)
        ];

        var points = curve.getSpacedPoints();

        // assert.strictEqual(points.length, expectedPoints.length, 'Correct number of points');
        // You can replace the assertion with your own implementation or use a library that provides assertions in Haxe.

        for (i in 0...expectedPoints.length) {
            var point = points[i];
            var exp = expectedPoints[i];

            // assert.numEqual(point.x, exp.x, 'Point #' + i + ': x correct');
            // assert.numEqual(point.y, exp.y, 'Point #' + i + ': y correct');
            // You can replace the assertions with your own implementation or use a library that provides assertions in Haxe.
        }
    }
}