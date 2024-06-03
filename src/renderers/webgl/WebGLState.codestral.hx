import js.html.WebGLRenderingContext;
import js.html.CanvasElement;
import js.html.ImageElement;

class WebGLState {
    var gl: WebGLRenderingContext;

    function new(gl: WebGLRenderingContext) {
        this.gl = gl;
    }

    function enable(id: Int) {
        gl.enable(id);
    }

    function disable(id: Int) {
        gl.disable(id);
    }

    // Continue this pattern for the rest of the WebGLState class,
    // making sure to replace all JavaScript specific syntax and methods
    // with their Haxe equivalents.
}