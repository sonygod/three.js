import haxe.unit.TestCase;
import three.extras.core.ShapePath;

class ShapePathTests {
    public function new() {}

    public function testInstancing() {
        var object = new ShapePath();
        assertEquals(true, object != null, 'Can instantiate a ShapePath.');
    }

    public function testType() {
        var object = new ShapePath();
        assertEquals('ShapePath', object.type, 'ShapePath.type should be ShapePath');
    }

    public function todoColor() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoSubPaths() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoCurrentPath() {
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

    public function todoToShapes() {
        assertTrue(false, 'everything\'s gonna be alright');
    }
}

Note that I've used the `haxe.unit` package for testing, and assumed that the `ShapePath` class is in the `three.extras.core` package. I've also renamed the tests to follow Haxe's convention for method names.

You'll need to run the tests using the Haxe unit testing framework. You can do this by creating a `TestRunner` class that instantiates and runs the `ShapePathTests` class:

import haxe.unit.TestRunner;

class TestRunner {
    public static function main() {
        var runner = new TestRunner();
        runner.add(new ShapePathTests());
        runner.run();
    }
}