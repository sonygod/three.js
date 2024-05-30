import js.three.*;
import js.three.extras.core.Object3D;
import js.three.extras.core.Geometry;
import js.three.materials.Material;
import js.three.materials.ShaderMaterial;
import js.three.materials.MeshBasicMaterial;
import js.three.materials.MeshNormalMaterial;
import js.three.materials.blending.NoBlending;
import js.three.materials.blending.NormalBlending;
import js.three.math.Color;
import js.three.math.Matrix4;
import js.three.objects.Mesh;
import js.three.renderers.WebGLRenderTarget;
import js.three.renderers.WebGLRenderTarget.TextureFilter;
import js.three.renderers.WebGLRenderTarget.TextureFormat;
import js.three.renderers.WebGLRenderTarget.TextureType;
import js.three.scenes.Scene;
import js.three.textures.DepthTexture;
import js.three.textures.Texture;
import js.three.textures.Texture.Filter;
import js.three.textures.Texture.Wrap;
import js.three.extras.renderers.Pass;
import js.three.extras.objects.FullScreenQuad;

class SSRPass extends Pass {

	public var renderer:WebGLRenderer;
	public var scene:Scene;
	public var camera:Camera;
	public var groundReflector:Object3D;
	public var width:Int;
	public var height:Int;
	public var clear:Bool;
	public var opacity:Float;
	public var output:Int;
	public var maxDistance:Float;
	public var thickness:Float;
	public var tempColor:Color;
	public var _selects:Array<Object3D>;
	public var selective:Bool;
	public var _bouncing:Bool;
	public var blur:Bool;
	public var _distanceAttenuation:Bool;
	public var _fresnel:Bool;
	public var _infiniteThick:Bool;
	public var beautyRenderTarget:WebGLRenderTarget;
	public var prevRenderTarget:WebGLRenderTarget;
	public var normalRenderTarget:WebGLRenderTarget;
	public var metalnessRenderTarget:WebGLRenderTarget;
	public var ssrRenderTarget:WebGLRenderTarget;
	public var blurRenderTarget:WebGLRenderTarget;
	public var blurRenderTarget2:WebGLRenderTarget;
	public var ssrMaterial:ShaderMaterial;
	public var normalMaterial:MeshNormalMaterial;
	public var metalnessOnMaterial:MeshBasicMaterial;
	public var metalnessOffMaterial:MeshBasicMaterial;
	public var blurMaterial:ShaderMaterial;
	public var blurMaterial2:ShaderMaterial;
	public var depthRenderMaterial:ShaderMaterial;
	public var copyMaterial:ShaderMaterial;
	public var fsQuad:FullScreenQuad;
	public var originalClearColor:Color;

	public function new({renderer, scene, camera, width, height, selects, bouncing, groundReflector}: {renderer: WebGLRenderer, scene: Scene, camera: Camera, width: Int, height: Int, selects: Array<Object3D>, bouncing: Bool, groundReflector: Object3D}) {
		super();
		this.renderer = renderer;
		this.scene = scene;
		this.camera = camera;
		this.groundReflector = groundReflector;
		this.width = if (width != null) width else 512;
		this.height = if (height != null) height else 512;
		this.clear = true;
		this.opacity = SSRShader.uniforms.opacity.value;
		this.output = 0;
		this.maxDistance = SSRShader.uniforms.maxDistance.value;
		this.thickness = SSRShader.uniforms.thickness.value;
		this.tempColor = new Color();
		this._selects = selects;
		this.selective = if (selects != null) true else false;
		this._bouncing = bouncing;
		this.blur = true;
		this._distanceAttenuation = SSRShader.defines.DISTANCE_ATTENUATION;
		this._fresnel = SSRShader.defines.FRESNEL;
		this._infiniteThick = SSRShader.defines.INFINITE_THICK;

		// beauty render target with depth buffer
		var depthTexture = new DepthTexture();
		depthTexture.type = TextureType.UnsignedShortType;
		depthTexture.minFilter = TextureFilter.NearestFilter;
		depthTexture.magFilter = TextureFilter.NearestFilter;

		this.beautyRenderTarget = new WebGLRenderTarget(this.width, this.height);
		this.beautyRenderTarget.minFilter = TextureFilter.NearestFilter;
		this.beautyRenderTarget.magFilter = TextureFilter.NearestFilter;
		this.beautyRenderTarget.type = TextureFormat.HalfFloatType;
		this.beautyRenderTarget.depthTexture = depthTexture;
		this.beautyRenderTarget.depthBuffer = true;

		//for bouncing
		this.prevRenderTarget = new WebGLRenderTarget(this.width, this.height);
		this.prevRenderTarget.minFilter = TextureFilter.NearestFilter;
		this.prevRenderTarget.magFilter = TextureFilter.NearestFilter;

		// normal render target
		this.normalRenderTarget = new WebGLRenderTarget(this.width, this.height);
		this.normalRenderTarget.minFilter = TextureFilter.NearestFilter;
		this.normalRenderTarget.magFilter = TextureFilter.NearestFilter;
		this.normalRenderTarget.type = TextureFormat.HalfFloatType;

		// metalness render target
		this.metalnessRenderTarget = new WebGLRenderTarget(this.width, this.height);
		this.metalnessRenderTarget.minFilter = TextureFilter.NearestFilter;
		this.metalnessRenderTarget.magFilter = TextureFilter.NearestFilter;
		this.metalnessRenderTarget.type = TextureFormat.HalfFloatType;

		// ssr render target
		this.ssrRenderTarget = new WebGLRenderTarget(this.width, this.height);
		this.ssrRenderTarget.minFilter = TextureFilter.NearestFilter;
		this.ssrRenderTarget.magFilter = TextureFilter.NearestFilter;

		this.blurRenderTarget = this.ssrRenderTarget.clone();
		this.blurRenderTarget2 = this.ssrRenderTarget.clone();

		// ssr material
		this.ssrMaterial = new ShaderMaterial({
			defines: {
				MAX_STEP: Std.int(Math.sqrt(this.width * this.width + this.height * this.height))
			},
			uniforms: SSRShader.uniforms,
			vertexShader: SSRShader.vertexShader,
			fragmentShader: SSRShader.fragmentShader,
			blending: NoBlending
		});

		this.ssrMaterial.uniforms['tDiffuse'].value = this.beautyRenderTarget.texture;
		this.ssrMaterial.uniforms['tNormal'].value = this.normalRenderTarget.texture;
		this.ssrMaterial.defines.SELECTIVE = this.selective;
		this.ssrMaterial.needsUpdate = true;
		this.ssrMaterial.uniforms['tMetalness'].value = this.metalnessRenderTarget.texture;
		this.ssrMaterial.uniforms['tDepth'].value = this.beautyRenderTarget.depthTexture;
		this.ssrMaterial.uniforms['cameraNear'].value = this.camera.near;
		this.ssrMaterial.uniforms['cameraFar'].value = this.camera.far;
		this.ssrMaterial.uniforms['thickness'].value = this.thickness;
		this.ssrMaterial.uniforms['resolution'].value.set(this.width, this.height);
		this.ssrMaterial.uniforms['cameraProjectionMatrix'].value.copy(this.camera.projectionMatrix);
		this.ssrMaterial.uniforms['cameraInverseProjectionMatrix'].value.copy(this.camera.projectionMatrixInverse);

		// normal material
		this.normalMaterial = new MeshNormalMaterial();
		this.normalMaterial.blending = NoBlending;

		// metalnessOn material
		this.metalnessOnMaterial = new MeshBasicMaterial({
			color: 'white'
		});

		// metalnessOff material
		this.metalnessOffMaterial = new MeshBasicMaterial({
			color: 'black'
		});

		// blur material
		this.blurMaterial = new ShaderMaterial({
			defines: SSRBlurShader.defines,
			uniforms: SSRBlurShader.uniforms,
			vertexShader: SSRBlurShader.vertexShader,
			fragmentShader: SSRBlurShader.fragmentShader
		});
		this.blurMaterial.uniforms['tDiffuse'].value = this.ssrRenderTarget.texture;
		this.blurMaterial.uniforms['resolution'].value.set(this.width, this.height);

		// blur material 2
		this.blurMaterial2 = new ShaderMaterial({
			defines: SSRBlurShader.defines,
			uniforms: SSRBlurShader.uniforms,
			vertexShader: SSRBlurShader.vertexShader,
			fragmentShader: SSRBlurShader.fragmentShader
		});
		this.blurMaterial2.uniforms['tDiffuse'].value = this.blurRenderTarget.texture;
		this.blurMaterial2.uniforms['resolution'].value.set(this.width, this.height);

		// material for rendering the depth
		this.depthRenderMaterial = new ShaderMaterial({
			defines: SSRDepthShader.defines,
			uniforms: SSRDepthShader.uniforms,
			vertexShader: SSRDepthShader.vertexShader,
			fragmentShader: SSRDepthShader.fragmentShader,
			blending: NoBlending
		});
		this.depthRenderMaterial.uniforms['tDepth'].value = this.beautyRenderTarget.depthTexture;
		this.depthRenderMaterial.uniforms['cameraNear'].value = this.camera.near;
		this.depthRenderMaterial.uniforms['cameraFar'].value = this.camera.far;

		// material for rendering the content of a render target
		this.copyMaterial = new ShaderMaterial({
			uniforms: CopyShader.uniforms,
			vertexShader: CopyShader.vertexShader,
			fragmentShader: CopyShader.fragmentShader,
			transparent: true,
			depthTest: false,
			depthWrite: false,
			blendSrc: SrcAlphaFactor,
			blendDst: OneMinusSrcAlphaFactor,
			blendEquation: AddEquation,
			blendSrcAlpha: SrcAlphaFactor,
			blendDstAlpha: OneMinusSrcAlphaFactor,
			blendEquationAlpha: AddEquation
		});

		this.fsQuad = new FullScreenQuad(null);

		this.originalClearColor = new Color();
	}

	public function dispose():Void {
		// dispose render targets
		this.beautyRenderTarget.dispose();
		this.prevRenderTarget.dispose();
		this.normalRenderTarget.dispose();
		this.metalnessRenderTarget.dispose();
		this.ssrRenderTarget.dispose();
		this.blurRenderTarget.dispose();
		this.blurRenderTarget2.dispose();

		// dispose materials
		this.normalMaterial.dispose();
		this.metalnessOnMaterial.dispose();
		this.metalnessOffMaterial.dispose();
		this.blurMaterial.dispose();
		this.blurMaterial2.dispose();
		this.copyMaterial.dispose();
		this.depthRenderMaterial.dispose();

		// dipsose full screen quad
		this.fsQuad.dispose();
	}

	public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget):Void {
		// render beauty and depth
		renderer.setRenderTarget(this.beautyRenderTarget);
		renderer.clear();
		if (this.groundReflector != null) {
			this.groundReflector.visible = false;
			this.groundReflector.doRender(this.renderer, this.scene, this.camera);
			this.groundReflector.visible = true;
		}

		renderer.render(this.scene, this.camera);
		if (this.groundReflector != null) this.groundReflector.visible = false;

		// render normals
		this.renderOverride(renderer, this.normalMaterial, this.normalRenderTarget, 0, 0);

		// render metalnesses
		if (this.selective) {
			this.renderMetalness(renderer, this.metalnessOnMaterial, this.metalnessRenderTarget, 0, 0);
		}

		// render SSR
		this.ssrMaterial.uniforms['opacity'].value = this.opacity;
		this.ssrMaterial.uniforms['maxDistance'].value = this.maxDistance;
		this.ssrMaterial.uniforms['thickness'].value = this.thickness;
		this.renderPass(renderer, this.ssrMaterial, this.ssrRenderTarget);

		// render blur
		if (this.blur) {
			this.renderPass(renderer, this.blurMaterial, this.blurRenderTarget);
			this.renderPass(renderer, this.blurMaterial2, this.blurRenderTarget2);
		}

		// output result to screen
		switch (this.output) {
			case SSRPass.OUTPUT.Default:
				if (this.bouncing) {
					this.copyMaterial.uniforms['tDiffuse'].value = this.beautyRenderTarget.texture;
					this.copyMaterial.blending = NoBlending;
					this.renderPass(renderer, this.copyMaterial, this.prevRenderTarget);

					if (this.blur)
						this.copyMaterial.uniforms['tDiffuse'].value = this.blurRenderTarget2.texture;
					else
						this.copyMaterial.uniforms['tDiffuse'].value = this.ssrRenderTarget.texture;
					this.copyMaterial.blending = NormalBlending;
					this.renderPass(renderer, this.copyMaterial, this.prevRenderTarget);

					this.copyMaterial.uniforms['tDiffuse'].value = this.prevRenderTarget.texture;
					this.copyMaterial.blending = NoBlending;
					this.renderPass(renderer, this.copyMaterial, writeBuffer);
				} else {
					this.copyMaterial.uniforms['tDiffuse'].value = this.beautyRenderTarget.texture;
					this.copyMaterial.blending = NoBlending;
					this.renderPass(renderer, this.copyMaterial, writeBuffer);

					if (this.blur)
						this.copyMaterial.uniforms['tDiffuse'].value = this.blurRenderTarget2.texture;
					else
						this.copyMaterial.uniforms['tDiffuse'].value = this.ssrRenderTarget.texture;
					this.copyMaterial.blending = NormalBlending;
					this.renderPass(renderer, this.copyMaterial, writeBuffer);
				}
				break;
			case SSRPass.OUTPUT.SSR:
				if (this.blur)
					this.copyMaterial.uniforms['tDiffuse'].value = this.blurRenderTarget2.texture;
				else
					this.copyMaterial.uniforms['tDiffuse'].value = this.ssrRenderTarget.texture;
				this.copyMaterial.blending = NoBlending;
				this.renderPass(renderer, this.copyMaterial, writeBuffer);

				if (this.bouncing) {
					if (this.blur)
						this.copyMaterial.uniforms['tDiffuse'].value = this.blurRenderTarget2.texture;
					else
						this.copyMaterial.uniforms['tDiffuse'].value = this.beautyRenderTarget.texture;
					this.copyMaterial.blending = NoBlending;
					this.renderPass(renderer, this.copyMaterial, this.prevRenderTarget);

					this.copyMaterial.uniforms['tDiffuse'].value = this.ssrRenderTarget.texture;
					this.copyMaterial.blending = NormalBlending;
					this.renderPass(renderer, this.copyMaterial, this.prevRenderTarget);
				}
				break;
			case SSRPass.OUTPUT.Beauty:
				this.copyMaterial.uniforms['tDiffuse'].value = this.beautyRenderTarget.texture;
				this.copyMaterial.blending = NoBlending;
				this.renderPass(renderer, this.copyMaterial, writeBuffer);
				break;
			case SSRPass.OUTPUT.Depth:
				this.renderPass(renderer, this.depthRenderMaterial, writeBuffer);
				break;
			case SSRPass.OUTPUT.Normal:
				this.copyMaterial.uniforms['tDiffuse'].value = this.normalRenderTarget.texture;
				this.copyMaterial.blending = NoBlending;
				this.renderPass(renderer, this.copyMaterial, writeBuffer);
				break;
			case SSRPass.OUTPUT.Metalness:
				this.copyMaterial.uniforms['tDiffuse'].value = this.metalnessRenderTarget.texture;
				this.copyMaterial.blending = NoBlending;
				this.renderPass(renderer, this.copyMaterial, writeBuffer);
				break;
			default:
				trace('THREE.SSRPass: Unknown output type.');
		}
	}

	public function renderPass(renderer:WebGLRenderer, passMaterial:Material, renderTarget:WebGLRenderTarget, clearColor:Float, clearAlpha:Float):Void {
		// save original state
		this.originalClearColor.copy(renderer.getClearColor(this.tempColor));
		var originalClearAlpha = renderer.getClearAlpha(this.tempColor);
		var originalAutoClear = renderer.autoClear;

		renderer.setRenderTarget(renderTarget);

		// setup pass state
		renderer.autoClear = false;
		if (clearColor != null && clearColor != null) {
			renderer.setClearColor(clearColor);
			renderer.setClearAlpha(if (clearAlpha != null) clearAlpha else 0.0);
			renderer.clear();
		}

		this.fsQuad.material = passMaterial;
		this.fsQuad.render(renderer);

		// restore original state
		renderer.autoClear = originalAutoClear;
		renderer.setClearColor(this.originalClearColor);
		renderer.setClearAlpha(originalClearAlpha);
	}

	public function renderOverride(renderer:WebGLRenderer, overrideMaterial:Material, renderTarget:WebGLRenderTarget, clearColor:Float, clearAlpha:Float):Void {
		this.originalClearColor.copy(renderer.getClearColor(this.tempColor));
		var originalClearAlpha = renderer.getClearAlpha(this.tempColor);
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

		// restore original state

		renderer.autoClear = originalAutoClear;
		renderer.setClearColor(this.originalClearColor);
		renderer.setClearAlpha(originalClearAlpha);
	}

	public function renderMetalness(renderer:WebGLRenderer, overrideMaterial:Material, renderTarget:WebGLRenderTarget, clearColor:Float, clearAlpha:Float):Void {
		this.originalClearColor.copy(renderer.getClearColor(this.tempColor));
		var originalClearAlpha = renderer.getClearAlpha(this.tempColor);
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

		this.scene.traverseVisible((child:Object3D) -> {
			child._SSRPassBackupMaterial = child.material;
			if (this._selects.contains(child)) {
				child.material = this.metalnessOnMaterial;
			} else {
				child.material = this.metalnessOffMaterial;
			}
		});
		renderer.render(this.scene, this.camera);
		this.scene.traverseVisible((child:Object3D) -> {
			child.material = child._SSRPassBackupMaterial;
		});

		// restore original state

		renderer.autoClear = originalAutoClear;
		renderer.setClearColor(this.originalClearColor);
		renderer.setClearAlpha(originalClearAlpha);
	}

	public function setSize(width:Int, height:Int):Void {
		this.width = width;
		this.height = height;

		this.ssrMaterial.defines.MAX_STEP = Std.int(Math.sqrt(width * width + height * height));
		this.ssrMaterial.needsUpdate = true;
		this.beautyRenderTarget.setSize(width, height);
		this.prevRenderTarget.setSize(width, height);
		this.ssrRenderTarget.setSize(width, height);
		this.normalRenderTarget.setSize(width, height);
		this.metalnessRenderTarget.setSize(width, height);
		this.blurRenderTarget.setSize(width, height);
		this.blurRenderTarget2.setSize(width, height);

		this.ssrMaterial.uniforms['resolution'].value.set(width, height);
		this.ssrMaterial.uniforms['cameraProjectionMatrix'].value.copy(this.camera.projectionMatrix);
		this.ssrMaterial.uniforms['cameraInverseProjectionMatrix'].value.copy(this.camera.projectionMatrixInverse);

		this.blurMaterial.uniforms['resolution'].value.set(width, height);
		this.blurMaterial2.uniforms['resolution'].value.set(width, height);
	}

	public static var OUTPUT:Array<String> = ['Default', 'SSR', 'Beauty', 'Depth', 'Normal', 'Metalness'];
}