import three.js.examples.jsm.postprocessing.SAOShader;
import three.js.examples.jsm.postprocessing.DepthLimitedBlurShader;
import three.js.examples.jsm.postprocessing.BlurShaderUtils;
import three.js.examples.jsm.postprocessing.CopyShader;
import three.js.examples.jsm.postprocessing.Pass;
import three.js.examples.jsm.postprocessing.FullScreenQuad;
import three.js.examples.jsm.shaders.SAOShader;
import three.js.examples.jsm.shaders.DepthLimitedBlurShader;
import three.js.examples.jsm.shaders.CopyShader;
import three.js.examples.jsm.shaders.AddEquation;
import three.js.examples.jsm.shaders.Color;
import three.js.examples.jsm.shaders.CustomBlending;
import three.js.examples.jsm.shaders.DepthTexture;
import three.js.examples.jsm.shaders.DstAlphaFactor;
import three.js.examples.jsm.shaders.DstColorFactor;
import three.js.examples.jsm.shaders.HalfFloatType;
import three.js.examples.jsm.shaders.MeshNormalMaterial;
import three.js.examples.jsm.shaders.NearestFilter;
import three.js.examples.jsm.shaders.NoBlending;
import three.js.examples.jsm.shaders.ShaderMaterial;
import three.js.examples.jsm.shaders.UniformsUtils;
import three.js.examples.jsm.shaders.DepthStencilFormat;
import three.js.examples.jsm.shaders.UnsignedInt248Type;
import three.js.examples.jsm.shaders.Vector2;
import three.js.examples.jsm.shaders.WebGLRenderTarget;
import three.js.examples.jsm.shaders.ZeroFactor;

class SAOPass extends Pass {

	public var scene:Scene;
	public var camera:Camera;
	public var resolution:Vector2;
	public var saoRenderTarget:WebGLRenderTarget;
	public var blurIntermediateRenderTarget:WebGLRenderTarget;
	public var normalRenderTarget:WebGLRenderTarget;
	public var normalMaterial:MeshNormalMaterial;
	public var saoMaterial:ShaderMaterial;
	public var vBlurMaterial:ShaderMaterial;
	public var hBlurMaterial:ShaderMaterial;
	public var materialCopy:ShaderMaterial;
	public var fsQuad:FullScreenQuad;

	public var params:Dynamic;
	public var originalClearColor:Color;
	public var _oldClearColor:Color;
	public var oldClearAlpha:Float;

	public function new(scene:Scene, camera:Camera, resolution:Vector2 = new Vector2(256, 256)) {
		super();

		this.scene = scene;
		this.camera = camera;

		this.clear = true;
		this.needsSwap = false;

		this.originalClearColor = new Color();
		this._oldClearColor = new Color();
		this.oldClearAlpha = 1;

		this.params = {
			output: 0,
			saoBias: 0.5,
			saoIntensity: 0.18,
			saoScale: 1,
			saoKernelRadius: 100,
			saoMinResolution: 0,
			saoBlur: true,
			saoBlurRadius: 8,
			saoBlurStdDev: 4,
			saoBlurDepthCutoff: 0.01
		};

		this.resolution = new Vector2(resolution.x, resolution.y);

		this.saoRenderTarget = new WebGLRenderTarget(this.resolution.x, this.resolution.y, { type: HalfFloatType });
		this.blurIntermediateRenderTarget = this.saoRenderTarget.clone();

		var depthTexture = new DepthTexture();
		depthTexture.format = DepthStencilFormat;
		depthTexture.type = UnsignedInt248Type;

		this.normalRenderTarget = new WebGLRenderTarget(this.resolution.x, this.resolution.y, {
			minFilter: NearestFilter,
			magFilter: NearestFilter,
			type: HalfFloatType,
			depthTexture: depthTexture
		});

		this.normalMaterial = new MeshNormalMaterial();
		this.normalMaterial.blending = NoBlending;

		this.saoMaterial = new ShaderMaterial({
			defines: Object.merge(SAOShader.defines),
			fragmentShader: SAOShader.fragmentShader,
			vertexShader: SAOShader.vertexShader,
			uniforms: UniformsUtils.clone(SAOShader.uniforms)
		});
		this.saoMaterial.defines['PERSPECTIVE_CAMERA'] = this.camera.isPerspectiveCamera ? 1 : 0;
		this.saoMaterial.uniforms['tDepth'].value = depthTexture;
		this.saoMaterial.uniforms['tNormal'].value = this.normalRenderTarget.texture;
		this.saoMaterial.uniforms['size'].value.set(this.resolution.x, this.resolution.y);
		this.saoMaterial.uniforms['cameraInverseProjectionMatrix'].value.copy(this.camera.projectionMatrixInverse);
		this.saoMaterial.uniforms['cameraProjectionMatrix'].value = this.camera.projectionMatrix;
		this.saoMaterial.blending = NoBlending;

		this.vBlurMaterial = new ShaderMaterial({
			uniforms: UniformsUtils.clone(DepthLimitedBlurShader.uniforms),
			defines: Object.merge(DepthLimitedBlurShader.defines),
			vertexShader: DepthLimitedBlurShader.vertexShader,
			fragmentShader: DepthLimitedBlurShader.fragmentShader
		});
		this.vBlurMaterial.defines['DEPTH_PACKING'] = 0;
		this.vBlurMaterial.defines['PERSPECTIVE_CAMERA'] = this.camera.isPerspectiveCamera ? 1 : 0;
		this.vBlurMaterial.uniforms['tDiffuse'].value = this.saoRenderTarget.texture;
		this.vBlurMaterial.uniforms['tDepth'].value = depthTexture;
		this.vBlurMaterial.uniforms['size'].value.set(this.resolution.x, this.resolution.y);
		this.vBlurMaterial.blending = NoBlending;

		this.hBlurMaterial = new ShaderMaterial({
			uniforms: UniformsUtils.clone(DepthLimitedBlurShader.uniforms),
			defines: Object.merge(DepthLimitedBlurShader.defines),
			vertexShader: DepthLimitedBlurShader.vertexShader,
			fragmentShader: DepthLimitedBlurShader.fragmentShader
		});
		this.hBlurMaterial.defines['DEPTH_PACKING'] = 0;
		this.hBlurMaterial.defines['PERSPECTIVE_CAMERA'] = this.camera.isPerspectiveCamera ? 1 : 0;
		this.hBlurMaterial.uniforms['tDiffuse'].value = this.blurIntermediateRenderTarget.texture;
		this.hBlurMaterial.uniforms['tDepth'].value = depthTexture;
		this.hBlurMaterial.uniforms['size'].value.set(this.resolution.x, this.resolution.y);
		this.hBlurMaterial.blending = NoBlending;

		this.materialCopy = new ShaderMaterial({
			uniforms: UniformsUtils.clone(CopyShader.uniforms),
			vertexShader: CopyShader.vertexShader,
			fragmentShader: CopyShader.fragmentShader,
			blending: NoBlending
		});
		this.materialCopy.transparent = true;
		this.materialCopy.depthTest = false;
		this.materialCopy.depthWrite = false;
		this.materialCopy.blending = CustomBlending;
		this.materialCopy.blendSrc = DstColorFactor;
		this.materialCopy.blendDst = ZeroFactor;
		this.materialCopy.blendEquation = AddEquation;
		this.materialCopy.blendSrcAlpha = DstAlphaFactor;
		this.materialCopy.blendDstAlpha = ZeroFactor;
		this.materialCopy.blendEquationAlpha = AddEquation;

		this.fsQuad = new FullScreenQuad(null);
	}

	public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, deltaTime:Float, maskActive:Bool) {
		// ...
	}

	public function setSize(width:Int, height:Int) {
		// ...
	}

	public function dispose() {
		// ...
	}

}

SAOPass.OUTPUT = {
	'Default': 0,
	'SAO': 1,
	'Normal': 2
};

export SAOPass;