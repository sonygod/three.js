// Import the necessary classes
import three.js.curves.LineCurve3;
import three.js.core.Curve;
import three.js.math.Vector3;

// Define a test module
class LineCurve3Tests {
    public function new() {}

    public static function main() {
        // Create a test module
        var testModule =_Test.createModule("Extras");

        // Create a sub-module for curves
        var curvesModule = testModule.addModule("Curves");

        // Create a sub-module for LineCurve3
        var lineCurve3Module = curvesModule.addModule("LineCurve3");

        // Define setup and teardown functions
        lineCurve3Module.beforeEach(function() {
            _points = [
                new Vector3(0, 0, 0),
                new Vector3(10, 10, 10),
                new Vector3(-10, 10, -10),
                new Vector3(-8, 5, -7)
            ];

            _curve = new LineCurve3(_points[0], _points[1]);
        });

        // Inheritance test
        lineCurve3Module.addTest("Extending", function(assert) {
            var object:LineCurve3 = new LineCurve3();
            assert.isTrue(object instanceof Curve, "LineCurve3 extends from Curve");
        });

        // Instancing test
        lineCurve3Module.addTest("Instancing", function(assert) {
            var object:LineCurve3 = new LineCurve3();
            assert.notNull(object, "Can instantiate a LineCurve3.");
        });

        // Properties test
        lineCurve3Module.addTest("type", function(assert) {
            var object:LineCurve3 = new LineCurve3();
            assert.areEqual(object.type, "LineCurve3", "LineCurve3.type should be LineCurve3");
        });

        // Todo tests
        lineCurve3Module.addTest("v1", function(assert) {
            assert.fail("Todo: implement test for v1");
        });

        lineCurve3Module.addTest("v2", function(assert) {
            assert.fail("Todo: implement test for v2");
        });

        // Public methods tests
        lineCurve3Module.addTest("isLineCurve3", function(assert) {
            var object:LineCurve3 = new LineCurve3();
            assert.isTrue(object.isLineCurve3, "LineCurve3.isLineCurve3 should be true");
        });

        // Todo tests
        lineCurve3Module.addTest("getPoint", function(assert) {
            assert.fail("Todo: implement test for getPoint");
        });

        lineCurve3Module.addTest("getPointAt", function(assert) {
            var curve:LineCurve3 = new LineCurve3(_points[0], _points[3]);
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

            assert.deepEqual(points, expectedPoints, "Correct getPointAt points");
        });

        // Todo tests
        lineCurve3Module.addTest("copy", function(assert) {
            assert.fail("Todo: implement test for copy");
        });

        lineCurve3Module.addTest("toJSON", function(assert) {
            assert.fail("Todo: implement test for toJSON");
        });

        lineCurve3Module.addTest("fromJSON", function(assert) {
            assert.fail("Todo: implement test for fromJSON");
        });

        // Other tests
        lineCurve3Module.addTest("Simple curve", function(assert) {
            var curve:LineCurve3 = _curve;

            var expectedPoints = [
                new Vector3(0, 0, 0),
                new Vector3(2, 2, 2),
                new Vector3(4, 4, 4),
                new Vector3(6, 6, 6),
                new Vector3(8, 8, 8),
                new Vector3(10, 10, 10)
            ];

            var points = curve.getPoints();

            assert.deepEqual(points, expectedPoints, "Correct points for first curve");

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

            assert.deepEqual(points, expectedPoints, "Correct points for second curve");
        });

        lineCurve3Module.addTest("getLength/getLengths", function(assert) {
            var curve:LineCurve3 = _curve;

            var length = curve.getLength();
            var expectedLength = Math.sqrt(300);

            assert-numEqual(length, expectedLength, "Correct length of curve");

            var lengths = curve.getLengths(5);
            var expectedLengths = [
                0.0,
                Math.sqrt(12),
                Math.sqrt(48),
                Math.sqrt(108),
                Math.sqrt(192),
                Math.sqrt(300)
            ];

            assert.areEqual(lengths.length, expectedLengths.length, "Correct number of segments");

            for (i in 0...lengths.length) {
                assert-numEqual(lengths[i], expectedLengths[i], "segment[$i] correct");
            }
        });

        lineCurve3Module.addTest("getTangent/getTangentAt", function(assert) {
            var curve:LineCurve3 = _curve;
            var tangent:Vector3 = new Vector3();

            curve.getTangent(0.5, tangent);
            var expectedTangent = Math.sqrt(1/3);

            assert-numEqual(tangent.x, expectedTangent, "tangent.x correct");
            assert-numEqual(tangent.y, expectedTangent, "tangent.y correct");
            assert-numEqual(tangent.z, expectedTangent, "tangent.z correct");

            tangent = curve.getTangentAt(0.5);

            assert-numEqual(tangent.x, expectedTangent, "tangentAt.x correct");
            assert-numEqual(tangent.y, expectedTangent, "tangentAt.y correct");
            assert-numEqual(tangent.z, expectedTangent, "tangentAt.z correct");
        });

        lineCurve3Module.addTest("computeFrenetFrames", function(assert) {
            var curve:LineCurve3 = _curve;

            var expected = {
                binormals: new Vector3(-0.5 * Math.sqrt(2), 0.5 * Math.sqrt(2), 0),
                normals: new Vector3(Math.sqrt(1/6), Math.sqrt(1/6), -Math.sqrt(2/3)),
                tangents: new Vector3(Math.sqrt(1/3), Math.sqrt(1/3), Math.sqrt(1/3))
            };

            var frames = curve.computeFrenetFrames(1, false);

            for (val in expected) {
                assert-numEqual(frames[val][0].x, expected[val].x, 'Frenet frames ' + val + '.x correct');
                assert-numEqual(frames[val][0].y, expected[val].y, 'Frenet frames ' + val + '.y correct');
                assert-numEqual(frames[val][0].z, expected[val].z, 'Frenet frames ' + val + '.z correct');
            }
        });

        lineCurve3Module.addTest("getUtoTmapping", function(assert) {
            var curve:LineCurve3 = _curve;

            var start = curve.getUtoTmapping(0, 0);
            var end = curve.getUtoTmapping(0, curve.getLength());
            var somewhere = curve.getUtoTmapping(0.7, 0);

            assert.areEqual(start, 0, 'getUtoTmapping(0, 0) is the starting point');
            assert.areEqual(end, 1, 'getUtoTmapping(0, length) is the ending point');
            assert-numEqual(somewhere, 0.7, 'getUtoTmapping(0.7, 0) is correct');
        });

        lineCurve3Module.addTest("getSpacedPoints", function(assert) {
            var curve:LineCurve3 = _curve;

            var expectedPoints = [
                new Vector3(0, 0, 0),
                new Vector3(2.5, 2.5, 2.5),
                new Vector3(5, 5, 5),
                new Vector3(7.5, 7.5, 7.5),
                new Vector3(10, 10, 10)
            ];

            var points = curve.getSpacedPoints(4);

            assert.areEqual(points.length, expectedPoints.length, 'Correct number of points');
            assert.deepEqual(points, expectedPoints, 'Correct points calculated');
        });
    }
}