import js.WebGLPathTracer;

class ViewportPathtracer {
    var pathTracer:WebGLPathTracer;
    public function new(renderer:WebGLRenderer) {
        pathTracer = null;
        init(renderer);
    }
    private function init(renderer:WebGLRenderer) {
        if (pathTracer == null) {
            pathTracer = WebGLPathTracer(renderer);
            pathTracer.filterGlossyFactor = 0.5;
        }
    }
    public function setSize(width:Int, height:Int):Void {
        if (pathTracer == null) return;
        pathTracer.reset();
    }
    public function setBackground(background:Dynamic, blurriness:Float):Void {
        if (pathTracer == null) return;
        pathTracer.updateEnvironment();
    }
    public function updateMaterials():Void {
        if (pathTracer == null) return;
        pathTracer.updateMaterials();
    }
    public function setEnvironment(environment:Dynamic):Void {
        if (pathTracer == null) return;
        pathTracer.updateEnvironment();
    }
    public function update():Void {
        if (pathTracer == null) return;
        pathTracer.renderSample();
    }
    public function reset():Void {
        if (pathTracer == null) return;
        pathTracer.updateCamera();
    }
}