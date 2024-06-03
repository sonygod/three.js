import three.gpu.pathtracer.WebGLPathTracer;
import three.renderer.WebGLRenderer;
import three.scene.Scene;
import three.camera.Camera;

class ViewportPathtracer {
    private var pathTracer:WebGLPathTracer = null;
    private var renderer:WebGLRenderer;

    public function new(renderer:WebGLRenderer) {
        this.renderer = renderer;
    }

    public function init(scene:Scene, camera:Camera):Void {
        if (pathTracer == null) {
            pathTracer = new WebGLPathTracer(renderer);
            pathTracer.filterGlossyFactor = 0.5;
        }
        pathTracer.setScene(scene, camera);
    }

    public function setSize():Void {
        if (pathTracer == null) return;
        pathTracer.reset();
    }

    public function setBackground():Void {
        if (pathTracer == null) return;
        pathTracer.updateEnvironment();
    }

    public function updateMaterials():Void {
        if (pathTracer == null) return;
        pathTracer.updateMaterials();
    }

    public function setEnvironment():Void {
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