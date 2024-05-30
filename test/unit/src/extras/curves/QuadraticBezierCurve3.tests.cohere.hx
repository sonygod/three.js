import js.extras.curves.QuadraticBezierCurve3;
import js.extras.core.Curve;
import js.math.Vector3;

class TestExtras {

    static function main() {
        var _curve = new QuadraticBezierCurve3(
            new Vector3(-10, 0, 2),
            new Vector3(20, 15, -5),
            new Vector3(10, 0, 10)
        );

        // INHERITANCE
        function testExtending() {
            var object = new QuadraticBezierCurve3();
            return object instanceof Curve;
        }

        // INSTANCING
        function testInstancing() {
            var object = new QuadraticBezierCurve3();
            return object != null;
        }

        // PROPERTIES
        function testType() {
            var object = new QuadraticBezierCurve3();
            return object.getType() == "QuadraticBezierCurve3";
        }

        // PUBLIC
        function testIsQuadraticBezierCurve3() {
            var object = new QuadraticBezierCurve3();
            return object.isQuadraticBezierCurve3();
        }

        // OTHERS
        function testSimpleCurve() {
            var curve = _curve;
            var expectedPoints = [
                new Vector3(-10, 0, 2),
                new Vector3(2.5, 5.625, -0.125),
                new Vector3(10, 7.5, 0.5),
                new Vector3(12.5, 5.625, 3.875),
                new Vector3(10, 0, 10)
            ];
            var points = curve.getPoints(expectedPoints.length - 1);
            return points.length == expectedPoints.length && points == expectedPoints;
        }

        function testGetLength_getLengths() {
            var curve = _curve;
            var length = curve.getLength();
            var expectedLength = 35.47294274967861;
            var expectedLengths = [
                0,
                13.871057998581074,
                21.62710402732536,
                26.226696400568883,
                34.91037361704809
            ];
            var lengths = curve.getLengths(expectedLengths.length - 1);
            return length == expectedLength && lengths.length == expectedLengths.length && lengths == expectedLengths;
        }

        function testGetPointAt() {
            var curve = _curve;
            var expectedPoints = [
                new Vector3(-10, 0, 2),
                new Vector3(-0.4981634504454243, 4.427089043881476, 0.19308849757196012),
                new Vector3(6.149415812887238, 6.838853310980195, -0.20278120208668637),
                new Vector3(10, 0, 10)
            ];
            var points = [
                curve.getPointAt(0, new Vector3()),
                curve.getPointAt(0.3, new Vector3()),
                curve.getPointAt(0.5, new Vector3()),
                curve.getPointAt(1, new Vector3())
            ];
            return points == expectedPoints;
        }

        function testGetTangent_getTangentAt() {
            var curve = _curve;
            var expectedTangents = [
                new Vector3(0.8755715084258769, 0.4377711603816079, -0.2042815331129452),
                new Vector3(0.9340289249885844, 0.3502608468707904, -0.07005216937416067),
                new Vector3(0.9284766908853163, 0, 0.37139067635396156),
                new Vector3(-3.669031233375946e-13, -0.6196442885791218, 0.7848827655333463),
                new Vector3(-0.4263618889888853, -0.6396068005601663, 0.6396238584473043)
            ];
            var tangents = [
                curve.getTangent(0, new Vector3()),
                curve.getTangent(0.25, new Vector3()),
                curve.getTangent(0.5, new Vector3()),
                curve.getTangent(0.75, new Vector3()),
                curve.getTangent(1, new Vector3())
            ];
            for (i in 0...expectedTangents.length) {
                var tangent = tangents[i];
                var exp = expectedTangents[i];
                return tangent.x == exp.x && tangent.y == exp.y;
            }
            expectedTangents = [
                new Vector3(0.8755715084258769, 0.4377711603816079, -0.2042815331129452),
                new Vector3(0.9060725703490549, 0.3984742932857448, -0.14230507668907377),
                new Vector3(0.9621604167456882, 0.2688562845452628, 0.044312872940942424),
                new Vector3(0.016586454041780826, -0.6163270940470614, 0.7873155674098058),
                new Vector3(-0.4263618889888853, -0.6396068005601663, 0.6396238584473043)
            ];
            tangents = [
                curve.getTangentAt(0, new Vector3()),
                curve.getTangentAt(0.25, new Vector3()),
                curve.getTangentAt(0.5, new Vector3()),
                curve.getTangentAt(0.75, new Vector3()),
                curve.getTangentAt(1, new Vector3())
            ];
            for (i in 0...expectedTangents.length) {
                var tangent = tangents[i];
                var exp = expectedTangents[i];
                return tangent.x == exp.x && tangent.y == exp.y;
            }
        }

        function testGetUtoTmapping() {
            var curve = _curve;
            var start = curve.getUtoTmapping(0, 0);
            var end = curve.getUtoTmapping(0, curve.getLength());
            var somewhere = curve.getUtoTmapping(0.5, 1);
            var expectedSomewhere = 0.014760890927167196;
            return start == 0 && end == 1 && somewhere == expectedSomewhere;
        }

        function testGetSpacedPoints() {
            var curve = _curve;
            var expectedPoints = [
                new Vector3(-10, 0, 2),
                new Vector3(-3.712652983516992, 3.015179001762753, 0.6957120710270492),
                new Vector3(2.7830973773262975, 5.730399338061483, -0.1452668772806931),
                new Vector3(9.575825284074465, 7.48754187603603, 0.3461104039841496),
                new Vector3(12.345199937734154, 4.575759904730531, 5.142117429101656),
                new Vector3(10, 0, 10)
            ];
            var points = curve.getSpacedPoints();
            return points.length == expectedPoints.length && points == expectedPoints;
        }

        function testComputeFrenetFrames() {
            var curve = _curve;
            var expected = {
                binormals: [
                    new Vector3(-0.447201668889759, 0.8944331542056199, 0),
                    new Vector3(-0.2684231751110917, 0.9631753839815436, -0.01556209353802903),
                    new Vector3(0.3459273556592433, 0.53807011680075, 0.7686447905324219)
                ],
                normals: [
                    new Vector3(-0.18271617600817133, -0.09135504253146765, -0.9789121795283909),
                    new Vector3(0.046865035058597876, -0.003078628350883253, -0.9988964863970807),
                    new Vector3(0.8357929194629689, -0.5489842348221077, 0.008155102228190641)
                ],
                tangents: [
                    new Vector3(0.8755715084258767, 0.4377711603816078, -0.20428153311294514),
                    new Vector3(0.9621604167456884, 0.26885628454526284, 0.04431287294094243),
                    new Vector3(-0.4263618889888853, -0.6396068005601663, 0.6396238584473043)
                ]
            };
            var frames = curve.computeFrenetFrames(2, false);
            for (group in expected.keys()) {
                for (i in 0...expected[group].length) {
                    var vec = expected[group][i];
                    var frame = frames[group][i];
                    return frame.x == vec.x && frame.y == vec.y && frame.z == vec.z;
                }
            }
        }
    }
}