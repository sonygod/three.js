import three.extras.passes.Pass;
import three.extras.passes.FullScreenQuad;
import three.math.Vector2;
import three.materials.MeshNormalMaterial;
import three.materials.ShaderMaterial;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import three.cameras.Camera;
import three.textures.DepthTexture;
import three.textures.Texture;
import three.renderers.WebGLRenderTarget;
import three.math.Color;
import three.constants.BlendingEquation;
import three.constants.BlendingFactorDest;
import three.constants.BlendingFactorSrc;
import three.constants.Blending;
import three.constants.DepthStencilFormat;
import three.constants.UnsignedInt248Type;
import three.constants.HalfFloatType;
import three.constants.NearestFilter;
import three.constants.RGBAFormat;
import three.constants.UnsignedByteType;
import three.utils.UniformsUtils;
import three.shaders.SAOShader;
import three.shaders.DepthLimitedBlurShader;
import three.shaders.BlurShaderUtils;
import three.shaders.CopyShader;

/**
 * SAO implementation inspired from bhouston previous SAO work
 */
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

	public var params:SAOPassParams;
	public var originalClearColor:Color;
	public var _oldClearColor:Color;
	public var oldClearAlpha:Float;

	public var prevStdDev:Float;
	public var prevNumSamples:Int;

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
		this.normalMaterial.blending = Blending.NoBlending;

		this.saoMaterial = new ShaderMaterial({
			defines:  cast SAOShader.defines,
			fragmentShader: SAOShader.fragmentShader,
			vertexShader: SAOShader.vertexShader,
			uniforms: UniformsUtils.clone(SAOShader.uniforms)
		});
		this.saoMaterial.defines["PERSPECTIVE_CAMERA"] = this.camera.isPerspectiveCamera ? 1 : 0;
		this.saoMaterial.uniforms["tDepth"].value = depthTexture;
		this.saoMaterial.uniforms["tNormal"].value = this.normalRenderTarget.texture;
		this.saoMaterial.uniforms["size"].value.set(this.resolution.x, this.resolution.y);
		this.saoMaterial.uniforms["cameraInverseProjectionMatrix"].value.copy(this.camera.projectionMatrixInverse);
		this.saoMaterial.uniforms["cameraProjectionMatrix"].value = this.camera.projectionMatrix;
		this.saoMaterial.blending = Blending.NoBlending;

		this.vBlurMaterial = new ShaderMaterial({
			uniforms: UniformsUtils.clone(DepthLimitedBlurShader.uniforms),
			defines: cast DepthLimitedBlurShader.defines,
			vertexShader: DepthLimitedBlurShader.vertexShader,
			fragmentShader: DepthLimitedBlurShader.fragmentShader
		});
		this.vBlurMaterial.defines["DEPTH_PACKING"] = 0;
		this.vBlurMaterial.defines["PERSPECTIVE_CAMERA"] = this.camera.isPerspectiveCamera ? 1 : 0;
		this.vBlurMaterial.uniforms["tDiffuse"].value = this.saoRenderTarget.texture;
		this.vBlurMaterial.uniforms["tDepth"].value = depthTexture;
		this.vBlurMaterial.uniforms["size"].value.set(this.resolution.x, this.resolution.y);
		this.vBlurMaterial.blending = Blending.NoBlending;

		this.hBlurMaterial = new ShaderMaterial({
			uniforms: UniformsUtils.clone(DepthLimitedBlurShader.uniforms),
			defines: cast DepthLimitedBlurShader.defines,
			vertexShader: DepthLimitedBlurShader.vertexShader,
			fragmentShader: DepthLimitedBlurShader.fragmentShader
		});
		this.hBlurMaterial.defines["DEPTH_PACKING"] = 0;
		this.hBlurMaterial.defines["PERSPECTIVE_CAMERA"] = this.camera.isPerspectiveCamera ? 1 : 0;
		this.hBlurMaterial.uniforms["tDiffuse"].value = this.blurIntermediateRenderTarget.texture;
		this.hBlurMaterial.uniforms["tDepth"].value = depthTexture;
		this.hBlurMaterial.uniforms["size"].value.set(this.resolution.x, this.resolution.y);
		this.hBlurMaterial.blending = Blending.NoBlending;

		this.materialCopy = new ShaderMaterial({
			uniforms: UniformsUtils.clone(CopyShader.uniforms),
			vertexShader: CopyShader.vertexShader,
			fragmentShader: CopyShader.fragmentShader,
			blending: Blending.NoBlending
		});
		this.materialCopy.transparent = true;
		this.materialCopy.depthTest = false;
		this.materialCopy.depthWrite = false;
		this.materialCopy.blending = Blending.CustomBlending;
		this.materialCopy.blendSrc = BlendingFactorSrc.DstColorFactor;
		this.materialCopy.blendDst = BlendingFactorDest.ZeroFactor;
		this.materialCopy.blendEquation = BlendingEquation.AddEquation;
		this.materialCopy.blendSrcAlpha = BlendingFactorSrc.DstAlphaFactor;
		this.materialCopy.blendDstAlpha = BlendingFactorDest.ZeroFactor;
		this.materialCopy.blendEquationAlpha = BlendingEquation.AddEquation;

		this.fsQuad = new FullScreenQuad(null);
	}

	public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget):Void {
		if (this.renderToScreen) {
			this.materialCopy.blending = Blending.NoBlending;
			this.materialCopy.uniforms["tDiffuse"].value = readBuffer.texture;
			this.materialCopy.needsUpdate = true;
			this.renderPass(renderer, this.materialCopy, null);
		}

		renderer.getClearColor(this._oldClearColor);
		this.oldClearAlpha = renderer.getClearAlpha();
		var oldAutoClear = renderer.autoClear;
		renderer.autoClear = false;

		this.saoMaterial.uniforms["bias"].value = this.params.saoBias;
		this.saoMaterial.uniforms["intensity"].value = this.params.saoIntensity;
		this.saoMaterial.uniforms["scale"].value = this.params.saoScale;
		this.saoMaterial.uniforms["kernelRadius"].value = this.params.saoKernelRadius;
		this.saoMaterial.uniforms["minResolution"].value = this.params.saoMinResolution;
		this.saoMaterial.uniforms["cameraNear"].value = this.camera.near;
		this.saoMaterial.uniforms["cameraFar"].value = this.camera.far;

		var depthCutoff = this.params.saoBlurDepthCutoff * (this.camera.far - this.camera.near);
		this.vBlurMaterial.uniforms["depthCutoff"].value = depthCutoff;
		this.hBlurMaterial.uniforms["depthCutoff"].value = depthCutoff;

		this.vBlurMaterial.uniforms["cameraNear"].value = this.camera.near;
		this.vBlurMaterial.uniforms["cameraFar"].value = this.camera.far;
		this.hBlurMaterial.uniforms["cameraNear"].value = this.camera.near;
		this.hBlurMaterial.uniforms["cameraFar"].value = this.camera.far;

		this.params.saoBlurRadius = Std.int(this.params.saoBlurRadius);
		if ((this.prevStdDev != this.params.saoBlurStdDev) || (this.prevNumSamples != this.params.saoBlurRadius)) {
			BlurShaderUtils.configure(this.vBlurMaterial, this.params.saoBlurRadius, this.params.saoBlurStdDev, new Vector2(0, 1));
			BlurShaderUtils.configure(this.hBlurMaterial, this.params.saoBlurRadius, this.params.saoBlurStdDev, new Vector2(1, 0));
			this.prevStdDev = this.params.saoBlurStdDev;
			this.prevNumSamples = this.params.saoBlurRadius;
		}

		this.renderOverride(renderer, this.normalMaterial, this.normalRenderTarget, 0x7777ff, 1.0);

		this.renderPass(renderer, this.saoMaterial, this.saoRenderTarget, 0xffffff, 1.0);

		if (this.params.saoBlur) {
			this.renderPass(renderer, this.vBlurMaterial, this.blurIntermediateRenderTarget, 0xffffff, 1.0);
			this.renderPass(renderer, this.hBlurMaterial, this.saoRenderTarget, 0xffffff, 1.0);
		}

		var outputMaterial = this.materialCopy;

		if (this.params.output == SAOPass.OUTPUT.Normal) {
			this.materialCopy.uniforms["tDiffuse"].value = this.normalRenderTarget.texture;
			this.materialCopy.needsUpdate = true;
		} else {
			this.materialCopy.uniforms["tDiffuse"].value = this.saoRenderTarget.texture;
			this.materialCopy.needsUpdate = true;
		}

		if (this.params.output == SAOPass.OUTPUT.Default) {
			outputMaterial.blending = Blending.CustomBlending;
		} else {
			outputMaterial.blending = Blending.NoBlending;
		}

		this.renderPass(renderer, outputMaterial, this.renderToScreen ? null : readBuffer);

		renderer.setClearColor(this._oldClearColor, this.oldClearAlpha);
		renderer.autoClear = oldAutoClear;
	}

	public function renderPass(renderer:WebGLRenderer, passMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, clearColor:Int = -1, clearAlpha:Float = 0.0):Void {
		renderer.getClearColor(this.originalClearColor);
		var originalClearAlpha = renderer.getClearAlpha();
		var originalAutoClear = renderer.autoClear;

		renderer.setRenderTarget(renderTarget);

		renderer.autoClear = false;
		if (clearColor != -1) {
			renderer.setClearColor(clearColor);
			renderer.setClearAlpha(clearAlpha);
			renderer.clear();
		}

		this.fsQuad.material = passMaterial;
		this.fsQuad.render(renderer);

		renderer.autoClear = originalAutoClear;
		renderer.setClearColor(this.originalClearColor);
		renderer.setClearAlpha(originalClearAlpha);
	}

	public function renderOverride(renderer:WebGLRenderer, overrideMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, clearColor:Int = -1, clearAlpha:Float = 0.0):Void {
		renderer.getClearColor(this.originalClearColor);
		var originalClearAlpha = renderer.getClearAlpha();
		var originalAutoClear = renderer.autoClear;

		renderer.setRenderTarget(renderTarget);
		renderer.autoClear = false;

		clearColor = overrideMaterial.clearColor != null ? overrideMaterial.clearColor : clearColor;
		clearAlpha = overrideMaterial.clearAlpha != null ? overrideMaterial.clearAlpha : clearAlpha;
		if (clearColor != -1) {
			renderer.setClearColor(clearColor);
			renderer.setClearAlpha(clearAlpha);
			renderer.clear();
		}

		this.scene.overrideMaterial = overrideMaterial;
		renderer.render(this.scene, this.camera);
		this.scene.overrideMaterial = null;

		renderer.autoClear = originalAutoClear;
		renderer.setClearColor(this.originalClearColor);
		renderer.setClearAlpha(originalClearAlpha);
	}

	public function setSize(width:Int, height:Int):Void {
		this.saoRenderTarget.setSize(width, height);
		this.blurIntermediateRenderTarget.setSize(width, height);
		this.normalRenderTarget.setSize(width, height);

		this.saoMaterial.uniforms["size"].value.set(width, height);
		this.saoMaterial.uniforms["cameraInverseProjectionMatrix"].value.copy(this.camera.projectionMatrixInverse);
		this.saoMaterial.uniforms["cameraProjectionMatrix"].value = this.camera.projectionMatrix;
		this.saoMaterial.needsUpdate = true;

		this.vBlurMaterial.uniforms["size"].value.set(width, height);
		this.vBlurMaterial.needsUpdate = true;

		this.hBlurMaterial.uniforms["size"].value.set(width, height);
		this.hBlurMaterial.needsUpdate = true;
	}

	public function dispose():Void {
		this.saoRenderTarget.dispose();
		this.blurIntermediateRenderTarget.dispose();
		this.normalRenderTarget.dispose();

		this.normalMaterial.dispose();
		this.saoMaterial.dispose();
		this.vBlurMaterial.dispose();
		this.hBlurMaterial.dispose();
		this.materialCopy.dispose();

		this.fsQuad.dispose();
	}

}

class SAOPassParams {
	public var output:Int;
	public var saoBias:Float;
	public var saoIntensity:Float;
	public var saoScale:Float;
	public var saoKernelRadius:Int;
	public var saoMinResolution:Int;
	public var saoBlur:Bool;
	public var saoBlurRadius:Int;
	public var saoBlurStdDev:Float;
	public var saoBlurDepthCutoff:Float;
}

SAOPass.OUTPUT = {
	Default: 0,
	SAO: 1,
	Normal: 2
};