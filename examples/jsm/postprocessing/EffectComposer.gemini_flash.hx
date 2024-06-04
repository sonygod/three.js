import three.Clock;
import three.HalfFloatType;
import three.NoBlending;
import three.Vector2;
import three.WebGLRenderTarget;
import three.shaders.CopyShader;
import three.passes.ShaderPass;
import three.passes.MaskPass;
import three.passes.ClearMaskPass;

class EffectComposer {
	public var renderer:three.Renderer;
	public var _pixelRatio:Float;
	public var _width:Int;
	public var _height:Int;
	public var renderTarget1:WebGLRenderTarget;
	public var renderTarget2:WebGLRenderTarget;
	public var writeBuffer:WebGLRenderTarget;
	public var readBuffer:WebGLRenderTarget;
	public var renderToScreen:Bool;
	public var passes:Array<three.Pass>;
	public var copyPass:ShaderPass;
	public var clock:Clock;

	public function new(renderer:three.Renderer, renderTarget:WebGLRenderTarget = null) {
		this.renderer = renderer;
		this._pixelRatio = renderer.getPixelRatio();

		if (renderTarget == null) {
			var size = renderer.getSize(new Vector2());
			this._width = size.width;
			this._height = size.height;
			renderTarget = new WebGLRenderTarget(this._width * this._pixelRatio, this._height * this._pixelRatio, { type: HalfFloatType });
			renderTarget.texture.name = "EffectComposer.rt1";
		} else {
			this._width = renderTarget.width;
			this._height = renderTarget.height;
		}

		this.renderTarget1 = renderTarget;
		this.renderTarget2 = renderTarget.clone();
		this.renderTarget2.texture.name = "EffectComposer.rt2";

		this.writeBuffer = this.renderTarget1;
		this.readBuffer = this.renderTarget2;

		this.renderToScreen = true;

		this.passes = new Array<three.Pass>();

		this.copyPass = new ShaderPass(new CopyShader());
		this.copyPass.material.blending = NoBlending;

		this.clock = new Clock();
	}

	public function swapBuffers() {
		var tmp = this.readBuffer;
		this.readBuffer = this.writeBuffer;
		this.writeBuffer = tmp;
	}

	public function addPass(pass:three.Pass) {
		this.passes.push(pass);
		pass.setSize(this._width * this._pixelRatio, this._height * this._pixelRatio);
	}

	public function insertPass(pass:three.Pass, index:Int) {
		this.passes.splice(index, 0, pass);
		pass.setSize(this._width * this._pixelRatio, this._height * this._pixelRatio);
	}

	public function removePass(pass:three.Pass) {
		var index = this.passes.indexOf(pass);
		if (index != -1) {
			this.passes.splice(index, 1);
		}
	}

	public function isLastEnabledPass(passIndex:Int):Bool {
		for (i in passIndex + 1...this.passes.length) {
			if (this.passes[i].enabled) {
				return false;
			}
		}
		return true;
	}

	public function render(deltaTime:Float = null) {
		// deltaTime value is in seconds
		if (deltaTime == null) {
			deltaTime = this.clock.getDelta();
		}
		var currentRenderTarget = this.renderer.getRenderTarget();
		var maskActive = false;
		for (i in 0...this.passes.length) {
			var pass = this.passes[i];
			if (pass.enabled == false) continue;
			pass.renderToScreen = (this.renderToScreen && this.isLastEnabledPass(i));
			pass.render(this.renderer, this.writeBuffer, this.readBuffer, deltaTime, maskActive);
			if (pass.needsSwap) {
				if (maskActive) {
					var context = this.renderer.getContext();
					var stencil = this.renderer.state.buffers.stencil;
					//context.stencilFunc(context.NOTEQUAL, 1, 0xffffffff);
					stencil.setFunc(context.NOTEQUAL, 1, 0xffffffff);
					this.copyPass.render(this.renderer, this.writeBuffer, this.readBuffer, deltaTime);
					//context.stencilFunc(context.EQUAL, 1, 0xffffffff);
					stencil.setFunc(context.EQUAL, 1, 0xffffffff);
				}
				this.swapBuffers();
			}
			if (MaskPass != null) {
				if (Std.is(pass, MaskPass)) {
					maskActive = true;
				} else if (Std.is(pass, ClearMaskPass)) {
					maskActive = false;
				}
			}
		}
		this.renderer.setRenderTarget(currentRenderTarget);
	}

	public function reset(renderTarget:WebGLRenderTarget = null) {
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

	public function setSize(width:Int, height:Int) {
		this._width = width;
		this._height = height;
		var effectiveWidth = this._width * this._pixelRatio;
		var effectiveHeight = this._height * this._pixelRatio;
		this.renderTarget1.setSize(effectiveWidth, effectiveHeight);
		this.renderTarget2.setSize(effectiveWidth, effectiveHeight);
		for (i in 0...this.passes.length) {
			this.passes[i].setSize(effectiveWidth, effectiveHeight);
		}
	}

	public function setPixelRatio(pixelRatio:Float) {
		this._pixelRatio = pixelRatio;
		this.setSize(this._width, this._height);
	}

	public function dispose() {
		this.renderTarget1.dispose();
		this.renderTarget2.dispose();
		this.copyPass.dispose();
	}
}