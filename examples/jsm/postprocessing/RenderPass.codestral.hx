import three.Color;
import postprocessing.Pass;

class RenderPass extends Pass {

    public var scene:Scene;
    public var camera:Camera;
    public var overrideMaterial:Material;
    public var clearColor:Color;
    public var clearAlpha:Float;
    public var clear:Bool;
    public var clearDepth:Bool;
    public var needsSwap:Bool;
    public var _oldClearColor:Color;

    public function new(scene:Scene, camera:Camera, ?overrideMaterial:Material, ?clearColor:Color, ?clearAlpha:Float) {
        super();

        this.scene = scene;
        this.camera = camera;
        this.overrideMaterial = overrideMaterial != null ? overrideMaterial : null;
        this.clearColor = clearColor != null ? clearColor : null;
        this.clearAlpha = clearAlpha != null ? clearAlpha : null;

        this.clear = true;
        this.clearDepth = false;
        this.needsSwap = false;
        this._oldClearColor = new Color();
    }

    public function render(renderer:Renderer, writeBuffer:RenderTarget, readBuffer:RenderTarget) {
        var oldAutoClear = renderer.autoClear;
        renderer.autoClear = false;

        var oldClearAlpha:Float;
        var oldOverrideMaterial:Material;

        if (this.overrideMaterial != null) {
            oldOverrideMaterial = this.scene.overrideMaterial;
            this.scene.overrideMaterial = this.overrideMaterial;
        }

        if (this.clearColor != null) {
            renderer.getClearColor(this._oldClearColor);
            renderer.setClearColor(this.clearColor);
        }

        if (this.clearAlpha != null) {
            oldClearAlpha = renderer.getClearAlpha();
            renderer.setClearAlpha(this.clearAlpha);
        }

        if (this.clearDepth) {
            renderer.clearDepth();
        }

        renderer.setRenderTarget(this.renderToScreen ? null : readBuffer);

        if (this.clear) {
            renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
        }

        renderer.render(this.scene, this.camera);

        // restore

        if (this.clearColor != null) {
            renderer.setClearColor(this._oldClearColor);
        }

        if (this.clearAlpha != null) {
            renderer.setClearAlpha(oldClearAlpha);
        }

        if (this.overrideMaterial != null) {
            this.scene.overrideMaterial = oldOverrideMaterial;
        }

        renderer.autoClear = oldAutoClear;
    }

}