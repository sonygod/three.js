import three.Clock;
import three.HalfFloatType;
import three.NoBlending;
import three.Vector2;
import three.WebGLRenderTarget;
import three.shaders.CopyShader;
import three.postprocessing.ShaderPass;
import three.postprocessing.MaskPass;
import three.postprocessing.ClearMaskPass;

class EffectComposer {

    public var renderer:Renderer;
    public var _pixelRatio:Float;
    public var _width:Int;
    public var _height:Int;
    public var renderTarget1:WebGLRenderTarget;
    public var renderTarget2:WebGLRenderTarget;
    public var writeBuffer:WebGLRenderTarget;
    public var readBuffer:WebGLRenderTarget;
    public var renderToScreen:Bool = true;
    public var passes:Array<Pass> = [];
    public var copyPass:ShaderPass;
    public var clock:Clock;

    public function new(renderer:Renderer, renderTarget:WebGLRenderTarget) {
        this.renderer = renderer;
        this._pixelRatio = renderer.getPixelRatio();

        if (renderTarget == null) {
            var size = renderer.getSize(new Vector2());
            this._width = size.width;
            this._height = size.height;

            renderTarget = new WebGLRenderTarget(this._width * this._pixelRatio, this._height * this._pixelRatio, { type: HalfFloatType.HALF_FLOAT });
            renderTarget.texture.name = 'EffectComposer.rt1';
        } else {
            this._width = renderTarget.width;
            this._height = renderTarget.height;
        }

        this.renderTarget1 = renderTarget;
        this.renderTarget2 = renderTarget.clone();
        this.renderTarget2.texture.name = 'EffectComposer.rt2';

        this.writeBuffer = this.renderTarget1;
        this.readBuffer = this.renderTarget2;

        this.copyPass = new ShaderPass(CopyShader);
        this.copyPass.material.blending = NoBlending;

        this.clock = new Clock();
    }

    public function swapBuffers():Void {
        var tmp = this.readBuffer;
        this.readBuffer = this.writeBuffer;
        this.writeBuffer = tmp;
    }

    public function addPass(pass:Pass):Void {
        this.passes.push(pass);
        pass.setSize(this._width * this._pixelRatio, this._height * this._pixelRatio);
    }

    public function insertPass(pass:Pass, index:Int):Void {
        this.passes.splice(index, 0, pass);
        pass.setSize(this._width * this._pixelRatio, this._height * this._pixelRatio);
    }

    public function removePass(pass:Pass):Void {
        var index = this.passes.indexOf(pass);

        if (index != -1) {
            this.passes.splice(index, 1);
        }
    }

    public function isLastEnabledPass(passIndex:Int):Bool {
        for (var i = passIndex + 1; i < this.passes.length; i++) {
            if (this.passes[i].enabled) {
                return false;
            }
        }

        return true;
    }

    public function render(deltaTime:Float):Void {
        if (deltaTime == null) {
            deltaTime = this.clock.getDelta();
        }

        var currentRenderTarget = this.renderer.getRenderTarget();
        var maskActive = false;

        for (var i = 0; i < this.passes.length; i++) {
            var pass = this.passes[i];

            if (!pass.enabled) continue;

            pass.renderToScreen = (this.renderToScreen && this.isLastEnabledPass(i));
            pass.render(this.renderer, this.writeBuffer, this.readBuffer, deltaTime, maskActive);

            if (pass.needsSwap) {
                if (maskActive) {
                    var context = this.renderer.getContext();
                    var stencil = this.renderer.state.buffers.stencil;

                    stencil.setFunc(context.NOTEQUAL, 1, 0xffffffff);

                    this.copyPass.render(this.renderer, this.writeBuffer, this.readBuffer, deltaTime);

                    stencil.setFunc(context.EQUAL, 1, 0xffffffff);
                }

                this.swapBuffers();
            }

            if (Type.resolveClass(MaskPass) != null) {
                if (Std.is(pass, MaskPass)) {
                    maskActive = true;
                } else if (Std.is(pass, ClearMaskPass)) {
                    maskActive = false;
                }
            }
        }

        this.renderer.setRenderTarget(currentRenderTarget);
    }

    public function reset(renderTarget:WebGLRenderTarget):Void {
        if (renderTarget == null) {
            var size = this.renderer.getSize(new Vector2());
            this._pixelRatio = this.renderer.getPixelRatio();
            this._width = size.width;
            this._height = size.height;

            renderTarget = this.renderTarget1.clone();
            renderTarget.setSize(this._width * this._pixelRatio, this._height * this._pixelRatio);
        }

        this.renderTarget1.dispose();
        this.renderTarget2.dispose();
        this.renderTarget1 = renderTarget;
        this.renderTarget2 = renderTarget.clone();

        this.writeBuffer = this.renderTarget1;
        this.readBuffer = this.renderTarget2;
    }

    public function setSize(width:Int, height:Int):Void {
        this._width = width;
        this._height = height;

        var effectiveWidth = this._width * this._pixelRatio;
        var effectiveHeight = this._height * this._pixelRatio;

        this.renderTarget1.setSize(effectiveWidth, effectiveHeight);
        this.renderTarget2.setSize(effectiveWidth, effectiveHeight);

        for (var i = 0; i < this.passes.length; i++) {
            this.passes[i].setSize(effectiveWidth, effectiveHeight);
        }
    }

    public function setPixelRatio(pixelRatio:Float):Void {
        this._pixelRatio = pixelRatio;

        this.setSize(this._width, this._height);
    }

    public function dispose():Void {
        this.renderTarget1.dispose();
        this.renderTarget2.dispose();

        this.copyPass.dispose();
    }
}