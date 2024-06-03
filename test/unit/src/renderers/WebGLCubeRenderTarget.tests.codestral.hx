import threejs.renderers.WebGLCubeRenderTarget;
import threejs.renderers.WebGLRenderTarget;

class WebGLCubeRenderTargetTests {

    public function new() {
        testExtending();
        testInstancing();
        // TODO: Add tests for other methods
    }

    private function testExtending(): Void {
        var object = new WebGLCubeRenderTarget();
        haxe.unit.Assert.isTrue(Std.is(object, WebGLRenderTarget), "WebGLCubeRenderTarget extends from WebGLRenderTarget");
    }

    private function testInstancing(): Void {
        var object = new WebGLCubeRenderTarget();
        haxe.unit.Assert.notNull(object, "Can instantiate a WebGLCubeRenderTarget.");
    }

    // TODO: Add tests for other methods
}