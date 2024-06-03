import js.Browser.document;
import three.renderers.WebGLRenderer;

class WebGLRendererTests {
    public static function testInstancing():Void {
        var renderer = new WebGLRenderer();
        js.Browser.console.log("Can instantiate a WebGLRenderer.");
    }

    public static function testDispose():Void {
        var object = new WebGLRenderer();
        object.dispose();
    }
}