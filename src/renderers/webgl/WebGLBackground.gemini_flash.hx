import haxe.extern.js.Anonymous;
import haxe.extern.js.Lib;
import haxe.io.Bytes;
import js.html.CanvasRenderingContext2D;
import js.html.Element;
import js.html.HTMLCanvasElement;
import js.html.Image;
import js.html.ImageData;
import js.html.Window;
import js.lib.Array;
import js.lib.Math;
import js.lib.Object;
import js.lib.String;
import js.lib.Uint8ClampedArray;
import js.lib.Vec3;
import js.lib.WebGLRenderingContext;
import js.lib.console;
import js.lib.document;
import js.lib.parseFloat;
import js.lib.parseInt;
import three.constants.BackSide;
import three.constants.CubeUVReflectionMapping;
import three.constants.FrontSide;
import three.constants.SRGBTransfer;
import three.geometries.BoxGeometry;
import three.geometries.PlaneGeometry;
import three.materials.ShaderMaterial;
import three.math.Color;
import three.math.ColorManagement;
import three.math.Euler;
import three.math.Matrix4;
import three.objects.Mesh;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import three.shaders.ShaderLib;
import three.textures.CubeTexture;
import three.textures.Texture;
import three.utils.UniformsUtils;

class WebGLBackground {
	public var renderer:WebGLRenderer;
	public var cubemaps:Anonymous<Texture>;
	public var cubeuvmaps:Anonymous<Texture>;
	public var state:Dynamic;
	public var objects:Dynamic;
	public var alpha:Bool;
	public var premultipliedAlpha:Bool;
	public var clearColor:Color;
	public var clearAlpha:Float;
	public var planeMesh:Mesh;
	public var boxMesh:Mesh;
	public var currentBackground:Texture;
	public var currentBackgroundVersion:Int;
	public var currentTonemapping:Int;

	public function new(renderer:WebGLRenderer, cubemaps:Anonymous<Texture>, cubeuvmaps:Anonymous<Texture>, state:Dynamic, objects:Dynamic, alpha:Bool, premultipliedAlpha:Bool) {
		this.renderer = renderer;
		this.cubemaps = cubemaps;
		this.cubeuvmaps = cubeuvmaps;
		this.state = state;
		this.objects = objects;
		this.alpha = alpha;
		this.premultipliedAlpha = premultipliedAlpha;
		this.clearColor = new Color(0x000000);
		this.clearAlpha = alpha ? 0 : 1;
	}

	public function getClearColor():Color {
		return this.clearColor;
	}

	public function setClearColor(color:Color, alpha:Float = 1):Void {
		this.clearColor.set(color);
		this.clearAlpha = alpha;
		this.setClear(this.clearColor, this.clearAlpha);
	}

	public function getClearAlpha():Float {
		return this.clearAlpha;
	}

	public function setClearAlpha(alpha:Float):Void {
		this.clearAlpha = alpha;
		this.setClear(this.clearColor, this.clearAlpha);
	}

	public function render(scene:Scene):Void {
		var forceClear:Bool = false;
		var background:Texture = this.getBackground(scene);
		if (background == null) {
			this.setClear(this.clearColor, this.clearAlpha);
		} else if (background != null && background.isColor) {
			this.setClear(background, 1);
			forceClear = true;
		}
		var environmentBlendMode:String = this.renderer.xr.getEnvironmentBlendMode();
		if (environmentBlendMode == "additive") {
			this.state.buffers.color.setClear(0, 0, 0, 1, this.premultipliedAlpha);
		} else if (environmentBlendMode == "alpha-blend") {
			this.state.buffers.color.setClear(0, 0, 0, 0, this.premultipliedAlpha);
		}
		if (this.renderer.autoClear || forceClear) {
			this.renderer.clear(this.renderer.autoClearColor, this.renderer.autoClearDepth, this.renderer.autoClearStencil);
		}
	}

	public function addToRenderList(renderList:Array<Dynamic>, scene:Scene):Void {
		var background:Texture = this.getBackground(scene);
		if (background != null && (background.isCubeTexture || background.mapping == CubeUVReflectionMapping)) {
			if (this.boxMesh == null) {
				this.boxMesh = new Mesh(
					new BoxGeometry(1, 1, 1),
					new ShaderMaterial(
						{
							name: "BackgroundCubeMaterial",
							uniforms: UniformsUtils.cloneUniforms(ShaderLib.backgroundCube.uniforms),
							vertexShader: ShaderLib.backgroundCube.vertexShader,
							fragmentShader: ShaderLib.backgroundCube.fragmentShader,
							side: BackSide,
							depthTest: false,
							depthWrite: false,
							fog: false
						}
					)
				);
				this.boxMesh.geometry.deleteAttribute("normal");
				this.boxMesh.geometry.deleteAttribute("uv");
				this.boxMesh.onBeforeRender = function(renderer:WebGLRenderer, scene:Scene, camera:Dynamic) {
					this.matrixWorld.copyPosition(camera.matrixWorld);
				};
				// add "envMap" material property so the renderer can evaluate it like for built-in materials
				Object.defineProperty(this.boxMesh.material, "envMap", {
					get: function() {
						return this.uniforms.envMap.value;
					}
				});
				this.objects.update(this.boxMesh);
			}
			var _e1 = new Euler();
			_e1.copy(scene.backgroundRotation);
			// accommodate left-handed frame
			_e1.x *= -1;
			_e1.y *= -1;
			_e1.z *= -1;
			if (background.isCubeTexture && background.isRenderTargetTexture == false) {
				// environment maps which are not cube render targets or PMREMs follow a different convention
				_e1.y *= -1;
				_e1.z *= -1;
			}
			var _m1 = new Matrix4();
			this.boxMesh.material.uniforms.envMap.value = background;
			this.boxMesh.material.uniforms.flipEnvMap.value = (background.isCubeTexture && background.isRenderTargetTexture == false) ? -1 : 1;
			this.boxMesh.material.uniforms.backgroundBlurriness.value = scene.backgroundBlurriness;
			this.boxMesh.material.uniforms.backgroundIntensity.value = scene.backgroundIntensity;
			this.boxMesh.material.uniforms.backgroundRotation.value.setFromMatrix4(_m1.makeRotationFromEuler(_e1));
			this.boxMesh.material.toneMapped = ColorManagement.getTransfer(background.colorSpace) != SRGBTransfer;
			if (this.currentBackground != background || this.currentBackgroundVersion != background.version || this.currentTonemapping != this.renderer.toneMapping) {
				this.boxMesh.material.needsUpdate = true;
				this.currentBackground = background;
				this.currentBackgroundVersion = background.version;
				this.currentTonemapping = this.renderer.toneMapping;
			}
			this.boxMesh.layers.enableAll();
			// push to the pre-sorted opaque render list
			renderList.unshift(this.boxMesh, this.boxMesh.geometry, this.boxMesh.material, 0, 0, null);
		} else if (background != null && background.isTexture) {
			if (this.planeMesh == null) {
				this.planeMesh = new Mesh(
					new PlaneGeometry(2, 2),
					new ShaderMaterial(
						{
							name: "BackgroundMaterial",
							uniforms: UniformsUtils.cloneUniforms(ShaderLib.background.uniforms),
							vertexShader: ShaderLib.background.vertexShader,
							fragmentShader: ShaderLib.background.fragmentShader,
							side: FrontSide,
							depthTest: false,
							depthWrite: false,
							fog: false
						}
					)
				);
				this.planeMesh.geometry.deleteAttribute("normal");
				// add "map" material property so the renderer can evaluate it like for built-in materials
				Object.defineProperty(this.planeMesh.material, "map", {
					get: function() {
						return this.uniforms.t2D.value;
					}
				});
				this.objects.update(this.planeMesh);
			}
			this.planeMesh.material.uniforms.t2D.value = background;
			this.planeMesh.material.uniforms.backgroundIntensity.value = scene.backgroundIntensity;
			this.planeMesh.material.toneMapped = ColorManagement.getTransfer(background.colorSpace) != SRGBTransfer;
			if (background.matrixAutoUpdate == true) {
				background.updateMatrix();
			}
			this.planeMesh.material.uniforms.uvTransform.value.copy(background.matrix);
			if (this.currentBackground != background || this.currentBackgroundVersion != background.version || this.currentTonemapping != this.renderer.toneMapping) {
				this.planeMesh.material.needsUpdate = true;
				this.currentBackground = background;
				this.currentBackgroundVersion = background.version;
				this.currentTonemapping = this.renderer.toneMapping;
			}
			this.planeMesh.layers.enableAll();
			// push to the pre-sorted opaque render list
			renderList.unshift(this.planeMesh, this.planeMesh.geometry, this.planeMesh.material, 0, 0, null);
		}
	}

	public function setClear(color:Color, alpha:Float):Void {
		var _rgb:Dynamic = { r: 0, b: 0, g: 0 };
		color.getRGB(_rgb, UniformsUtils.getUnlitUniformColorSpace(this.renderer));
		this.state.buffers.color.setClear(_rgb.r, _rgb.g, _rgb.b, alpha, this.premultipliedAlpha);
	}

	public function getBackground(scene:Scene):Texture {
		var background:Dynamic = scene.isScene ? scene.background : null;
		if (background != null && background.isTexture) {
			var usePMREM:Bool = scene.backgroundBlurriness > 0; // use PMREM if the user wants to blur the background
			background = usePMREM ? this.cubeuvmaps.get(background) : this.cubemaps.get(background);
		}
		return cast background;
	}
}