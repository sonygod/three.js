package three.test.unit.src.extras.core;

import haxe.unit.TestCase;
import three.extras.core.Path;
import three.extras.core.CurvePath;

class PathTests {

    public function new() {}

    public function testExtending() {
        var object = new Path();
        assertTrue(object instanceof CurvePath, 'Path extends from CurvePath');
    }

    public function testInstancing() {
        var object = new Path();
        assertTrue(object != null, 'Can instantiate a Path.');
    }

    public function testType() {
        var object = new Path();
        assertEquals(object.type, 'Path', 'Path.type should be Path');
    }

    public function todoCurrentPoint() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoSetFromPoints() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoMoveTo() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoLineTo() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoQuadraticCurveTo() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoBezierCurveTo() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoSplineThru() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoArc() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoAbsarc() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoEllipse() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoAbsellipse() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoCopy() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoToJSON() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoFromJSON() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    static function main() {
        var runner = new haxe.unit.TestRunner();
        runner.add(new PathTests());
        runner.run();
    }
}