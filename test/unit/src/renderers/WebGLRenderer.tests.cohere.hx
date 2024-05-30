import js.WebGLRenderingContext;
import js.WebGLRenderer;

class WebGLRendererTest {
    static function main() {
        var renderer = new WebGLRenderer();
        trace("Can instantiate a WebGLRenderer: " + Std.is(renderer, WebGLRenderer));
    }
}

WebGLRendererTest.main();