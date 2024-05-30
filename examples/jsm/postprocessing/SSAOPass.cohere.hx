import js.three.*;
import js.three.extras.core.DataTexture;
import js.three.extras.core.DepthTexture;
import js.three.extras.renderers.passes.Pass;
import js.three.extras.renderers.shaders.CopyShader;
import js.three.extras.renderers.shaders.ShaderMaterial;
import js.three.extras.renderers.shaders.SSAOBlurShader;
import js.three.extras.renderers.shaders.SSAODepthShader;
import js.three.extras.renderers.shaders.SSAOShader;
import js.three.extras.renderers.shaders.UniformsUtils;
import js.three.extras.shaders.SimplexNoise;
import js.three.materials.MeshNormalMaterial;
import js.three.materials.parameters.Blending;
import js.three.materials.parameters.DepthTextureParam;
import js.three.materials.parameters.Side;
import js.three.math.Color;
import js.three.math.Matrix4;
import js.three.math.Vector3;
import js.three.objects.FullScreenQuad;
import js.three.renderers.WebGLRenderTarget;
import js.three.renderers.WebGLRenderTargetParameters;
import js.three.scenes.Scene;

class SSAOPass extends Pass {
	public var width:Int;
	public var height:Int;
	public var kernelRadius:Int;
	public var kernel:Array<Vector3>;
	public var noiseTexture:DataTexture;
	public var output:Int;
	public var minDistance:Float;
	public var maxDistance:Float;
	public var _visibilityCache:Map<Scene,Bool>;
	public var normalRenderTarget:WebGLRenderTarget;
	public var ssaoRenderTarget:WebGLRenderTarget;
	public var blurRenderTarget:WebGLRenderTarget;
	public var ssaoMaterial:ShaderMaterial;
	public var normalMaterial:MeshNormalMaterial;
	public var blurMaterial:ShaderMaterial;
	public var depthRenderMaterial:ShaderMaterial;
	public var copyMaterial:ShaderMaterial;
	public var fsQuad:FullScreenQuad;
	public var originalClearColor:Color;
	public var camera:Camera;
	public var scene:Scene;

	public function new(scene:Scene, camera:Camera, ?width:Int, ?height:Int, ?kernelSize:Int) {
		super();
		this.width = if (width != null) width else 512;
		this.height = if (height != null) height else 512;
		this.clear = true;
		this.camera = camera;
		this.scene = scene;
		this.kernelRadius = 8;
		this.kernel = [];
		this.noiseTexture = null;
		this.output = 0;
		this.minDistance = 0.005;
		this.maxDistance = 0.1;
		this._visibilityCache = new Map();
		this.generateSampleKernel(kernelSize);
		this.generateRandomKernelRotations();
		var depthTexture = new DepthTexture();
		depthTexture.format = js.three.DepthFormat.DepthStencil;
		depthTexture.type = js.three.UnsignedIntType.UnsignedInt248;
		var normalRenderTargetParameters = new WebGLRenderTargetParameters();
		normalRenderTargetParameters.minFilter = js.three.TextureFilter.Nearest;
		normalRenderTargetParameters.magFilter = js.three.TextureFilter.Nearest;
		normalRenderTargetParameters.type = js.three.TextureDataType.HalfFloat;
		normalRenderTargetParameters.depthTexture = depthTexture;
		this.normalRenderTarget = new WebGLRenderTarget(this.width, this.height, normalRenderTargetParameters);
		this.ssaoRenderTarget = new WebGLRenderTarget(this.width, this.height, { type: js.three.TextureDataType.HalfFloat });
		this.blurRenderTarget = this.ssaoRenderTarget.clone();
		this.ssaoMaterial = new ShaderMaterial({
			defines: { $from: SSAOShader.defines },
			uniforms: UniformsUtils.clone(SSAOShader.uniforms),
			vertexShader: SSAOShader.vertexShader,
			fragmentShader: SSAOShader.fragmentShader,
			blending: Blending.NoBlending
		});
		this.ssaoMaterial.defines['KERNEL_SIZE'] = kernelSize;
		this.ssaoMaterial.uniforms['tNormal'].value = this.normalRenderTarget.texture;
		this.ssaoMaterial.uniforms['tDepth'].value = this.normalRenderTarget.depthTexture;
		this.ssaoMaterial.uniforms['tNoise'].value = this.noiseTexture;
		this.ssaoMaterial.uniforms['kernel'].value = this.kernel;
		this.ssaoMaterial.uniforms['cameraNear'].value = this.camera.near;
		this.ssaoMaterial.uniforms['cameraFar'].value = this.camera.far;
		this.ssaoMaterial.uniforms['resolution'].value.set(this.width, this.height);
		this.ssaoMaterial.uniforms['cameraProjectionMatrix'].value.copy(this.camera.projectionMatrix);
		this.ssaoMaterial.uniforms['cameraInverseProjectionMatrix'].value.copy(this.camera.projectionMatrixInverse);
		this.normalMaterial = new MeshNormalMaterial();
		this.normalMaterial.blending = Blending.NoBlending;
		this.blurMaterial = new ShaderMaterial({
			defines: { $from: SSAOBlurShader.defines },
			uniforms: UniformsUtils.clone(SSAOBlurShader.uniforms),
			vertexShader: SSAOBlurShader.vertexShader,
			fragmentShader: SSAOBlurShader.fragmentShader
		});
		this.blurMaterial.uniforms['tDiffuse'].value = this.ssaoRenderTarget.texture;
		this.blurMaterial.uniforms['resolution'].value.set(this.width, this.height);
		this.depthRenderMaterial = new ShaderMaterial({
			defines: { $from: SSAODepthShader.defines },
			uniforms: UniformsUtils.clone(SSAODepthShader.uniforms),
			vertexShader: SSAODepthShader.vertexShader,
			fragmentShader: SSAODepthShader.fragmentShader,
			blending: Blending.NoBlending
		});
		this.depthRenderMaterial.uniforms['tDepth'].value = this.normalRenderTarget.depthTexture;
		this.depthRenderMaterial.uniforms['cameraNear'].value = this.camera.near;
		this.depthRenderMaterial.uniforms['cameraFar'].value = this.camera.far;
		this.copyMaterial = new ShaderMaterial({
			uniforms: UniformsUtils.clone(CopyShader.uniforms),
			vertexShader: CopyShader.vertexShader,
			fragmentShader: CopyShader.fragmentShader,
			transparent: true,
			depthTest: false,
			depthWrite: false,
			blendSrc: js.three.BlendFactor.DstColorFactor,
			blendDst: js.three.BlendFactor.ZeroFactor,
			blendEquation: js.three.BlendEquation.AddEquation,
			blendSrcAlpha: js.three.BlendFactor.DstAlphaFactor,
			blendDstAlpha: js.three.BlendFactor.ZeroFactor,
			blendEquationAlpha: js.three.BlendEquation.AddEquation
		});
		this.fsQuad = new FullScreenQuad(null);
	}

	public function dispose() {
		this.normalRenderTarget.dispose();
		this.ssaoRenderTarget.dispose();
		this.blurRenderTarget.dispose();
		this.normalMaterial.dispose();
		this.blurMaterial.dispose();
		this.copyMaterial.dispose();
		this.depthRenderMaterial.dispose();
		this.fsQuad.dispose();
	}

	public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget) {
		this.overrideVisibility();
		this.renderOverride(renderer, this.normalMaterial, this.normalRenderTarget, 0x7777ff, 1.0);
		this.restoreVisibility();
		this.ssaoMaterial.uniforms['kernelRadius'].value = this.kernelRadius;
		this.ssaoMaterial.uniforms['minDistance'].value = this.minDistance;
		this.ssaoMaterial.uniforms['maxDistance'].value = this.maxDistance;
		this.renderPass(renderer, this.ssaoMaterial, this.ssaoRenderTarget);
		this.renderPass(renderer, this.blurMaterial, this.blurRenderTarget);
		switch (this.output) {
			case SSAOPass.OUTPUT.SSAO:
				this.copyMaterial.uniforms['tDiffuse'].value = this.ssaoRenderTarget.texture;
				this.copyMaterial.blending = Blending.NoBlending;
				this.renderPass(renderer, this.copyMaterial, if (this.renderToScreen) null else writeBuffer);
				break;
			case SSAOPass.OUTPUT.Blur:
				this.copyMaterial.uniforms['tDiffuse'].value = this.blurRenderTarget.texture;
				this.copyMaterial.blending = Blending.NoBlending;
				this.renderPass(renderer, this.copyMaterial, if (this.renderToScreen) null else writeBuffer);
				break;
			case SSAOPass.OUTPUT.Depth:
				this.renderPass(renderer, this.depthRenderMaterial, if (this.renderToScreen) null else writeBuffer);
				break;
			case SSAOPass.OUTPUT.Normal:
				this.copyMaterial.uniforms['tDiffuse'].value = this.normalRenderTarget.texture;
				this.copyMaterial.blending = Blending.NoBlending;
				this.renderPass(renderer, this.copyMaterial, if (this.renderToScreen) null else writeBuffer);
				break;
			case SSAOPass.OUTPUT.Default:
				this.copyMaterial.uniforms['tDiffuse'].value = readBuffer.texture;
				this.copyMaterial.blending = Blending.NoBlending;
				this.renderPass(renderer, this.copyMaterial, if (this.renderToScreen) null else writeBuffer);
				this.copyMaterial.uniforms['tDiffuse'].value = this.blurRenderTarget.texture;
				this.copyMaterial.blending = Blending.CustomBlending;
				this.renderPass(renderer, this.copyMaterial, if (this.renderToScreen) null else writeBuffer);
				break;
			default:
				trace('THREE.SSAOPass: Unknown output type.');
		}
	}

	public function renderPass(renderer:WebGLRenderer, passMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, ?clearColor:Int, ?clearAlpha:Float) {
		renderer.getClearColor(this.originalClearColor);
		var originalClearAlpha = renderer.getClearAlpha();
		var originalAutoClear = renderer.autoClear;
		renderer.setRenderTarget(renderTarget);
		renderer.autoClear = false;
		if (clearColor != null && clearColor != null) {
			renderer.setClearColor(clearColor);
			renderer.setClearAlpha(if (clearAlpha != null) clearAlpha else 0.0);
			renderer.clear();
		}
		this.fsQuad.material = passMaterial;
		this.fsQuad.render(renderer);
		renderer.autoClear = originalAutoClear;
		renderer.setClearColor(this.originalClearColor);
		renderer.setClearAlpha(originalClearAlpha);
	}

	public function renderOverride(renderer:WebGLRenderer, overrideMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, ?clearColor:Int, ?clearAlpha:Float) {
		renderer.getClearColor(this.originalClearColor);
		var originalClearAlpha = renderer.getClearAlpha();
		var originalAutoClear = renderer.autoClear;
		renderer.setRenderTarget(renderTarget);
		renderer.autoClear = false;
		clearColor = if (overrideMaterial.clearColor != null) overrideMaterial.clearColor else clearColor;
		clearAlpha = if (overrideMaterial.clearAlpha != null) overrideMaterial.clearAlpha else clearAlpha;
		if (clearColor != null && clearColor != null) {
			renderer.setClearColor(clearColor);
			renderer.setClearAlpha(if (clearAlpha != null) clearAlpha else 0.0);
			renderer.clear();
		}
		this.scene.overrideMaterial = overrideMaterial;
		renderer.render(this.scene, this.camera);
		this.scene.overrideMaterial = null;
		renderer.autoClear = originalAutoClear;
		renderer.setClearColor(this.originalClearColor);
		renderer.setClearAlpha(originalClearAlpha);
	}

	public function setSize(width:Int, height:Int) {
		this.width = width;
		this.height = height;
		this.ssaoRenderTarget.setSize(width, height);
		this.normalRenderTarget.setSize(width, height);
		this.blurRenderTarget.setSize(width, height);
		this.ssaoMaterial.uniforms['resolution'].value.set(width, height);
		this.ssaoMaterial.uniforms['cameraProjectionMatrix'].value.copy(this.camera.projectionMatrix);
		this.ssaoMaterial.uniforms['cameraInverseProjectionMatrix'].value.copy(this.camera.projectionMatrixInverse);
		this.blurMaterial.uniforms['resolution'].value.set(width, height);
	}

	public function generateSampleKernel(?kernelSize:Int) {
		var kernel = this.kernel;
		var i = 0;
		while (i < kernelSize) {
			var sample = new Vector3();
			sample.x = Std.random() * 2 - 1;
			sample.y = Std.random() * 2 - 1;
			sample.z = Std.random();
			sample.normalize();
			var scale = i / kernelSize;
			scale = Math.lerp(0.1, 1, scale * scale);
			sample.multiplyScalar(scale);
			kernel.push(sample);
			i++;
		}
	}

	public function generateRandomKernelRotations() {
		var width = 4;
		var height = 4;
		var simplex = new SimplexNoise();
		var size = width * height;
		var data = new Float32Array(size);
		var i = 0;
		while (i < size) {
			var x = Std.random() * 2 - 1;
			var y = Std.random() * 2 - 1;
			var z = 0;
			data[i] = simplex.noise3d(x, y, z);
			i++;
		}
		this.noiseTexture = new DataTexture(data, width, height, js.three.PixelFormat.RedFormat, js.three.TextureDataType.FloatType);
		this.noiseTexture.wrapS = js.three.TextureWrapping.RepeatWrapping;
		this.noiseTexture.wrapT = js.three.TextureWrapping.RepeatWrapping;
		this.noiseTexture.needsUpdate = true;
	}

	public function overrideVisibility() {
		var scene = this.scene;
		var cache = this._visibilityCache;
		scene.traverse((object) -> {
			cache.set(object, object.visible);
			if (object.isPoints || object.isLine)
				object.visible = false;
		});
	}

	public function restoreVisibility() {
		var scene = this.scene;
		var cache = this._visibilityCache;
		scene.traverse((object) -> {
			var visible = cache.get(object);
			object.visible = visible;
		});
		cache.clear();
	}

	public static var OUTPUT:Array<String> = ['Default', 'SSAO', 'Blur', 'Depth', 'Normal'];
}