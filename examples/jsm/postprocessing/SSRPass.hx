import three.math.Color;
import three.core.Pass;
import three.materials.ShaderMaterial;
import three.materials.UniformsUtils;
import three.renderers.WebGLRenderTarget;
import three.shaders.CopyShader;
import three.textures.DepthTexture;
import three.textures.Texture;

import flash.display.Sprite;
import flash.geom.Matrix;

class SSRPass extends Pass {

	public var width:Int;
	public var height:Int;
	public var clear:Bool;
	public var renderer:Dynamic;
	public var scene:Dynamic;
	public var camera:Dynamic;
	public var groundReflector:Dynamic;

	public var opacity:Float;
	public var output:Int;
	public var maxDistance:Float;
	public var thickness:Float;
	public var tempColor:Color;

	public var _selects:Array<Dynamic>;
	public var selective:Bool;

	public var _bouncing:Bool;
	public var distanceAttenuation:Bool;
	public var fresnel:Bool;
	public var infiniteThick:Bool;

	public var beautyRenderTarget:WebGLRenderTarget;
	public var prevRenderTarget:WebGLRenderTarget;
	public var normalRenderTarget:WebGLRenderTarget;
	public var metalnessRenderTarget:WebGLRenderTarget;
	public var ssrRenderTarget:WebGLRenderTarget;
	public var blurRenderTarget:WebGLRenderTarget;
	public var blurRenderTarget2:WebGLRenderTarget;
	// public var blurRenderTarget3:WebGLRenderTarget;

	public var ssrMaterial:ShaderMaterial;
	public var normalMaterial:Dynamic;
	public var metalnessOnMaterial:Dynamic;
	public var metalnessOffMaterial:Dynamic;
	public var blurMaterial:ShaderMaterial;
	public var blurMaterial2:ShaderMaterial;
	// public var blurMaterial3:ShaderMaterial;
	public var copyMaterial:ShaderMaterial;
	public var depthRenderMaterial:ShaderMaterial;
	public var fsQuad:Sprite;

	public function new(renderer:Dynamic, scene:Dynamic, camera:Dynamic, width:Int = 512, height:Int = 512, selects:Array<Dynamic> = [], bouncing:Bool = false, groundReflector:Dynamic = null) {
		super();

		this.width = width;
		this.height = height;

		this.clear = true;

		this.renderer = renderer;
		this.scene = scene;
		this.camera = camera;
		this.groundReflector = groundReflector;

		this.opacity = SSRShader.uniforms.opacity.value;
		this.output = 0;

		this.maxDistance = SSRShader.uniforms.maxDistance.value;
		this.thickness = SSRShader.uniforms.thickness.value;

		this.tempColor = new Color();

		this._selects = selects;
		this.selective = Array.isArray(this._selects);
		Object.defineProperty(this, "selects", {
			get: function () {
				return this._selects;
			},
			set: function (val) {
				if (this._selects === val) return;
				this._selects = val;
				if (Array.isArray(val)) {
					this.selective = true;
					this.ssrMaterial.defines.SELECTIVE = true;
					this.ssrMaterial.needsUpdate = true;
				} else {
					this.selective = false;
					this.ssrMaterial.defines.SELECTIVE = false;
					this.ssrMaterial.needsUpdate = true;
				}
			}
		});

		this._bouncing = bouncing;
		Object.defineProperty(this, "bouncing", {
			get: function () {
				return this._bouncing;
			},
			set: function (val) {
				if (this._bouncing === val) return;
				this._bouncing = val;
				if (val) {
					this.ssrMaterial.uniforms["tDiffuse"].value = this.prevRenderTarget.texture;
				} else {
					this.ssrMaterial.uniforms["tDiffuse"].value = this.beautyRenderTarget.texture;
				}
			}
		});

		this.blur = true;

		this._distanceAttenuation = SSRShader.defines.DISTANCE_ATTENUATION;
		Object.defineProperty(this, "distanceAttenuation", {
			get: function () {
				return this._distanceAttenuation;
			},
			set: function (val) {
				if (this._distanceAttenuation === val) return;
				this._distanceAttenuation = val;
				this.ssrMaterial.defines.DISTANCE_ATTENUATION = val;
				this.ssrMaterial.needsUpdate = true;
			}
		});

		this._fresnel = SSRShader.defines.FRESNEL;
		Object.defineProperty(this, "fresnel", {
			get: function () {
				return this._fresnel;
			},
			set: function (val) {
				if (this._fresnel === val) return;
				this._fresnel = val;
				this.ssrMaterial.defines.FRESNEL = val;
				this.ssrMaterial.needsUpdate = true;
			}
		});

		this._infiniteThick = SSRShader.defines.INFINITE_THICK;
		Object.defineProperty(this, "infiniteThick", {
			get: function () {
				return this._infiniteThick;
			},
			set: function (val) {
				if (this._infiniteThick === val) return;
				this._infiniteThick = val;
				this.ssrMaterial.defines.INFINITE_THICK = val;
				this.ssrMaterial.needsUpdate = true;
			}
		});

		// beauty render target with depth buffer

		var depthTexture = new DepthTexture();
		depthTexture.type = haxe.threed.WebGLRenderTarget.UNSIGNED_SHORT;
		depthTexture.minFilter = haxe.threed.WebGLRenderTarget.NEAREST;
		depthTexture.magFilter = haxe.threed.WebGLRenderTarget.NEAREST;

		this.beautyRenderTarget = new haxe.threed.WebGLRenderTarget(this.width, this.height, {
			minFilter: haxe.threed.WebGLRenderTarget.NEAREST,
			magFilter: haxe.threed.WebGLRenderTarget.NEAREST,
			type: haxe.threed.WebGLRenderTarget.HALF_FLOAT,
			depthTexture: depthTexture,
			depthBuffer: true
		});

		//for bouncing
		this.prevRenderTarget = new haxe.threed.WebGLRenderTarget(this.width, this.height, {
			minFilter: haxe.threed.WebGLRenderTarget.NEAREST,
			magFilter: haxe.threed.WebGLRenderTarget.NEAREST
		});

		// normal render target

		this.normalRenderTarget = new haxe.threed.WebGLRenderTarget(this.width, this.height, {
			minFilter: haxe.threed.WebGLRenderTarget.NEAREST,
			magFilter: haxe.threed.WebGLRenderTarget.NEAREST,
			type: haxe.threed.WebGLRenderTarget.HALF_FLOAT,
		});

		// metalness render target

		this.metalnessRenderTarget = new haxe.threed.WebGLRenderTarget(this.width, this.height, {
			minFilter: haxe.threed.WebGLRenderTarget.NEAREST,
			magFilter: haxe.threed.WebGLRenderTarget.NEAREST,
			type: haxe.threed.WebGLRenderTarget.HALF_FLOAT,
		});



		// ssr render target

		this.ssrRenderTarget = new haxe.threed.WebGLRenderTarget(this.width, this.height, {
			minFilter: haxe.threed.WebGLRenderTarget.NEAREST,
			magFilter: haxe.threed.WebGLRenderTarget.NEAREST
		});

		this.blurRenderTarget = this.ssrRenderTarget.clone();
		this.blurRenderTarget2 = this.ssrRenderTarget.clone();
		// this.blurRenderTarget3 = this.ssrRenderTarget.clone();

		// ssr material

		this.ssrMaterial = new haxe.threed.ShaderMaterial({
			defines: Object.assign({}, SSRShader.defines, {
				MAX_STEP: Math.sqrt(this.width * this.width + this.height * this.height)
			}),
			uniforms: UniformsUtils.clone(SSRShader.uniforms),
			vertexShader: SSRShader.vertexShader,
			fragmentShader: SSRShader.fragmentShader,
			blending: haxe.threed.NoBlending
		});

		this.ssrMaterial.uniforms["tDiffuse"].value = this.beautyRenderTarget.texture;
		this.ssrMaterial.uniforms["tNormal"].value = this.normalRenderTarget.texture;
		this.ssrMaterial.defines.SELECTIVE = this.selective;
		this.ssrMaterial.needsUpdate = true;
		this.ssrMaterial.uniforms["tMetalness"].value = this.metalnessRenderTarget.texture;
		this.ssrMaterial.uniforms["tDepth"].value = this.beautyRenderTarget.depthTexture;
		this.ssrMaterial.uniforms["cameraNear"].value = this.camera.near;
		this.ssrMaterial.uniforms["cameraFar"].value = this.camera.far;
		this.ssrMaterial.uniforms["thickness"].value = this.thickness;
		this.ssrMaterial.uniforms["resolution"].value.set(this.width, this.height);
		this.ssrMaterial.uniforms["cameraProjectionMatrix"].value.copy(this.camera.projectionMatrix);
		this.ssrMaterial.uniforms["cameraInverseProjectionMatrix"].value.copy(this.camera.projectionMatrixInverse);

		// normal material

		this.normalMaterial = new haxe.threed.MeshNormalMaterial();
		this.normalMaterial.blending = haxe.threed.NoBlending;

		// metalnessOn material

		this.metalnessOnMaterial = new haxe.threed.MeshBasicMaterial({
			color: 'white'
		});

		// metalnessOff material

		this.metalnessOffMaterial = new haxe.threed.MeshBasicMaterial({
			color: 'black'
		});

		// blur material

		this.blurMaterial = new haxe.threed.ShaderMaterial({
			defines: Object.assign({}, SSRBlurShader.defines),
			uniforms: UniformsUtils.clone(SSRBlurShader.uniforms),
			vertexShader: SSRBlurShader.vertexShader,
			fragmentShader: SSRBlurShader.fragmentShader
		});
		this.blurMaterial.uniforms["tDiffuse"].value = this.ssrRenderTarget.texture;
		this.blurMaterial.uniforms["resolution"].value.set(this.width, this.height);

		// blur material 2

		this.blurMaterial2 = new haxe.threed.ShaderMaterial({
			defines: Object.assign({}, SSRBlurShader.defines),
			uniforms: UniformsUtils.clone(SSRBlurShader.uniforms),
			vertexShader: SSRBlurShader.vertexShader,
			fragmentShader: SSRBlurShader.fragmentShader
		});
		this.blurMaterial2.uniforms["tDiffuse"].value = this.blurRenderTarget.texture;
		this.blurMaterial2.uniforms["resolution"].value.set(this.width, this.height);

		// // blur material 3

		// this.blurMaterial3 = new haxe.threed.ShaderMaterial({
		//   defines: Object.assign({}, SSRBlurShader.defines),
		//   uniforms: UniformsUtils.clone(SSRBlurShader.uniforms),
		//   vertexShader: SSRBlurShader.vertexShader,
		//   fragmentShader: SSRBlurShader.fragmentShader
		// });
		// this.blurMaterial3.uniforms['tDiffuse'].value = this.blurRenderTarget2.texture;
		// this.blurMaterial3.uniforms['resolution'].value.set(this.width, this.height);

		// material for rendering the depth

		this.depthRenderMaterial = new haxe.threed.ShaderMaterial({
			defines: Object.assign({}, SSRDepthShader.defines),
			uniforms: UniformsUtils.clone(SSRDepthShader.uniforms),
			vertexShader: SSRDepthShader.vertexShader,
			fragmentShader: SSRDepthShader.fragmentShader,
			blending: haxe.threed.NoBlending
		});
		this.depthRenderMaterial.uniforms["tDepth"].value = this.beautyRenderTarget.depthTexture;
		this.depthRenderMaterial.uniforms["cameraNear"].value = this.camera.near;
		this.depthRenderMaterial.uniforms["cameraFar"].value = this.camera.far;

		// material for rendering the content of a render target

		this.copyMaterial = new haxe.threed.ShaderMaterial({
			uniforms: UniformsUtils.clone(CopyShader.uniforms),
			vertexShader: CopyShader.vertexShader,
			fragmentShader: CopyShader.fragmentShader,
			transparent: true,
			depthTest: false,
			depthWrite: false,
			blendSrc: haxe.threed.SrcAlphaFactor,
			blendDst: haxe.threed.OneMinusSrcAlphaFactor,
			blendEquation: haxe.threed.AddEquation,
			blendSrcAlpha: haxe.threed.SrcAlphaFactor,
			blendDstAlpha: haxe.threed.OneMinusSrcAlphaFactor,
			blendEquationAlpha: haxe.threed.AddEquation,
			// premultipliedAlpha:true,
		});

		this.fsQuad = new flash.display.Sprite();

		this.originalClearColor = new Color();

		this.init();
	}

	public function init():Void {
		// Initialize your objects here
	}

	// ... Rest of the class implementation

}