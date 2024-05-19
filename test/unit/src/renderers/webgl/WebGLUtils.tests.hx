package three.test.unit.src.renderers.webgl;

import three.renderers.webgl.WebGLUtils;
import utest.Runner;
import utest.ui.Report;

class WebGLUtilsTests {
    public static function main():Void {
        var runner:Runner = new Runner();
        runner.addCase(new WebGLUtilsTest());
        Report.create(runner);
        runner.run();
    }
}

class WebGLUtilsTest {
    public function new() {}

    public function testInstancing():Void {
        Assert.isTrue(false, "everything's gonna be alright");
    }

    public function testConvert():Void {
        Assert.isTrue(false, "everything's gonna be alright");
    }
}