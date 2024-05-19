package three.test.unit.src.renderers.webgl;

import utest.Runner;
import utest.ui.Report;

class WebGLLightsTest {
    public function new() {}

    public static function main() {
        var runner = new Runner();
        runner.addCase(new WebGLLightsTest());
        Report.create(runner);
        runner.run();
    }

    public function testInstancing() {
        #if todo
        assert(false, "everything's gonna be alright");
        #end
    }

    public function testSetup() {
        #if todo
        assert(false, "everything's gonna be alright");
        #end
    }

    public function testState() {
        #if todo
        assert(false, "everything's gonna be alright");
        #end
    }
}