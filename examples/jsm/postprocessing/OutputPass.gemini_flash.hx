import three.ColorManagement;
import three.RawShaderMaterial;
import three.UniformsUtils;
import three.LinearToneMapping;
import three.ReinhardToneMapping;
import three.CineonToneMapping;
import three.AgXToneMapping;
import three.ACESFilmicToneMapping;
import three.NeutralToneMapping;
import three.SRGBTransfer;
import three.passes.Pass;
import three.passes.FullScreenQuad;
import three.shaders.OutputShader;

class OutputPass extends Pass {

	public var uniforms:Dynamic;
	public var material:RawShaderMaterial;
	public var fsQuad:FullScreenQuad;

	private var _outputColorSpace:Null<Int>;
	private var _toneMapping:Null<Int>;

	public function new() {
		super();

		//

		var shader = OutputShader;

		this.uniforms = UniformsUtils.clone(shader.uniforms);

		this.material = new RawShaderMaterial({
			name: shader.name,
			uniforms: this.uniforms,
			vertexShader: shader.vertexShader,
			fragmentShader: shader.fragmentShader
		});

		this.fsQuad = new FullScreenQuad(this.material);

		// internal cache

		this._outputColorSpace = null;
		this._toneMapping = null;
	}

	public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic/*, deltaTime:Float, maskActive:Bool*/) {

		this.uniforms['tDiffuse'].value = readBuffer.texture;
		this.uniforms['toneMappingExposure'].value = renderer.toneMappingExposure;

		// rebuild defines if required

		if (this._outputColorSpace != renderer.outputColorSpace || this._toneMapping != renderer.toneMapping) {

			this._outputColorSpace = renderer.outputColorSpace;
			this._toneMapping = renderer.toneMapping;

			this.material.defines = new haxe.ds.StringMap();

			if (ColorManagement.getTransfer(this._outputColorSpace) == SRGBTransfer) this.material.defines.set('SRGB_TRANSFER', '');

			if (this._toneMapping == LinearToneMapping) this.material.defines.set('LINEAR_TONE_MAPPING', '');
			else if (this._toneMapping == ReinhardToneMapping) this.material.defines.set('REINHARD_TONE_MAPPING', '');
			else if (this._toneMapping == CineonToneMapping) this.material.defines.set('CINEON_TONE_MAPPING', '');
			else if (this._toneMapping == ACESFilmicToneMapping) this.material.defines.set('ACES_FILMIC_TONE_MAPPING', '');
			else if (this._toneMapping == AgXToneMapping) this.material.defines.set('AGX_TONE_MAPPING', '');
			else if (this._toneMapping == NeutralToneMapping) this.material.defines.set('NEUTRAL_TONE_MAPPING', '');

			this.material.needsUpdate = true;
		}

		//

		if (this.renderToScreen) {

			renderer.setRenderTarget(null);
			this.fsQuad.render(renderer);

		} else {

			renderer.setRenderTarget(writeBuffer);
			if (this.clear) renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
			this.fsQuad.render(renderer);

		}
	}

	public function dispose() {
		this.material.dispose();
		this.fsQuad.dispose();
	}
}