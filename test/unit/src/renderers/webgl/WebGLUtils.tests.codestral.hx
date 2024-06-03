import js.Browser.document;
import js.html.InputElement;
import js.html.HTML;

class WebGLUtilsTests {
    public function new() {
        testWebGL();
    }

    private function testWebGL() {
        trace("Renderers");
        trace("\tWebGL");
        trace("\t\tWebGLUtils");
        testInstancing();
        testConvert();
    }

    private function testInstancing() {
        trace("\t\t\tInstancing");
        var assert = haxe.unit.Assert;
        // Replace the following line with the actual test
        assert.isTrue(false, 'everything\'s gonna be alright');
    }

    private function testConvert() {
        trace("\t\t\tconvert");
        var assert = haxe.unit.Assert;
        // Replace the following line with the actual test
        assert.isTrue(false, 'everything\'s gonna be alright');
    }
}