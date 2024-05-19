package three.test.unit.src.extras.core;

import utest.Runner;
import utest.ui.Report;
import utest.Assert;

class InterpolationsTest {
    public function new() {}

    public static function main() {
        var runner = new Runner();
        runner.addCase(new InterpolationsTest());
        Report.create(runner);
        runner.run();
    }

    public function testCatmullRom() {
        Assert.fail("everything's gonna be alright");
    }

    public function testQuadraticBezier() {
        Assert.fail("everything's gonna be alright");
    }

    public function testCubicBezier() {
        Assert.fail("everything's gonna be alright");
    }
}