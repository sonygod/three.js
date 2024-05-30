package three.test.unit.src.extras.core;

import haxe.unit.TestCase;

class InterpolationsTest extends TestCase {

    public function new() {
        super();
    }

    public function testCatmullRom() {
        todo("CatmullRom", "everything's gonna be alright");
    }

    public function testQuadraticBezier() {
        todo("QuadraticBezier", "everything's gonna be alright");
    }

    public function testCubicBezier() {
        todo("CubicBezier", "everything's gonna be alright");
    }

    public static function main() {
        var runner = new haxe.unit.TestRunner();
        runner.add(new InterpolationsTest());
        runner.run();
    }

}