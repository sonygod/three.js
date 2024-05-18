package three.js.examples.jsm.postprocessing;

import three.Color;
import Pass;

class RenderPass extends Pass {

    public var scene:Dynamic;
    public var camera:Dynamic;

    public var overrideMaterial:Dynamic;
    public var clearColor:Color;
    public var clearAlpha:Null<Float>;

    public var clear:Bool;
    public var clearDepth:Bool;
    public var needsSwap:Bool;
    public var _oldClearColor:Color;

    public function new(scene:Dynamic, camera:Dynamic, ?overrideMaterial:Dynamic, ?clearColor:Color, ?clearAlpha:Float) {
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

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic /*, deltaTime:Float, maskActive:Bool */):Void {
        var oldAutoClear:Bool = renderer.autoClear;
        renderer.autoClear = false;

        var oldOverrideMaterial:Dynamic;
        var oldClearAlpha:Null<Float>;

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
            // TODO: Avoid using autoClear properties, see https://github.com/mrdoob/three.js/pull/15571#issuecomment-465669600
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