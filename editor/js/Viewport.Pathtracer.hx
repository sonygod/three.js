package three.js.editor.js;

import three.gpu.pathtracer.WebGLPathTracer;

class ViewportPathtracer {
    private var pathTracer:WebGLPathTracer;

    public function new(renderer:Dynamic) {
        pathTracer = null;
    }

    public function init(scene:Dynamic, camera:Dynamic):Void {
        if (pathTracer == null) {
            pathTracer = new WebGLPathTracer(renderer);
            pathTracer.filterGlossyFactor = 0.5;
        }
        pathTracer.setScene(scene, camera);
    }

    public function setSize(/* width, height */):Void {
        if (pathTracer == null) return;
        pathTracer.reset();
    }

    public function setBackground(/* background, blurriness */):Void {
        if (pathTracer == null) return;
        pathTracer.updateEnvironment();
    }

    public function updateMaterials():Void {
        if (pathTracer == null) return;
        pathTracer.updateMaterials();
    }

    public function setEnvironment(/* environment */):Void {
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