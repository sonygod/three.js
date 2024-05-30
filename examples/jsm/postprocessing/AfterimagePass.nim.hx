import three.examples.jsm.postprocessing.Pass;
import three.examples.jsm.postprocessing.FullScreenQuad;
import three.examples.jsm.shaders.AfterimageShader;
import three.HalfFloatType;
import three.MeshBasicMaterial;
import three.NearestFilter;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.WebGLRenderTarget;

class AfterimagePass extends Pass {

	public var shader:AfterimageShader;
	public var uniforms:Dynamic;
	public var textureComp:WebGLRenderTarget;
	public var textureOld:WebGLRenderTarget;
	public var compFsMaterial:ShaderMaterial;
	public var compFsQuad:FullScreenQuad;
	public var copyFsMaterial:MeshBasicMaterial;
	public var copyFsQuad:FullScreenQuad;

	public function new(damp:Float = 0.96) {
		super();

		this.shader = new AfterimageShader();

		this.uniforms = UniformsUtils.clone(this.shader.uniforms);

		this.uniforms['damp'].value = damp;

		this.textureComp = new WebGLRenderTarget(window.innerWidth, window.innerHeight, {
			magFilter: NearestFilter,
			type: HalfFloatType
		});

		this.textureOld = new WebGLRenderTarget(window.innerWidth, window.innerHeight, {
			magFilter: NearestFilter,
			type: HalfFloatType
		});

		this.compFsMaterial = new ShaderMaterial({
			uniforms: this.uniforms,
			vertexShader: this.shader.vertexShader,
			fragmentShader: this.shader.fragmentShader
		});

		this.compFsQuad = new FullScreenQuad(this.compFsMaterial);

		this.copyFsMaterial = new MeshBasicMaterial();
		this.copyFsQuad = new FullScreenQuad(this.copyFsMaterial);
	}

	public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic/*, deltaTime:Dynamic, maskActive:Dynamic*/) {
		this.uniforms['tOld'].value = this.textureOld.texture;
		this.uniforms['tNew'].value = readBuffer.texture;

		renderer.setRenderTarget(this.textureComp);
		this.compFsQuad.render(renderer);

		this.copyFsQuad.material.map = this.textureComp.texture;

		if (this.renderToScreen) {
			renderer.setRenderTarget(null);
			this.copyFsQuad.render(renderer);
		} else {
			renderer.setRenderTarget(writeBuffer);

			if (this.clear) renderer.clear();

			this.copyFsQuad.render(renderer);
		}

		// Swap buffers.
		var temp = this.textureOld;
		this.textureOld = this.textureComp;
		this.textureComp = temp;
		// Now textureOld contains the latest image, ready for the next frame.
	}

	public function setSize(width:Int, height:Int) {
		this.textureComp.setSize(width, height);
		this.textureOld.setSize(width, height);
	}

	public function dispose() {
		this.textureComp.dispose();
		this.textureOld.dispose();

		this.compFsMaterial.dispose();
		this.copyFsMaterial.dispose();

		this.compFsQuad.dispose();
		this.copyFsQuad.dispose();
	}
}