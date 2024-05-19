Here is the converted Haxe code:
```
package three.js.test.unit.src.extras.curves;

import haxe.unit.TestCase;
import three.js.extras.curves.LineCurve3;
import three.js.extras.core.Curve;
import three.js.math.Vector3;

class LineCurve3Tests {
    public function new() {}

    public function test() {
        var points:Array<Vector3> = [];
        var curve:LineCurve3;

        before(function() {
            points = [
                new Vector3(0, 0, 0),
                new Vector3(10, 10, 10),
                new Vector3(-10, 10, -10),
                new Vector3(-8, 5, -7)
            ];

            curve = new LineCurve3(points[0], points[1]);
        });

        // INHERITANCE
        testCase("Extending", function(assert) {
            var object:LineCurve3 = new LineCurve3();
            assert.isTrue(object instanceof Curve, "LineCurve3 extends from Curve");
        });

        // INSTANCING
        testCase("Instancing", function(assert) {
            var object:LineCurve3 = new LineCurve3();
            assert.notNull(object, "Can instantiate a LineCurve3.");
        });

        // PROPERTIES
        testCase("type", function(assert) {
            var object:LineCurve3 = new LineCurve3();
            assert.areEqual(object.type, "LineCurve3", "LineCurve3.type should be LineCurve3");
        });

        // todo: v1
        testCase("v1", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        // todo: v2
        testCase("v2", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        // PUBLIC
        testCase("isLineCurve3", function(assert) {
            var object:LineCurve3 = new LineCurve3();
            assert.isTrue(object.isLineCurve3, "LineCurve3.isLineCurve3 should be true");
        });

        // todo: getPoint
        testCase("getPoint", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        testCase("getPointAt", function(assert) {
            var curve:LineCurve3 = new LineCurve3(points[0], points[3]);

            var expectedPoints:Array<Vector3> = [
                new Vector3(0, 0, 0),
                new Vector3(-2.4, 1.5, -2.1),
                new Vector3(-4, 2.5, -3.5),
                new Vector3(-8, 5, -7)
            ];

            var points:Array<Vector3> = [
                curve.getPointAt(0, new Vector3()),
                curve.getPointAt(0.3, new Vector3()),
                curve.getPointAt(0.5, new Vector3()),
                curve.getPointAt(1, new Vector3())
            ];

            assert.deepEqual(points, expectedPoints, "Correct getPointAt points");
        });

        // todo: copy
        testCase("copy", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        // todo: toJSON
        testCase("toJSON", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        // todo: fromJSON
        testCase("fromJSON", function(assert) {
            assert.fail("everything's gonna be alright");
        });

        // OTHERS
        testCase("Simple curve", function(assert) {
            var curve:LineCurve3 = _curve;

            var expectedPoints:Array<Vector3> = [
                new Vector3(0, 0, 0),
                new Vector3(2, 2, 2),
                new Vector3(4, 4, 4),
                new Vector3(6, 6, 6),
                new Vector3(8, 8, 8),
                new Vector3(10, 10, 10)
            ];

            var points:Array<Vector3> = curve.getPoints();

            assert.deepEqual(points, expectedPoints, "Correct points for first curve");

            curve = new LineCurve3(points[1], points[2]);

            expectedPoints = [
                new Vector3(10, 10, 10),
                new Vector3(6, 10, 6),
                new Vector3(2, 10, 2),
                new Vector3(-2, 10, -2),
                new Vector3(-6, 10, -6),
                new Vector3(-10, 10, -10)
            ];

            points = curve.getPoints();

            assert.deepEqual(points, expectedPoints, "Correct points for second curve");
        });

        testCase("getLength/getLengths", function(assert) {
            var curve:LineCurve3 = _curve;

            var length:Float = curve.getLength();
            var expectedLength:Float = Math.sqrt(300);

            assert.numEqual(length, expectedLength, "Correct length of curve");

            var lengths:Array<Float> = curve.getLengths(5);
            var expectedLengths:Array<Float> = [
                0.0,
                Math.sqrt(12),
                Math.sqrt(48),
                Math.sqrt(108),
                Math.sqrt(192),
                Math.sqrt(300)
            ];

            assert.areEqual(lengths.length, expectedLengths.length, "Correct number of segments");

            for (i in 0...lengths.length) {
                assert.numEqual(lengths[i], expectedLengths[i], "segment[" + i + "] correct");
            }
        });

        testCase("getTangent/getTangentAt", function(assert) {
            var curve:LineCurve3 = _curve;
            var tangent:Vector3 = new Vector3();

            curve.getTangent(0.5, tangent);
            var expectedTangent:Float = Math.sqrt(1 / 3);

            assert.numEqual(tangent.x, expectedTangent, "tangent.x correct");
            assert.numEqual(tangent.y, expectedTangent, "tangent.y correct");
            assert.numEqual(tangent.z, expectedTangent, "tangent.z correct");

            tangent = curve.getTangentAt(0.5);

            assert.numEqual(tangent.x, expectedTangent, "tangentAt.x correct");
            assert.numEqual(tangent.y, expectedTangent, "tangentAt.y correct");
            assert.numEqual(tangent.z, expectedTangent, "tangentAt.z correct");
        });

        testCase("computeFrenetFrames", function(assert) {
            var curve:LineCurve3 = _curve;

            var expected:Object = {
                binormals: new Vector3(-0.5 * Math.sqrt(2), 0.5 * Math.sqrt(2), 0),
                normals: new Vector3(Math.sqrt(1 / 6), Math.sqrt(1 / 6), -Math.sqrt(2 / 3)),
                tangents: new Vector3(Math.sqrt(1 / 3), Math.sqrt(1 / 3), Math.sqrt(1 / 3))
            };

            var frames:Object = curve.computeFrenetFrames(1, false);

            for (val in expected) {
                assert.numEqual(frames[val][0].x, expected[val].x, "Frenet frames " + val + ".x correct");
                assert.numEqual(frames[val][0].y, expected[val].y, "Frenet frames " + val + ".y correct");
                assert.numEqual(frames[val][0].z, expected[val].z, "Frenet frames " + val + ".z correct");
            }
        });

        testCase("getUtoTmapping", function(assert) {
            var curve:LineCurve3 = _curve;

            var start:Float = curve.getUtoTmapping(0, 0);
            var end:Float = curve.getUtoTmapping(0, curve.getLength());
            var somewhere:Float = curve.getUtoTmapping(0.7, 0);

            assert.areEqual(start, 0, "getUtoTmapping(0, 0) is the starting point");
            assert.areEqual(end, 1, "getUtoTmapping(0, length) is the ending point");
            assert.numEqual(somewhere, 0.7, "getUtoTmapping(0.7, 0) is correct");
        });

        testCase("getSpacedPoints", function(assert) {
            var curve:LineCurve3 = _curve;

            var expectedPoints:Array<Vector3> = [
                new Vector3(0, 0, 0),
                new Vector3(2.5, 2.5, 2.5),
                new Vector3(5, 5, 5),
                new Vector3(7.5, 7.5, 7.5),
                new Vector3(10, 10, 10)
            ];

            var points:Array<Vector3> = curve.getSpacedPoints(4);

            assert.areEqual(points.length, expectedPoints.length, "Correct number of points");
            assert.deepEqual(points, expectedPoints, "Correct points calculated");
        });
    }
}
```
Note that I've used the `haxe.unit` package to define the test cases, and I've replaced the `QUnit` syntax with the equivalent Haxe syntax. I've also removed the `export default` statement, as it's not necessary in Haxe.