import haxe.ui.Color;
import three.constants.BackSide;
import three.constants.FrontSide;
import three.constants.CubeUVReflectionMapping;
import three.constants.SRGBTransfer;
import three.geometries.BoxGeometry;
import three.geometries.PlaneGeometry;
import three.materials.ShaderMaterial;
import three.math.Euler;
import three.math.Matrix4;
import three.objects.Mesh;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import three.textures.CubeTexture;
import three.textures.Texture;
import three.materials.shaders.ShaderLib;
import three.materials.shaders.UniformsUtils;

class WebGLBackground {
	private var _renderer: WebGLRenderer;
	private var _cubemaps: Map<Texture, Texture>;
	private var _cubeuvmaps: Map<Texture, Texture>;
	private var _state: Dynamic;
	private var _objects: Dynamic;
	private var _alpha: Bool;
	private var _premultipliedAlpha: Bool;

	private var _clearColor: Color;
	private var _clearAlpha: Float;
	private var _planeMesh: Mesh;
	private var _boxMesh: Mesh;
	private var _currentBackground: Texture;
	private var _currentBackgroundVersion: Int;
	private var _currentTonemapping: Int;

	private static var _rgb: {r: Float, g: Float, b: Float} = {r: 0, g: 0, b: 0};
	private static var _e1: Euler = new Euler();
	private static var _m1: Matrix4 = new Matrix4();

	public function new(renderer: WebGLRenderer, cubemaps: Map<Texture, Texture>, cubeuvmaps: Map<Texture, Texture>, state: Dynamic, objects: Dynamic, alpha: Bool, premultipliedAlpha: Bool) {
		this._renderer = renderer;
		this._cubemaps = cubemaps;
		this._cubeuvmaps = cubeuvmaps;
		this._state = state;
		this._objects = objects;
		this._alpha = alpha;
		this._premultipliedAlpha = premultipliedAlpha;

		this._clearColor = new Color(0x000000);
		this._clearAlpha = alpha ? 0 : 1;
	}

	public function getClearColor(): Color {
		return this._clearColor;
	}

	public function setClearColor(color: Color, alpha: Float = 1): Void {
		this._clearColor.set(color);
		this._clearAlpha = alpha;
		this._setClear(this._clearColor, this._clearAlpha);
	}

	public function getClearAlpha(): Float {
		return this._clearAlpha;
	}

	public function setClearAlpha(alpha: Float): Void {
		this._clearAlpha = alpha;
		this._setClear(this._clearColor, this._clearAlpha);
	}

	public function render(scene: Scene): Void {
		var forceClear: Bool = false;
		var background: Texture = this._getBackground(scene);

		if (background == null) {
			this._setClear(this._clearColor, this._clearAlpha);
		} else if (background != null && Std.is(background, Color)) {
			this._setClear(cast background, 1);
			forceClear = true;
		}

		var environmentBlendMode: String = this._renderer.xr.getEnvironmentBlendMode();

		if (environmentBlendMode == "additive") {
			this._state.buffers.color.setClear(0, 0, 0, 1, this._premultipliedAlpha);
		} else if (environmentBlendMode == "alpha-blend") {
			this._state.buffers.color.setClear(0, 0, 0, 0, this._premultipliedAlpha);
		}

		if (this._renderer.autoClear || forceClear) {
			this._renderer.clear(this._renderer.autoClearColor, this._renderer.autoClearDepth, this._renderer.autoClearStencil);
		}
	}

	public function addToRenderList(renderList: Array<Dynamic>, scene: Scene): Void {
		var background: Texture = this._getBackground(scene);

		if (background != null && (Std.is(background, CubeTexture) || background.mapping == CubeUVReflectionMapping)) {
			if (this._boxMesh == null) {
				this._boxMesh = new Mesh(
					new BoxGeometry(1, 1, 1),
					new ShaderMaterial({
						name: "BackgroundCubeMaterial",
						uniforms: UniformsUtils.cloneUniforms(ShaderLib.backgroundCube.uniforms),
						vertexShader: ShaderLib.backgroundCube.vertexShader,
						fragmentShader: ShaderLib.backgroundCube.fragmentShader,
						side: BackSide,
						depthTest: false,
						depthWrite: false,
						fog: false
					})
				);

				this._boxMesh.geometry.deleteAttribute("normal");
				this._boxMesh.geometry.deleteAttribute("uv");

				this._boxMesh.onBeforeRender = function(renderer: WebGLRenderer, scene: Scene, camera: Dynamic) {
					this.matrixWorld.copyPosition(camera.matrixWorld);
				};

				// add "envMap" material property so the renderer can evaluate it like for built-in materials
				Reflect.setField(this._boxMesh.material, "envMap", function() {
					return this.uniforms.envMap.value;
				});

				this._objects.update(this._boxMesh);
			}

			_e1.copy(scene.backgroundRotation);

			// accommodate left-handed frame
			_e1.x *= -1;
			_e1.y *= -1;
			_e1.z *= -1;

			if (Std.is(background, CubeTexture) && Std.is(background, Texture) == false) {
				// environment maps which are not cube render targets or PMREMs follow a different convention
				_e1.y *= -1;
				_e1.z *= -1;
			}

			this._boxMesh.material.uniforms.envMap.value = background;
			this._boxMesh.material.uniforms.flipEnvMap.value = (Std.is(background, CubeTexture) && Std.is(background, Texture) == false) ? -1 : 1;
			this._boxMesh.material.uniforms.backgroundBlurriness.value = scene.backgroundBlurriness;
			this._boxMesh.material.uniforms.backgroundIntensity.value = scene.backgroundIntensity;
			this._boxMesh.material.uniforms.backgroundRotation.value.setFromMatrix4(_m1.makeRotationFromEuler(_e1));
			this._boxMesh.material.toneMapped = ColorManagement.getTransfer(background.colorSpace) != SRGBTransfer;

			if (this._currentBackground != background ||
				this._currentBackgroundVersion != background.version ||
				this._currentTonemapping != this._renderer.toneMapping) {

				this._boxMesh.material.needsUpdate = true;

				this._currentBackground = background;
				this._currentBackgroundVersion = background.version;
				this._currentTonemapping = this._renderer.toneMapping;
			}

			this._boxMesh.layers.enableAll();

			// push to the pre-sorted opaque render list
			renderList.unshift(this._boxMesh, this._boxMesh.geometry, this._boxMesh.material, 0, 0, null);
		} else if (background != null && Std.is(background, Texture)) {
			if (this._planeMesh == null) {
				this._planeMesh = new Mesh(
					new PlaneGeometry(2, 2),
					new ShaderMaterial({
						name: "BackgroundMaterial",
						uniforms: UniformsUtils.cloneUniforms(ShaderLib.background.uniforms),
						vertexShader: ShaderLib.background.vertexShader,
						fragmentShader: ShaderLib.background.fragmentShader,
						side: FrontSide,
						depthTest: false,
						depthWrite: false,
						fog: false
					})
				);

				this._planeMesh.geometry.deleteAttribute("normal");

				// add "map" material property so the renderer can evaluate it like for built-in materials
				Reflect.setField(this._planeMesh.material, "map", function() {
					return this.uniforms.t2D.value;
				});

				this._objects.update(this._planeMesh);
			}

			this._planeMesh.material.uniforms.t2D.value = background;
			this._planeMesh.material.uniforms.backgroundIntensity.value = scene.backgroundIntensity;
			this._planeMesh.material.toneMapped = ColorManagement.getTransfer(background.colorSpace) != SRGBTransfer;

			if (background.matrixAutoUpdate) {
				background.updateMatrix();
			}

			this._planeMesh.material.uniforms.uvTransform.value.copy(background.matrix);

			if (this._currentBackground != background ||
				this._currentBackgroundVersion != background.version ||
				this._currentTonemapping != this._renderer.toneMapping) {

				this._planeMesh.material.needsUpdate = true;

				this._currentBackground = background;
				this._currentBackgroundVersion = background.version;
				this._currentTonemapping = this._renderer.toneMapping;
			}

			this._planeMesh.layers.enableAll();

			// push to the pre-sorted opaque render list
			renderList.unshift(this._planeMesh, this._planeMesh.geometry, this._planeMesh.material, 0, 0, null);
		}
	}

	private function _getBackground(scene: Scene): Texture {
		var background: Texture = scene.isScene ? scene.background : null;

		if (background != null && Std.is(background, Texture)) {
			var usePMREM: Bool = scene.backgroundBlurriness > 0; // use PMREM if the user wants to blur the background
			background = (usePMREM ? this._cubeuvmaps : this._cubemaps).get(background);
		}

		return background;
	}

	private function _setClear(color: Color, alpha: Float): Void {
		color.getRGB(_rgb, UniformsUtils.getUnlitUniformColorSpace(this._renderer));

		this._state.buffers.color.setClear(_rgb.r, _rgb.g, _rgb.b, alpha, this._premultipliedAlpha);
	}
}