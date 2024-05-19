import haxe.unit.TestCase;
import three.CatmullRomCurve3;
import three.Curve;
import three.Vector3;

class TestCatmullRomCurve3 {
    public function new() {}

    public function testExtending(testCase : TestCase) {
        var object = new CatmullRomCurve3();
        testCase.assertTrue(Std.is(object, Curve), 'CatmullRomCurve3 extends from Curve');
    }

    public function testInstancing(testCase : TestCase) {
        var object = new CatmullRomCurve3();
        testCase.assertNotNull(object, 'Can instantiate a CatmullRomCurve3.');
    }

    public function testType(testCase : TestCase) {
        var object = new CatmullRomCurve3();
        testCase.assertEquals(object.type, 'CatmullRomCurve3', 'CatmullRomCurve3.type should be CatmullRomCurve3');
    }

    public function testIsCatmullRomCurve3(testCase : TestCase) {
        var object = new CatmullRomCurve3();
        testCase.assertTrue(object.isCatmullRomCurve3, 'CatmullRomCurve3.isCatmullRomCurve3 should be true');
    }

    // ...

    public function testCatmullRomCheck(testCase : TestCase) {
        var positions = [
            new Vector3(-60, -100, 60),
            new Vector3(-60, 20, 60),
            new Vector3(-60, 120, 60),
            new Vector3(60, 20, -60),
            new Vector3(60, -100, -60)
        ];
        var curve = new CatmullRomCurve3(positions);
        curve.curveType = 'catmullrom';

        var expectedPoints = [
            new Vector3(-60, -100, 60),
            new Vector3(-60, -51.04, 60),
            new Vector3(-60, -2.7199999999999998, 60),
            new Vector3(-61.92, 44.48, 61.92),
            new Vector3(-68.64, 95.36000000000001, 68.64),
            new Vector3(-60, 120, 60),
            new Vector3(-14.880000000000017, 95.36000000000001, 14.880000000000017),
            new Vector3(41.75999999999997, 44.48000000000003, -41.75999999999997),
            new Vector3(67.68, -2.720000000000023, -67.68),
            new Vector3(65.75999999999999, -51.04000000000001, -65.75999999999999),
            new Vector3(60, -100, -60)
        ];

        var points = curve.getPoints(10);

        testCase.assertEquals(points.length, expectedPoints.length, 'correct number of points.');

        for (i in 0...points.length) {
            testCase.assertEquals(points[i].x, expectedPoints[i].x, 'points[$i].x');
            testCase.assertEquals(points[i].y, expectedPoints[i].y, 'points[$i].y');
            testCase.assertEquals(points[i].z, expectedPoints[i].z, 'points[$i].z');
        }
    }

    // ...
}