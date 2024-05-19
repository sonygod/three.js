import haxe.unit.TestCase;
import three.renderers.WebGLArrayRenderTarget;
import three.renderers.WebGLRenderTarget;

class WebGLArrayRenderTargetTests {
    public function new() {}

    public function testExtending():Void {
        var object:WebGLArrayRenderTarget = new WebGLArrayRenderTarget();
        assertTrue(object instanceof WebGLRenderTarget, 'WebGLArrayRenderTarget extends from WebGLRenderTarget');
    }

    public function testInstancing():Void {
        var object:WebGLArrayRenderTarget = new WebGLArrayRenderTarget();
        assertNotNull(object, 'Can instantiate a WebGLArrayRenderTarget.');
    }

    public function todoDepth():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoTexture():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoIsWebGLArrayRenderTarget():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public static function main():Void {
        var testCase:TestCase = new WebClient();
        testCase.addTest(new WebGLArrayRenderTargetTests());
        testCase.run();
    }
}