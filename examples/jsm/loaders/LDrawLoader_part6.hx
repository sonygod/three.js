import haxe.ds.StringMap;
import js.html.FileLoader;
import js.html.FileLoaderOptions;
import js.typedarrays.TypedArray;
import js.typedarrays.Uint8Array;

class LDrawLoader extends js.Lib.Loader<Group> {

	public var materials:Array<Material>;
	public var materialLibrary:StringMap<Material>;
	private var edgeMaterialCache:WeakMap<Material, LineBasicMaterial>;
	private var conditionalEdgeMaterialCache:WeakMap<LineBasicMaterial, LDrawConditionalLineMaterial>;
	public var partsCache:LDrawPartsGeometryCache;
	public var fileMap:StringMap<String>;
	public var smoothNormals:Bool;
	public var partsLibraryPath:String;
	public var missingColorMaterial:MeshStandardMaterial;
	public var missingEdgeColorMaterial:LineBasicMaterial;
	public var missingConditionalEdgeColorMaterial:LDrawConditionalLineMaterial;

	public function new(manager:LoaderManager) {
		super(manager);
		this.materials = [];
		this.materialLibrary = {};
		this.edgeMaterialCache = new WeakMap<Material, LineBasicMaterial>();
		this.conditionalEdgeMaterialCache = new WeakMap<LineBasicMaterial, LDrawConditionalLineMaterial>();
		this.partsCache = new LDrawPartsGeometryCache(this);
		this.fileMap = {};
		this.smoothNormals = true;
		this.partsLibraryPath = '';
		this.missingColorMaterial = new MeshStandardMaterial( { name: Loader.DEFAULT_MATERIAL_NAME, color: 0xFF00FF, roughness: 0.3, metalness: 0 } );
		this.missingEdgeColorMaterial = new LineBasicMaterial( { name: Loader.DEFAULT_MATERIAL_NAME, color: 0xFF00FF } );
		this.missingConditionalEdgeColorMaterial = new LDrawConditionalLineMaterial( { name: Loader.DEFAULT_MATERIAL_NAME, fog: true, color: 0xFF00FF } );
		this.edgeMaterialCache.set(this.missingColorMaterial, this.missingEdgeColorMaterial);
		this.conditionalEdgeMaterialCache.set(this.missingEdgeColorMaterial, this.missingConditionalEdgeColorMaterial);
	}

	public function setPartsLibraryPath(path:String):LDrawLoader {
		this.partsLibraryPath = path;
		return this;
	}

	public function async preloadMaterials(url:String):Future<Void> {
		var fileLoader = new FileLoader(this.manager);
		fileLoader.path = this.path;
		fileLoader.requestHeader = this.requestHeader;
		fileLoader.withCredentials = this.withCredentials;
		return fileLoader.loadAsync(url).map(text => {
			var colorLineRegex = /^0 !COLOUR/;
			var lines = text.split(/[\n\r]/g);
			var materials = [];
			for (i in 0...lines.length) {
				var line = lines[i];
				if (colorLineRegex.test(line)) {
					var directive = line.replace(colorLineRegex, '');
					var material = this.parseColorMetaDirective(new LineParser(directive));
					materials.push(material);
				}
			}
			this.setMaterials(materials);
		});
	}

	// ... Rest of the methods
}

class WeakMap<K, V> {
	private var _map:Map<K, V>;
	public function new() {
		this._map = new Map<K, V>();
	}
	public function set(key:K, value:V):Void {
		this._map.set(key, value);
	}
	public function get(key:K):V {
		return this._map.get(key);
	}
}