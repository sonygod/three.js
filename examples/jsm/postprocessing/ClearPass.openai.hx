package three.js.examples.jsm.postprocessing;

import three.Color;
import Pass;

class ClearPass extends Pass {
    public var clearColor:Int;
    public var clearAlpha:Float;
    private var _oldClearColor:Color;

    public function new(clearColor:Int = 0x000000, clearAlpha:Float = 0) {
        super();
        this.needsSwap = false;
        this.clearColor = clearColor;
        this.clearAlpha = clearAlpha;
        this._oldClearColor = new Color();
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic, ?deltaTime:Float, ?maskActive:Bool) {
        var oldClearAlpha:Float;

        if (clearColor != 0) {
            renderer.getClearColor(_oldClearColor);
            oldClearAlpha = renderer.getClearAlpha();
            renderer.setClearColor(clearColor, clearAlpha);
        }

        renderer.setRenderTarget(renderToScreen ? null : readBuffer);
        renderer.clear();

        if (clearColor != 0) {
            renderer.setClearColor(_oldClearColor, oldClearAlpha);
        }
    }
}