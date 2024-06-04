import three.AddEquation;
import three.Color;
import three.CustomBlending;
import three.DataTexture;
import three.DepthTexture;
import three.DepthStencilFormat;
import three.DstAlphaFactor;
import three.DstColorFactor;
import three.HalfFloatType;
import three.MeshNormalMaterial;
import three.NearestFilter;
import three.NoBlending;
import three.RepeatWrapping;
import three.RGBAFormat;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.UnsignedByteType;
import three.UnsignedInt248Type;
import three.WebGLRenderTarget;
import three.ZeroFactor;
import three.Pass;
import three.FullScreenQuad;
import three.Math.SimplexNoise;
import shaders.GTAOShader;
import shaders.GTAODepthShader;
import shaders.GTAOBlendShader;
import shaders.PoissonDenoiseShader;
import shaders.CopyShader;

class GTAOPass extends Pass {

	var width:Int;
	var height:Int;
	var camera:three.Camera;
	var scene:three.Scene;
	var output:Int;
	var _renderGBuffer:Bool;
	var _visibilityCache:Map<three.Object3D,Bool>;
	var blendIntensity:Float;

	var pdRings:Float;
	var pdRadiusExponent:Float;
	var pdSamples:Int;

	var gtaoNoiseTexture:DataTexture;
	var pdNoiseTexture:DataTexture;

	var gtaoRenderTarget:WebGLRenderTarget;
	var pdRenderTarget:WebGLRenderTarget;

	var gtaoMaterial:ShaderMaterial;
	var normalMaterial:MeshNormalMaterial;
	var pdMaterial:ShaderMaterial;
	var depthRenderMaterial:ShaderMaterial;
	var copyMaterial:ShaderMaterial;
	var blendMaterial:ShaderMaterial;

	var fsQuad:FullScreenQuad;

	var originalClearColor:Color;

	var depthTexture:DepthTexture;
	var normalTexture:DataTexture;

	var normalRenderTarget:WebGLRenderTarget;

	public function new(scene:three.Scene, camera:three.Camera, width:Int = 512, height:Int = 512, parameters:Dynamic = null, aoParameters:Dynamic = null, pdParameters:Dynamic = null) {
		super();
		this.width = width;
		this.height = height;
		this.clear = true;
		this.camera = camera;
		this.scene = scene;
		this.output = 0;
		this._renderGBuffer = true;
		this._visibilityCache = new Map();
		this.blendIntensity = 1.;
		this.pdRings = 2.;
		this.pdRadiusExponent = 2.;
		this.pdSamples = 16;
		this.gtaoNoiseTexture = generateMagicSquareNoise();
		this.pdNoiseTexture = this.generateNoise();
		this.gtaoRenderTarget = new WebGLRenderTarget(width, height, {type: HalfFloatType});
		this.pdRenderTarget = this.gtaoRenderTarget.clone();
		this.gtaoMaterial = new ShaderMaterial({
			defines: cast GTAOShader.defines,
			uniforms: UniformsUtils.clone(GTAOShader.uniforms),
			vertexShader: GTAOShader.vertexShader,
			fragmentShader: GTAOShader.fragmentShader,
			blending: NoBlending,
			depthTest: false,
			depthWrite: false
		});
		this.gtaoMaterial.defines.PERSPECTIVE_CAMERA = camera.isPerspectiveCamera ? 1 : 0;
		this.gtaoMaterial.uniforms.tNoise.value = this.gtaoNoiseTexture;
		this.gtaoMaterial.uniforms.resolution.value.set(width, height);
		this.gtaoMaterial.uniforms.cameraNear.value = camera.near;
		this.gtaoMaterial.uniforms.cameraFar.value = camera.far;
		this.normalMaterial = new MeshNormalMaterial();
		this.normalMaterial.blending = NoBlending;
		this.pdMaterial = new ShaderMaterial({
			defines: cast PoissonDenoiseShader.defines,
			uniforms: UniformsUtils.clone(PoissonDenoiseShader.uniforms),
			vertexShader: PoissonDenoiseShader.vertexShader,
			fragmentShader: PoissonDenoiseShader.fragmentShader,
			depthTest: false,
			depthWrite: false
		});
		this.pdMaterial.uniforms.tDiffuse.value = this.gtaoRenderTarget.texture;
		this.pdMaterial.uniforms.tNoise.value = this.pdNoiseTexture;
		this.pdMaterial.uniforms.resolution.value.set(width, height);
		this.pdMaterial.uniforms.lumaPhi.value = 10;
		this.pdMaterial.uniforms.depthPhi.value = 2;
		this.pdMaterial.uniforms.normalPhi.value = 3;
		this.pdMaterial.uniforms.radius.value = 8;
		this.depthRenderMaterial = new ShaderMaterial({
			defines: cast GTAODepthShader.defines,
			uniforms: UniformsUtils.clone(GTAODepthShader.uniforms),
			vertexShader: GTAODepthShader.vertexShader,
			fragmentShader: GTAODepthShader.fragmentShader,
			blending: NoBlending
		});
		this.depthRenderMaterial.uniforms.cameraNear.value = camera.near;
		this.depthRenderMaterial.uniforms.cameraFar.value = camera.far;
		this.copyMaterial = new ShaderMaterial({
			uniforms: UniformsUtils.clone(CopyShader.uniforms),
			vertexShader: CopyShader.vertexShader,
			fragmentShader: CopyShader.fragmentShader,
			transparent: true,
			depthTest: false,
			depthWrite: false,
			blendSrc: DstColorFactor,
			blendDst: ZeroFactor,
			blendEquation: AddEquation,
			blendSrcAlpha: DstAlphaFactor,
			blendDstAlpha: ZeroFactor,
			blendEquationAlpha: AddEquation
		});
		this.blendMaterial = new ShaderMaterial({
			uniforms: UniformsUtils.clone(GTAOBlendShader.uniforms),
			vertexShader: GTAOBlendShader.vertexShader,
			fragmentShader: GTAOBlendShader.fragmentShader,
			transparent: true,
			depthTest: false,
			depthWrite: false,
			blending: CustomBlending,
			blendSrc: DstColorFactor,
			blendDst: ZeroFactor,
			blendEquation: AddEquation,
			blendSrcAlpha: DstAlphaFactor,
			blendDstAlpha: ZeroFactor,
			blendEquationAlpha: AddEquation
		});
		this.fsQuad = new FullScreenQuad(null);
		this.originalClearColor = new Color();
		this.setGBuffer(parameters ? parameters.depthTexture : null, parameters ? parameters.normalTexture : null);
		if (aoParameters != null) {
			this.updateGtaoMaterial(aoParameters);
		}
		if (pdParameters != null) {
			this.updatePdMaterial(pdParameters);
		}
	}

	public function dispose():Void {
		this.gtaoNoiseTexture.dispose();
		this.pdNoiseTexture.dispose();
		this.normalRenderTarget.dispose();
		this.gtaoRenderTarget.dispose();
		this.pdRenderTarget.dispose();
		this.normalMaterial.dispose();
		this.pdMaterial.dispose();
		this.copyMaterial.dispose();
		this.depthRenderMaterial.dispose();
		this.fsQuad.dispose();
	}

	public function get gtaoMap():DataTexture {
		return this.pdRenderTarget.texture;
	}

	public function setGBuffer(depthTexture:DepthTexture, normalTexture:DataTexture):Void {
		if (depthTexture != null) {
			this.depthTexture = depthTexture;
			this.normalTexture = normalTexture;
			this._renderGBuffer = false;
		} else {
			this.depthTexture = new DepthTexture();
			this.depthTexture.format = DepthStencilFormat;
			this.depthTexture.type = UnsignedInt248Type;
			this.normalRenderTarget = new WebGLRenderTarget(this.width, this.height, {
				minFilter: NearestFilter,
				magFilter: NearestFilter,
				type: HalfFloatType,
				depthTexture: this.depthTexture
			});
			this.normalTexture = this.normalRenderTarget.texture;
			this._renderGBuffer = true;
		}
		var normalVectorType = (this.normalTexture != null) ? 1 : 0;
		var depthValueSource = (this.depthTexture == this.normalTexture) ? "w" : "x";
		this.gtaoMaterial.defines.NORMAL_VECTOR_TYPE = normalVectorType;
		this.gtaoMaterial.defines.DEPTH_SWIZZLING = depthValueSource;
		this.gtaoMaterial.uniforms.tNormal.value = this.normalTexture;
		this.gtaoMaterial.uniforms.tDepth.value = this.depthTexture;
		this.pdMaterial.defines.NORMAL_VECTOR_TYPE = normalVectorType;
		this.pdMaterial.defines.DEPTH_SWIZZLING = depthValueSource;
		this.pdMaterial.uniforms.tNormal.value = this.normalTexture;
		this.pdMaterial.uniforms.tDepth.value = this.depthTexture;
		this.depthRenderMaterial.uniforms.tDepth.value = this.normalRenderTarget.depthTexture;
	}

	public function setSceneClipBox(box:three.Box3):Void {
		if (box != null) {
			this.gtaoMaterial.needsUpdate = this.gtaoMaterial.defines.SCENE_CLIP_BOX != 1;
			this.gtaoMaterial.defines.SCENE_CLIP_BOX = 1;
			this.gtaoMaterial.uniforms.sceneBoxMin.value.copy(box.min);
			this.gtaoMaterial.uniforms.sceneBoxMax.value.copy(box.max);
		} else {
			this.gtaoMaterial.needsUpdate = this.gtaoMaterial.defines.SCENE_CLIP_BOX == 0;
			this.gtaoMaterial.defines.SCENE_CLIP_BOX = 0;
		}
	}

	public function updateGtaoMaterial(parameters:Dynamic):Void {
		if (parameters.radius != null) {
			this.gtaoMaterial.uniforms.radius.value = parameters.radius;
		}
		if (parameters.distanceExponent != null) {
			this.gtaoMaterial.uniforms.distanceExponent.value = parameters.distanceExponent;
		}
		if (parameters.thickness != null) {
			this.gtaoMaterial.uniforms.thickness.value = parameters.thickness;
		}
		if (parameters.distanceFallOff != null) {
			this.gtaoMaterial.uniforms.distanceFallOff.value = parameters.distanceFallOff;
			this.gtaoMaterial.needsUpdate = true;
		}
		if (parameters.scale != null) {
			this.gtaoMaterial.uniforms.scale.value = parameters.scale;
		}
		if (parameters.samples != null && parameters.samples != this.gtaoMaterial.defines.SAMPLES) {
			this.gtaoMaterial.defines.SAMPLES = parameters.samples;
			this.gtaoMaterial.needsUpdate = true;
		}
		if (parameters.screenSpaceRadius != null && (parameters.screenSpaceRadius ? 1 : 0) != this.gtaoMaterial.defines.SCREEN_SPACE_RADIUS) {
			this.gtaoMaterial.defines.SCREEN_SPACE_RADIUS = parameters.screenSpaceRadius ? 1 : 0;
			this.gtaoMaterial.needsUpdate = true;
		}
	}

	public function updatePdMaterial(parameters:Dynamic):Void {
		var updateShader = false;
		if (parameters.lumaPhi != null) {
			this.pdMaterial.uniforms.lumaPhi.value = parameters.lumaPhi;
		}
		if (parameters.depthPhi != null) {
			this.pdMaterial.uniforms.depthPhi.value = parameters.depthPhi;
		}
		if (parameters.normalPhi != null) {
			this.pdMaterial.uniforms.normalPhi.value = parameters.normalPhi;
		}
		if (parameters.radius != null && parameters.radius != this.radius) {
			this.pdMaterial.uniforms.radius.value = parameters.radius;
		}
		if (parameters.radiusExponent != null && parameters.radiusExponent != this.pdRadiusExponent) {
			this.pdRadiusExponent = parameters.radiusExponent;
			updateShader = true;
		}
		if (parameters.rings != null && parameters.rings != this.pdRings) {
			this.pdRings = parameters.rings;
			updateShader = true;
		}
		if (parameters.samples != null && parameters.samples != this.pdSamples) {
			this.pdSamples = parameters.samples;
			updateShader = true;
		}
		if (updateShader) {
			this.pdMaterial.defines.SAMPLES = this.pdSamples;
			this.pdMaterial.defines.SAMPLE_VECTORS = generatePdSamplePointInitializer(this.pdSamples, this.pdRings, this.pdRadiusExponent);
			this.pdMaterial.needsUpdate = true;
		}
	}

	override function render(renderer:three.Renderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, deltaTime:Float, maskActive:Bool):Void {
		if (this._renderGBuffer) {
			this.overrideVisibility();
			this.renderOverride(renderer, this.normalMaterial, this.normalRenderTarget, 0x7777ff, 1.0);
			this.restoreVisibility();
		}
		this.gtaoMaterial.uniforms.cameraNear.value = this.camera.near;
		this.gtaoMaterial.uniforms.cameraFar.value = this.camera.far;
		this.gtaoMaterial.uniforms.cameraProjectionMatrix.value.copy(this.camera.projectionMatrix);
		this.gtaoMaterial.uniforms.cameraProjectionMatrixInverse.value.copy(this.camera.projectionMatrixInverse);
		this.gtaoMaterial.uniforms.cameraWorldMatrix.value.copy(this.camera.matrixWorld);
		this.renderPass(renderer, this.gtaoMaterial, this.gtaoRenderTarget, 0xffffff, 1.0);
		this.pdMaterial.uniforms.cameraProjectionMatrixInverse.value.copy(this.camera.projectionMatrixInverse);
		this.renderPass(renderer, this.pdMaterial, this.pdRenderTarget, 0xffffff, 1.0);
		switch (this.output) {
			case GTAOPass.OUTPUT.Off:
				break;
			case GTAOPass.OUTPUT.Diffuse:
				this.copyMaterial.uniforms.tDiffuse.value = readBuffer.texture;
				this.copyMaterial.blending = NoBlending;
				this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);
				break;
			case GTAOPass.OUTPUT.AO:
				this.copyMaterial.uniforms.tDiffuse.value = this.gtaoRenderTarget.texture;
				this.copyMaterial.blending = NoBlending;
				this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);
				break;
			case GTAOPass.OUTPUT.Denoise:
				this.copyMaterial.uniforms.tDiffuse.value = this.pdRenderTarget.texture;
				this.copyMaterial.blending = NoBlending;
				this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);
				break;
			case GTAOPass.OUTPUT.Depth:
				this.depthRenderMaterial.uniforms.cameraNear.value = this.camera.near;
				this.depthRenderMaterial.uniforms.cameraFar.value = this.camera.far;
				this.renderPass(renderer, this.depthRenderMaterial, this.renderToScreen ? null : writeBuffer);
				break;
			case GTAOPass.OUTPUT.Normal:
				this.copyMaterial.uniforms.tDiffuse.value = this.normalRenderTarget.texture;
				this.copyMaterial.blending = NoBlending;
				this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);
				break;
			case GTAOPass.OUTPUT.Default:
				this.copyMaterial.uniforms.tDiffuse.value = readBuffer.texture;
				this.copyMaterial.blending = NoBlending;
				this.renderPass(renderer, this.copyMaterial, this.renderToScreen ? null : writeBuffer);
				this.blendMaterial.uniforms.intensity.value = this.blendIntensity;
				this.blendMaterial.uniforms.tDiffuse.value = this.pdRenderTarget.texture;
				this.renderPass(renderer, this.blendMaterial, this.renderToScreen ? null : writeBuffer);
				break;
			default:
				Sys.println("THREE.GTAOPass: Unknown output type.");
		}
	}

	public function renderPass(renderer:three.Renderer, passMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, clearColor:Int, clearAlpha:Float):Void {
		renderer.getClearColor(this.originalClearColor);
		var originalClearAlpha = renderer.getClearAlpha();
		var originalAutoClear = renderer.autoClear;
		renderer.setRenderTarget(renderTarget);
		renderer.autoClear = false;
		if (clearColor != null) {
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

	public function renderOverride(renderer:three.Renderer, overrideMaterial:ShaderMaterial, renderTarget:WebGLRenderTarget, clearColor:Int, clearAlpha:Float):Void {
		renderer.getClearColor(this.originalClearColor);
		var originalClearAlpha = renderer.getClearAlpha();
		var originalAutoClear = renderer.autoClear;
		renderer.setRenderTarget(renderTarget);
		renderer.autoClear = false;
		clearColor = overrideMaterial.clearColor || clearColor;
		clearAlpha = overrideMaterial.clearAlpha || clearAlpha;
		if (clearColor != null) {
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
		this.width = width;
		this.height = height;
		this.gtaoRenderTarget.setSize(width, height);
		this.normalRenderTarget.setSize(width, height);
		this.pdRenderTarget.setSize(width, height);
		this.gtaoMaterial.uniforms.resolution.value.set(width, height);
		this.gtaoMaterial.uniforms.cameraProjectionMatrix.value.copy(this.camera.projectionMatrix);
		this.gtaoMaterial.uniforms.cameraProjectionMatrixInverse.value.copy(this.camera.projectionMatrixInverse);
		this.pdMaterial.uniforms.resolution.value.set(width, height);
		this.pdMaterial.uniforms.cameraProjectionMatrixInverse.value.copy(this.camera.projectionMatrixInverse);
	}

	public function overrideVisibility():Void {
		var scene = this.scene;
		var cache = this._visibilityCache;
		scene.traverse(function(object:three.Object3D) {
			cache.set(object, object.visible);
			if (object.isPoints || object.isLine) object.visible = false;
		});
	}

	public function restoreVisibility():Void {
		var scene = this.scene;
		var cache = this._visibilityCache;
		scene.traverse(function(object:three.Object3D) {
			var visible = cache.get(object);
			object.visible = visible;
		});
		cache.clear();
	}

	public function generateNoise(size:Int = 64):DataTexture {
		var simplex = new SimplexNoise();
		var arraySize = size * size * 4;
		var data = new Uint8Array(arraySize);
		for (var i in 0...size) {
			for (var j in 0...size) {
				var x = i;
				var y = j;
				data[(i * size + j) * 4] = (simplex.noise(x, y) * 0.5 + 0.5) * 255;
				data[(i * size + j) * 4 + 1] = (simplex.noise(x + size, y) * 0.5 + 0.5) * 255;
				data[(i * size + j) * 4 + 2] = (simplex.noise(x, y + size) * 0.5 + 0.5) * 255;
				data[(i * size + j) * 4 + 3] = (simplex.noise(x + size, y + size) * 0.5 + 0.5) * 255;
			}
		}
		var noiseTexture = new DataTexture(data, size, size, RGBAFormat, UnsignedByteType);
		noiseTexture.wrapS = RepeatWrapping;
		noiseTexture.wrapT = RepeatWrapping;
		noiseTexture.needsUpdate = true;
		return noiseTexture;
	}

	static public var OUTPUT = {
		Off: - 1,
		Default: 0,
		Diffuse: 1,
		Depth: 2,
		Normal: 3,
		AO: 4,
		Denoise: 5
	};

	private static function generateMagicSquareNoise():DataTexture {
		var size = 4;
		var data = new Uint8Array(size * size * 4);
		var magicSquare = [
			[1, 15, 14, 4],
			[12, 6, 7, 9],
			[8, 10, 11, 5],
			[13, 3, 2, 16]
		];
		for (var i in 0...size) {
			for (var j in 0...size) {
				data[(i * size + j) * 4] = (magicSquare[i][j] / 17) * 255;
				data[(i * size + j) * 4 + 1] = (magicSquare[i][j] / 17) * 255;
				data[(i * size + j) * 4 + 2] = (magicSquare[i][j] / 17) * 255;
				data[(i * size + j) * 4 + 3] = (magicSquare[i][j] / 17) * 255;
			}
		}
		var noiseTexture = new DataTexture(data, size, size, RGBAFormat, UnsignedByteType);
		noiseTexture.wrapS = RepeatWrapping;
		noiseTexture.wrapT = RepeatWrapping;
		noiseTexture.needsUpdate = true;
		return noiseTexture;
	}

	private static function generatePdSamplePointInitializer(samples:Int, rings:Float, radiusExponent:Float):String {
		var sampleVectors = "";
		var angleStep = Math.PI * 2 / samples;
		var ringStep = 1 / rings;
		for (var i in 0...samples) {
			var angle = i * angleStep;
			var radius = Math.pow(ringStep * i, radiusExponent);
			var x = Math.cos(angle) * radius;
			var y = Math.sin(angle) * radius;
			sampleVectors += "vec2(" + x + ", " + y + ")";
			if (i < samples - 1) sampleVectors += ", ";
		}
		return sampleVectors;
	}

}