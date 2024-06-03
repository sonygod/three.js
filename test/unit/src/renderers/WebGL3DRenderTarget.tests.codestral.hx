import three.renderers.WebGL3DRenderTarget;
import three.renderers.WebGLRenderTarget;

class WebGL3DRenderTargetTests {
    public function new() {
        testExtending();
        testInstancing();
        // TODO: Uncomment and implement the rest of the tests
        // testDepth();
        // testTexture();
        // testIsWebGL3DRenderTarget();
    }

    private function testExtending() {
        var object = new WebGL3DRenderTarget();
        haxe.unit.Assert.isTrue(Std.is(object, WebGLRenderTarget), "WebGL3DRenderTarget extends from WebGLRenderTarget");
    }

    private function testInstancing() {
        var object = new WebGL3DRenderTarget();
        haxe.unit.Assert.isNotNull(object, "Can instantiate a WebGL3DRenderTarget.");
    }

    // TODO: Implement the rest of the tests
    /*
    private function testDepth() {
        // Implementation here
    }

    private function testTexture() {
        // Implementation here
    }

    private function testIsWebGL3DRenderTarget() {
        // Implementation here
    }
    */
}