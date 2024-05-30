class LDrawLoader extends Loader {

	var materials:Array<Material>;
	var materialLibrary:Map<String, Material>;
	var edgeMaterialCache:Map<Material, Material>;
	var conditionalEdgeMaterialCache:Map<Material, Material>;
	var partsCache:LDrawPartsGeometryCache;
	var fileMap:Map<String, String>;
	var missingColorMaterial:MeshStandardMaterial;
	var missingEdgeColorMaterial:LineBasicMaterial;
	var missingConditionalEdgeColorMaterial:LDrawConditionalLineMaterial;
	var smoothNormals:Bool;
	var partsLibraryPath:String;

	public function new(manager:Loader) {
		super(manager);
		this.materials = [];
		this.materialLibrary = new Map();
		this.edgeMaterialCache = new Map();
		this.conditionalEdgeMaterialCache = new Map();
		this.partsCache = new LDrawPartsGeometryCache(this);
		this.fileMap = new Map();
		this.setMaterials([]);
		this.smoothNormals = true;
		this.partsLibraryPath = '';
		this.missingColorMaterial = new MeshStandardMaterial({name: Loader.DEFAULT_MATERIAL_NAME, color: 0xFF00FF, roughness: 0.3, metalness: 0});
		this.missingEdgeColorMaterial = new LineBasicMaterial({name: Loader.DEFAULT_MATERIAL_NAME, color: 0xFF00FF});
		this.missingConditionalEdgeColorMaterial = new LDrawConditionalLineMaterial({name: Loader.DEFAULT_MATERIAL_NAME, fog: true, color: 0xFF00FF});
		this.edgeMaterialCache.set(this.missingColorMaterial, this.missingEdgeColorMaterial);
		this.conditionalEdgeMaterialCache.set(this.missingEdgeColorMaterial, this.missingConditionalEdgeColorMaterial);
	}

	public function setPartsLibraryPath(path:String):LDrawLoader {
		this.partsLibraryPath = path;
		return this;
	}

	public function preloadMaterials(url:String):Void {
		var fileLoader = new FileLoader(this.manager);
		fileLoader.setPath(this.path);
		fileLoader.setRequestHeader(this.requestHeader);
		fileLoader.setWithCredentials(this.withCredentials);
		fileLoader.loadAsync(url, text => {
			var colorLineRegex = /^0 !COLOUR/;
			var lines = text.split(/\[\n\r]/g);
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

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var fileLoader = new FileLoader(this.manager);
		fileLoader.setPath(this.path);
		fileLoader.setRequestHeader(this.requestHeader);
		fileLoader.setWithCredentials(this.withCredentials);
		fileLoader.load(url, text => {
			this.partsCache.parseModel(text, this.materialLibrary).then(group => {
				this.applyMaterialsToMesh(group, MAIN_COLOUR_CODE, this.materialLibrary, true);
				this.computeBuildingSteps(group);
				group.userData.fileName = url;
				onLoad(group);
			}).catch(onError);
		}, onProgress, onError);
	}

	public function parse(text:String, onLoad:Dynamic->Void, onError:Dynamic->Void):Void {
		this.partsCache.parseModel(text, this.materialLibrary).then(group => {
			this.applyMaterialsToMesh(group, MAIN_COLOUR_CODE, this.materialLibrary, true);
			this.computeBuildingSteps(group);
			group.userData.fileName = '';
			onLoad(group);
		}).catch(onError);
	}

	public function setMaterials(materials:Array<Material>):LDrawLoader {
		this.materialLibrary = new Map();
		this.materials = [];
		for (i in 0...materials.length) {
			this.addMaterial(materials[i]);
		}
		this.addMaterial(this.parseColorMetaDirective(new LineParser('Main_Colour CODE 16 VALUE #FF8080 EDGE #333333')));
		this.addMaterial(this.parseColorMetaDirective(new LineParser('Edge_Colour CODE 24 VALUE #A0A0A0 EDGE #333333')));
		return this;
	}

	public function setFileMap(fileMap:Map<String, String>):LDrawLoader {
		this.fileMap = fileMap;
		return this;
	}

	public function addMaterial(material:Material):LDrawLoader {
		if (!this.materialLibrary.exists(material.userData.code)) {
			this.materials.push(material);
			this.materialLibrary.set(material.userData.code, material);
		}
		return this;
	}

	public function getMaterial(colorCode:String):Material {
		if (colorCode.startsWith('0x2')) {
			var color = colorCode.substring(3);
			return this.parseColorMetaDirective(new LineParser('Direct_Color_' + color + ' CODE -1 VALUE #' + color + ' EDGE #' + color + ''));
		}
		return this.materialLibrary.get(colorCode) ?? null;
	}

	public function applyMaterialsToMesh(group:Group, parentColorCode:String, materialHierarchy:Map<String, Material>, finalMaterialPass:Bool = false):Void {
		group.traverse(c => {
			if (c.isMesh || c.isLineSegments) {
				if (Std.is(c.material, Array)) {
					for (i in 0...c.material.length) {
						if (!Std.is(c.material[i], Material)) {
							c.material[i] = getMaterial(c, c.material[i]);
						}
					}
				} else if (!Std.is(c.material, Material)) {
					c.material = getMaterial(c, c.material);
				}
			}
		});

		function getMaterial(c:Dynamic, colorCode:String):Material {
			var parentIsPassthrough = parentColorCode == MAIN_COLOUR_CODE;
			if (parentIsPassthrough && !materialHierarchy.exists(colorCode) && !finalMaterialPass) {
				return colorCode;
			}
			var forEdge = c.isLineSegments || c.isConditionalLine;
			var isPassthrough = !forEdge && colorCode == MAIN_COLOUR_CODE || forEdge && colorCode == MAIN_EDGE_COLOUR_CODE;
			if (isPassthrough) {
				colorCode = parentColorCode;
			}
			var material:Material = null;
			if (materialHierarchy.exists(colorCode)) {
				material = materialHierarchy.get(colorCode);
			} else if (finalMaterialPass) {
				material = this.getMaterial(colorCode);
				if (material == null) {
					trace('LDrawLoader: Material properties for code ${colorCode} not available.');
					material = this.missingColorMaterial;
				}
			} else {
				return colorCode;
			}
			if (c.isLineSegments) {
				material = this.edgeMaterialCache.get(material);
				if (c.isConditionalLine) {
					material = this.conditionalEdgeMaterialCache.get(material);
				}
			}
			return material;
		}
	}

	public function getMainMaterial():Material {
		return this.getMaterial(MAIN_COLOUR_CODE);
	}

	public function getMainEdgeMaterial():Material {
		var mat = this.getMaterial(MAIN_EDGE_COLOUR_CODE);
		return mat ? this.edgeMaterialCache.get(mat) : null;
	}

	public function parseColorMetaDirective(lineParser:LineParser):Material {
		// Parses a color definition and returns a THREE.Material
		// ...
	}

	public function computeBuildingSteps(model:Group):Void {
		// Sets userdata.buildingStep number in Group objects and userData.numBuildingSteps number in the root Group object.
		// ...
	}
}