import three.extras.curves.CubicBezierCurve3;
import three.math.Vector3;
import three.extras.core.Curve;

class CubicBezierCurve3Tests {
    var curve:CubicBezierCurve3;

    public function new() {
        setup();
        testExtending();
        testInstancing();
        testType();
        // TODO: Add tests for v0, v1, v2, v3, copy, toJSON, fromJSON, getPoint
        testIsCubicBezierCurve3();
        testSimpleCurve();
        testGetLength();
        testGetPointAt();
        testGetTangent();
        testGetUtoTmapping();
        testGetSpacedPoints();
        testComputeFrenetFrames();
    }

    private function setup():Void {
        curve = new CubicBezierCurve3(
            new Vector3(-10, 0, 2),
            new Vector3(-5, 15, 4),
            new Vector3(20, 15, -5),
            new Vector3(10, 0, 10)
        );
    }

    private function testExtending():Void {
        var object = new CubicBezierCurve3();
        // Note: In Haxe, you can use `Std.is` to check instances.
        haxe.Log.trace("CubicBezierCurve3 extends from Curve: " + Std.is(object, Curve));
    }

    private function testInstancing():Void {
        var object = new CubicBezierCurve3();
        haxe.Log.trace("Can instantiate a CubicBezierCurve3: " + (object != null));
    }

    private function testType():Void {
        var object = new CubicBezierCurve3();
        haxe.Log.trace("CubicBezierCurve3.type should be CubicBezierCurve3: " + (object.type == "CubicBezierCurve3"));
    }

    private function testIsCubicBezierCurve3():Void {
        var object = new CubicBezierCurve3();
        haxe.Log.trace("CubicBezierCurve3.isCubicBezierCurve3 should be true: " + object.isCubicBezierCurve3);
    }

    private function testSimpleCurve():Void {
        var expectedPoints = [
            new Vector3(-10, 0, 2),
            new Vector3(-3.359375, 8.4375, 1.984375),
            new Vector3(5.625, 11.25, 1.125),
            new Vector3(11.796875, 8.4375, 2.703125),
            new Vector3(10, 0, 10)
        ];

        var points = curve.getPoints(expectedPoints.length - 1);

        haxe.Log.trace("Correct number of points: " + (points.length == expectedPoints.length));
        haxe.Log.trace("Correct points calculated: " + points.equals(expectedPoints));

        var curveRev = new CubicBezierCurve3(
            curve.v3, curve.v2, curve.v1, curve.v0
        );

        points = curveRev.getPoints(expectedPoints.length - 1);

        haxe.Log.trace("Reversed: Correct number of points: " + (points.length == expectedPoints.length));
        haxe.Log.trace("Reversed: Correct points curve: " + points.equals(expectedPoints.reverse()));
    }

    private function testGetLength():Void {
        var length = curve.getLength();
        var expectedLength = 39.58103024989427;

        haxe.Log.trace("Correct length of curve: " + (length == expectedLength));

        var expectedLengths = [
            0,
            10.73729718231036,
            20.19074500737662,
            27.154413277853756,
            38.453287150114214
        ];
        var lengths = curve.getLengths(expectedLengths.length - 1);

        haxe.Log.trace("Correct number of segments: " + (lengths.length == expectedLengths.length));

        for (i in 0...lengths.length) {
            haxe.Log.trace("segment[" + i + "] correct: " + (lengths[i] == expectedLengths[i]));
        }
    }

    private function testGetPointAt():Void {
        var expectedPoints = [
            new Vector3(-10, 0, 2),
            new Vector3(-2.591880240484318, 8.908333501170798, 1.8953420625251136),
            new Vector3(4.866251460832755, 11.22787914038507, 1.150832855206874),
            new Vector3(10, 0, 10)
        ];

        var points = [
            curve.getPointAt(0, new Vector3()),
            curve.getPointAt(0.3, new Vector3()),
            curve.getPointAt(0.5, new Vector3()),
            curve.getPointAt(1, new Vector3())
        ];

        haxe.Log.trace("Correct points: " + points.equals(expectedPoints));
    }

    private function testGetTangent():Void {
        var expectedTangents = [
            new Vector3(0.3138715439944244, 0.9411440474105875, 0.12542940601858074),
            new Vector3(0.8351825262580098, 0.54174002562179, -0.09480449605683638),
            new Vector3(0.9997531780538501, 0, -0.02221672728433752),
            new Vector3(0.40693407933981185, -0.7512629496079668, 0.5196235518317053),
            new Vector3(-0.42632467075185815, -0.6396469221230213, 0.6396085444448543)
        ];

        var tangents = [
            curve.getTangent(0, new Vector3()),
            curve.getTangent(0.25, new Vector3()),
            curve.getTangent(0.5, new Vector3()),
            curve.getTangent(0.75, new Vector3()),
            curve.getTangent(1, new Vector3())
        ];

        for (i in 0...expectedTangents.length) {
            haxe.Log.trace("getTangent #" + i + ": x correct: " + (tangents[i].x == expectedTangents[i].x));
            haxe.Log.trace("getTangent #" + i + ": y correct: " + (tangents[i].y == expectedTangents[i].y));
        }

        expectedTangents = [
            new Vector3(0.3138715439944244, 0.9411440474105875, 0.12542940601858074),
            new Vector3(0.8016539573770751, 0.5918626760037707, -0.08396133262002324),
            new Vector3(0.997337559412928, 0.05740742907719314, -0.044968652092444425),
            new Vector3(0.1389373097746809, -0.7882209938358005, 0.5995032016837588),
            new Vector3(-0.42632467075185815, -0.6396469221230213, 0.6396085444448543)
        ];

        tangents = [
            curve.getTangentAt(0, new Vector3()),
            curve.getTangentAt(0.25, new Vector3()),
            curve.getTangentAt(0.5, new Vector3()),
            curve.getTangentAt(0.75, new Vector3()),
            curve.getTangentAt(1, new Vector3())
        ];

        for (i in 0...expectedTangents.length) {
            haxe.Log.trace("getTangentAt #" + i + ": x correct: " + (tangents[i].x == expectedTangents[i].x));
            haxe.Log.trace("getTangentAt #" + i + ": y correct: " + (tangents[i].y == expectedTangents[i].y));
        }
    }

    private function testGetUtoTmapping():Void {
        var start = curve.getUtoTmapping(0, 0);
        var end = curve.getUtoTmapping(0, curve.getLength());
        var somewhere = curve.getUtoTmapping(0.5, 1);

        var expectedSomewhere = 0.021163245321323316;

        haxe.Log.trace("getUtoTmapping(0, 0) is the starting point: " + (start == 0));
        haxe.Log.trace("getUtoTmapping(0, length) is the ending point: " + (end == 1));
        haxe.Log.trace("getUtoTmapping(0.5, 1) is correct: " + (somewhere == expectedSomewhere));
    }

    private function testGetSpacedPoints():Void {
        var expectedPoints = [
            new Vector3(-10, 0, 2),
            new Vector3(-5.756524515061918, 6.568020242700483, 2.22116711170301),
            new Vector3(1.0003511895116906, 10.49656064587831, 1.4727101010850698),
            new Vector3(8.767656412295171, 10.784286845278622, 1.2873599519775174),
            new Vector3(12.306772513558396, 5.545103788071547, 4.909948454535794),
            new Vector3(10, 0, 10)
        ];

        var points = curve.getSpacedPoints();

        haxe.Log.trace("Correct number of points: " + (points.length == expectedPoints.length));
        haxe.Log.trace("Correct points calculated: " + points.equals(expectedPoints));
    }

    private function testComputeFrenetFrames():Void {
        var expected = {
            binormals: [
                new Vector3(-0.9486358543207215, 0.316370061632252, -6.938893903907228e-18),
                new Vector3(-0.05491430765311864, 0.9969838307670049, 0.054842137122173326),
                new Vector3(0.5944656510461876, 0.334836503700931, 0.7310917216844742)
            ],
            normals: [
                new Vector3(0.03968210891259515, 0.11898683173537697, -0.9921025471723304),
                new Vector3(-0.047981365124836806, 0.05222670079466692, -0.9974819097732357),
                new Vector3(0.6818048583242511, -0.6919077473246573, -0.23749906180354932)
            ],
            tangents: [
                new Vector3(0.3138715439944244, 0.9411440474105875, 0.12542940601858074),
                new Vector3(0.9973375594129282, 0.05740742907719315, -0.04496865209244443),
                new Vector3(-0.42632467075185815, -0.6396469221230213, 0.6396085444448543)
            ]
        };

        var frames = curve.computeFrenetFrames(2, false);

        for (group in Reflect.fields(expected)) {
            for (j in 0...expected[group].length) {
                haxe.Log.trace("Frenet frames [" + group + ", " + j + "].x correct: " + (frames[group][j].x == expected[group][j].x));
                haxe.Log.trace("Frenet frames [" + group + ", " + j + "].y correct: " + (frames[group][j].y == expected[group][j].y));
                haxe.Log.trace("Frenet frames [" + group + ", " + j + "].z correct: " + (frames[group][j].z == expected[group][j].z));
            }
        }
    }
}