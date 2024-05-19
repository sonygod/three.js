package three.test.unit.src.extras.core;

import three.extras.core.ShapePath;
import haxe.unit.TestCase;

class ShapePathTests {

    public function new() {}

    public function testInstancing():Void {
        var object = new ShapePath();
        assertEquals(true, object != null, 'Can instantiate a ShapePath.');
    }

    public function testType():Void {
        var object = new ShapePath();
        assertEquals('ShapePath', object.type, 'ShapePath.type should be ShapePath');
    }

    public function todoColor():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoSubPaths():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoCurrentPath():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoMoveTo():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoLineTo():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoQuadraticCurveTo():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoBezierCurveTo():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoSplineThru():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoToShapes():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public static function main():Void {
        var testRunner = new haxe.unit.TestRunner();
        testRunner.add(new ShapePathTests());
        testRunner.run();
    }
}