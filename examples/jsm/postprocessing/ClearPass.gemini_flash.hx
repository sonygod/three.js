import three.Color;
import three.passes.Pass;

class ClearPass extends Pass {

  public var clearColor:Color;
  public var clearAlpha:Float;
  private var _oldClearColor:Color;

  public function new(clearColor:Color = null, clearAlpha:Float = 0) {
    super();

    this.needsSwap = false;

    this.clearColor = clearColor != null ? clearColor : new Color(0x000000);
    this.clearAlpha = clearAlpha != null ? clearAlpha : 0;
    this._oldClearColor = new Color();
  }

  public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic /*, deltaTime:Float, maskActive:Bool */) {

    var oldClearAlpha:Float;

    if (this.clearColor != null) {

      renderer.getClearColor(this._oldClearColor);
      oldClearAlpha = renderer.getClearAlpha();

      renderer.setClearColor(this.clearColor, this.clearAlpha);

    }

    renderer.setRenderTarget(this.renderToScreen ? null : readBuffer);
    renderer.clear();

    if (this.clearColor != null) {

      renderer.setClearColor(this._oldClearColor, oldClearAlpha);

    }

  }

}