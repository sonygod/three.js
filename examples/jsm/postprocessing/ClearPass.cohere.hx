import js.three.Color;
import Pass from "./Pass.hx";

class ClearPass extends Pass {
    public var needsSwap:Bool = false;
    public var clearColor:Int;
    public var clearAlpha:Float;
    public var _oldClearColor:Color;

    public function new(clearColor:Int = 0x000000, clearAlpha:Float = 0.0) {
        super();
        this.clearColor = clearColor;
        this.clearAlpha = clearAlpha;
        this._oldClearColor = new Color();
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic) {
        var oldClearAlpha:Float;

        if (this.clearColor != null) {
            var oldClearColor = renderer.getClearColor();
            oldClearAlpha = renderer.getClearAlpha();

            renderer.setClearColor(this.clearColor, this.clearAlpha);
        }

        renderer.setRenderTarget(if (this.renderToScreen) null else readBuffer);
        renderer.clear();

        if (this.clearColor != null) {
            renderer.setClearColor(oldClearColor, oldClearAlpha);
        }
    }
}

@:export("ClearPass")
extern function ClearPass_create(clearColor:Int, clearAlpha:Float):ClearPass;