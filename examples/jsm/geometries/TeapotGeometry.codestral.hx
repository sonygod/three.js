import js.Browser;
import js.html.WebGLRenderingContext;
import js.html.CanvasElement;
import js.html.HTMLDocument;

class TeapotGeometry {
    public var gl: WebGLRenderingContext;
    public var canvas: CanvasElement;
    public var size: Float = 50.0;
    public var segments: Int = 10;
    public var bottom: Bool = true;
    public var lid: Bool = true;
    public var body: Bool = true;
    public var fitLid: Bool = true;
    public var blinn: Bool = true;

    public function new(size: Float = 50.0, segments: Int = 10, bottom: Bool = true, lid: Bool = true, body: Bool = true, fitLid: Bool = true, blinn: Bool = true) {
        this.size = size;
        this.segments = segments;
        this.bottom = bottom;
        this.lid = lid;
        this.body = body;
        this.fitLid = fitLid;
        this.blinn = blinn;

        this.canvas = Browser.document.getElementById("canvas") as CanvasElement;
        this.gl = this.canvas.getContext("webgl", {alpha: false}) as WebGLRenderingContext;

        // Rest of the code...
    }

    // Rest of the methods...
}