import js.three.Color;
import js.three.Pass;

class RenderPass extends Pass {
    var scene:Dynamic;
    var camera:Dynamic;
    var overrideMaterial:Dynamic;
    var clearColor:Dynamic;
    var clearAlpha:Float;
    var clear:Bool;
    var clearDepth:Bool;
    var needsSwap:Bool;
    var _oldClearColor:Color;

    public function new(scene:Dynamic, camera:Dynamic, overrideMaterial:Dynamic = null, clearColor:Dynamic = null, clearAlpha:Float = null) {
        super();
        this.scene = scene;
        this.camera = camera;
        this.overrideMaterial = overrideMaterial;
        this.clearColor = clearColor;
        this.clearAlpha = clearAlpha;
        this.clear = true;
        this.clearDepth = false;
        this.needsSwap = false;
        this._oldClearColor = new Color();
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic) {
        var oldAutoClear = renderer.autoClear;
        renderer.autoClear = false;

        var oldClearAlpha:Float;
        var oldOverrideMaterial:Dynamic;

        if (overrideMaterial != null) {
            oldOverrideMaterial = scene.overrideMaterial;
            scene.overrideMaterial = overrideMaterial;
        }

        if (clearColor != null) {
            renderer.getClearColor(_oldClearColor);
            renderer.setClearColor(clearColor);
        }

        if (clearAlpha != null) {
            oldClearAlpha = renderer.getClearAlpha();
            renderer.setClearAlpha(clearAlpha);
        }

        if (clearDepth) {
            renderer.clearDepth();
        }

        renderer.setRenderTarget(if (renderToScreen) null else readBuffer);

        if (clear) {
            renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
        }

        renderer.render(scene, camera);

        // restore

        if (clearColor != null) {
            renderer.setClearColor(_oldClearColor);
        }

        if (clearAlpha != null) {
            renderer.setClearAlpha(oldClearAlpha);
        }

        if (overrideMaterial != null) {
            scene.overrideMaterial = oldOverrideMaterial;
        }

        renderer.autoClear = oldAutoClear;
    }
}

@:jsModule("RenderPass")
class RenderPassModule {
    static function renderPass($:RenderPass) {
    }
}