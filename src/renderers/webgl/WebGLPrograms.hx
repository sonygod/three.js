import haxe.ds.Set;
import three.core.Layers;
import three.math.ColorManagement;

class WebGLPrograms {

	private var _programLayers: Layers;
	private var _customShaders: WebGLShaderCache;
	private var _activeChannels: Set<Int>;
	private var programs: Array<WebGLProgram>;

	private var logarithmicDepthBuffer: Bool;
	private var SUPPORTS_VERTEX_TEXTURES: Bool;
	private var precision: String;

	private var shaderIDs: Dict<String>;

	public function new(renderer: WebGLRenderer, cubemaps: Dict<CubeTexture>, cubeuvmaps: Dict<CubeTexture>, extensions: WebGLExtensions, capabilities: WebGLCapabilities, bindingStates: WebGLBindingStates, clipping: WebGLClipping) {
		this._programLayers = new Layers();
		this._customShaders = new WebGLShaderCache();
		this._activeChannels = new Set<Int>();
		this.programs = [];

		this.logarithmicDepthBuffer = capabilities.logarithmicDepthBuffer;
		this.SUPPORTS_VERTEX_TEXTURES = capabilities.vertexTextures;
		this.precision = capabilities.precision;

		this.shaderIDs = {
			MeshDepthMaterial: 'depth',
			MeshDistanceMaterial: 'distanceRGBA',
			MeshNormalMaterial: 'normal',
			MeshBasicMaterial: 'basic',
			MeshLambertMaterial: 'lambert',
			MeshPhongMaterial: 'phong',
			MeshToonMaterial: 'toon',
			MeshStandardMaterial: 'physical',
			MeshPhysicalMaterial: 'physical',
			MeshMatcapMaterial: 'matcap',
			LineBasicMaterial: 'basic',
			LineDashedMaterial: 'dashed',
			PointsMaterial: 'points',
			ShadowMaterial: 'shadow',
			SpriteMaterial: 'sprite'
		};
	}

	private function getChannel(value: Int): String {
		this._activeChannels.add(value);
		return (value === 0) ? 'uv' : `uv${value}`;
	}

	private function getParameters(material: Material, lights: Dict<Dynamic>, shadows: Dict<Dynamic>, scene: Scene, object: Object3D): Dict<Dynamic> {
		// ... (same implementation as before)
	}

	private function getProgramCacheKey(parameters: Dict<Dynamic>): String {
		// ... (same implementation as before)
	}

	private function getProgramCacheKeyParameters(array: Array<Dynamic>, parameters: Dict<Dynamic>): Void {
		// ... (same implementation as before)
	}

	private function getProgramCacheKeyBooleans(array: Array<Dynamic>, parameters: Dict<Dynamic>): Void {
		// ... (same implementation as before)
	}

	private function getUniforms(material: Material): Dict<Dynamic> {
		// ... (same implementation as before)
	}

	private function acquireProgram(parameters: Dict<Dynamic>, cacheKey: String): WebGLProgram {
		// ... (same implementation as before)
	}

	private function releaseProgram(program: WebGLProgram): Void {
		// ... (same implementation as before)
	}

	private function releaseShaderCache(material: Material): Void {
		// ... (same implementation as before)
	}

	public function dispose(): Void {
		// ... (same implementation as before)
	}

}