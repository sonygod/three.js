import haxe.unit.TestCase;
import three.CatmullRomCurve3;
import three.Curve;
import three.Vector3;

class CatmullRomCurve3Tests {
    public function new() {}

    public function testInheritance():Void {
        var object:CatmullRomCurve3 = new CatmullRomCurve3();
        Assert.isTrue(Std.is(object, Curve), 'CatmullRomCurve3 extends from Curve');
    }

    public function testInstancing():Void {
        var object:CatmullRomCurve3 = new CatmullRomCurve3();
        Assert.isNotNull(object, 'Can instantiate a CatmullRomCurve3.');
    }

    public function testType():Void {
        var object:CatmullRomCurve3 = new CatmullRomCurve3();
        Assert.areEqual(object.type, 'CatmullRomCurve3', 'CatmullRomCurve3.type should be CatmullRomCurve3');
    }

    // ... and so on for each test method ...

    public function testGetLengthAndGetLengths():Void {
        var positions:Array<Vector3> = [
            new Vector3(-60, -100, 60),
            new Vector3(-60, 20, 60),
            new Vector3(-60, 120, 60),
            new Vector3(60, 20, -60),
            new Vector3(60, -100, -60)
        ];
        var curve:CatmullRomCurve3 = new CatmullRomCurve3(positions);
        curve.curveType = 'catmullrom';

        var length:Float = curve.getLength();
        var expectedLength:Float = 551.549686276872;
        Assert.areEqual(length, expectedLength, 'Correct length of curve');

        var expectedLengths:Array<Float> = [
            0,
            120,
            220,
            416.9771560359221,
            536.9771560359221
        ];
        var lengths:Array<Float> = curve.getLengths(expectedLengths.length - 1);

        Assert.areEqual(lengths.length, expectedLengths.length, 'Correct number of segments');

        for (i in 0...lengths.length) {
            Assert.areEqual(lengths[i], expectedLengths[i], 'segment[' + i + '] correct');
        }
    }

    // ... and so on for each test method ...
}