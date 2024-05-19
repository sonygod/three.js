package three.js.test.unit.src.extras.core;

import haxe.unit.TestCase;
import three.extras.core.CurvePath;
import three.extras.core.Curve;

class CurvePathTest {
    public function new() {}

    public function testExtending():Void {
        var object:CurvePath = new CurvePath();
        assertTrue(Std.is(object, Curve), 'CurvePath extends from Curve');
    }

    public function testInstancing():Void {
        var object:CurvePath = new CurvePath();
        assertNotNull(object, 'Can instantiate a CurvePath.');
    }

    public function testType():Void {
        var object:Curve = new Curve();
        assertEquals(object.type, 'Curve', 'Curve.type should be Curve');
    }

    public function todoCurves():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoAutoClose():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoAdd():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoClosePath():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoGetPoint():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoGetLength():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoUpdateArcLengths():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoGetCurveLengths():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoGetSpacedPoints():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoGetPoints():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoCopy():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoToJSON():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoFromJSON():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }
}