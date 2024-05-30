class LDrawLoader extends Loader {

	public var materials:Array<Dynamic>;
	public var materialLibrary:Dynamic;
	public var edgeMaterialCache:Map<Dynamic, Dynamic>;
	public var conditionalEdgeMaterialCache:Map<Dynamic, Dynamic>;
	public var partsCache:LDrawPartsGeometryCache;
	public var fileMap:Dynamic;
	public var smoothNormals:Bool;
	public var partsLibraryPath:String;
	public var missingColorMaterial:MeshStandardMaterial;
	public var missingEdgeColorMaterial:LineBasicMaterial;
	public var missingConditionalEdgeColorMaterial:LDrawConditionalLineMaterial;

	public function new(manager:Dynamic) {

		super(manager);

		materials = [];
		materialLibrary = {};
		edgeMaterialCache = new Map();
		conditionalEdgeMaterialCache = new Map();

		partsCache = new LDrawPartsGeometryCache(this);

		fileMap = {};

		setMaterials([]);

		smoothNormals = true;

		partsLibraryPath = '';

		missingColorMaterial = new MeshStandardMaterial({ name: Loader.DEFAULT_MATERIAL_NAME, color: 0xFF00FF, roughness: 0.3, metalness: 0 });
		missingEdgeColorMaterial = new LineBasicMaterial({ name: Loader.DEFAULT_MATERIAL_NAME, color: 0xFF00FF });
		missingConditionalEdgeColorMaterial = new LDrawConditionalLineMaterial({ name: Loader.DEFAULT_MATERIAL_NAME, fog: true, color: 0xFF00FF });
		edgeMaterialCache.set(missingColorMaterial, missingEdgeColorMaterial);
		conditionalEdgeMaterialCache.set(missingEdgeColorMaterial, missingConditionalEdgeColorMaterial);

	}

	public function setPartsLibraryPath(path:String):LDrawLoader {

		partsLibraryPath = path;
		return this;

	}

	public async function preloadMaterials(url:String):Void {

		var fileLoader = new FileLoader(manager);
		fileLoader.setPath(path);
		fileLoader.setRequestHeader(requestHeader);
		fileLoader.setWithCredentials(withCredentials);

		var text = await fileLoader.loadAsync(url);
		var colorLineRegex = /^0 !COLOUR/;
		var lines = text.split(/[\n\r]/g);
		var materials = [];
		for (i in 0...lines.length) {

			var line = lines[i];
			if (colorLineRegex.test(line)) {

				var directive = line.replace(colorLineRegex, '');
				var material = parseColorMetaDirective(new LineParser(directive));
				materials.push(material);

			}

		}

		setMaterials(materials);

	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {

		var fileLoader = new FileLoader(manager);
		fileLoader.setPath(path);
		fileLoader.setRequestHeader(requestHeader);
		fileLoader.setWithCredentials(withCredentials);
		fileLoader.load(url, function(text) {

			partsCache
				.parseModel(text, materialLibrary)
				.then(function(group) {

					applyMaterialsToMesh(group, MAIN_COLOUR_CODE, materialLibrary, true);
					computeBuildingSteps(group);
					group.userData.fileName = url;
					onLoad(group);

				})
				.catch(onError);

		}, onProgress, onError);

	}

	public function parse(text:String, onLoad:Dynamic, onError:Dynamic):Void {

		partsCache
			.parseModel(text, materialLibrary)
			.then(function(group) {

				applyMaterialsToMesh(group, MAIN_COLOUR_CODE, materialLibrary, true);
				computeBuildingSteps(group);
				group.userData.fileName = '';
				onLoad(group);

			})
			.catch(onError);

	}

	public function setMaterials(materials:Array<Dynamic>):LDrawLoader {

		materialLibrary = {};
		this.materials = [];
		for (i in 0...materials.length) {

			addMaterial(materials[i]);

		}

		addMaterial(parseColorMetaDirective(new LineParser('Main_Colour CODE 16 VALUE #FF8080 EDGE #333333')));
		addMaterial(parseColorMetaDirective(new LineParser('Edge_Colour CODE 24 VALUE #A0A0A0 EDGE #333333')));

		return this;

	}

	public function setFileMap(fileMap:Dynamic):LDrawLoader {

		this.fileMap = fileMap;

		return this;

	}

	public function addMaterial(material:Dynamic):LDrawLoader {

		var matLib = materialLibrary;
		if (!matLib[material.userData.code]) {

			materials.push(material);
			matLib[material.userData.code] = material;

		}

		return this;

	}

	public function getMaterial(colorCode:String):Dynamic {

		if (colorCode.startsWith('0x2')) {

			var color = colorCode.substring(3);

			return parseColorMetaDirective(new LineParser('Direct_Color_' + color + ' CODE -1 VALUE #' + color + ' EDGE #' + color + ''));

		}

		return materialLibrary[colorCode] || null;

	}

	public function applyMaterialsToMesh(group:Dynamic, parentColorCode:String, materialHierarchy:Dynamic, finalMaterialPass:Bool = false):Void {

		group.traverse(function(c) {

			if (c.isMesh || c.isLineSegments) {

				if (Array.isArray(c.material)) {

					for (i in 0...c.material.length) {

						if (!c.material[i].isMaterial) {

							c.material[i] = getMaterial(c, c.material[i]);

						}

					}

				} else if (!c.material.isMaterial) {

					c.material = getMaterial(c, c.material);

				}

			}

		});

		function getMaterial(c:Dynamic, colorCode:String):Dynamic {

			var parentIsPassthrough = parentColorCode === MAIN_COLOUR_CODE;
			if (parentIsPassthrough && ! (colorCode in materialHierarchy) && !finalMaterialPass) {

				return colorCode;

			}

			var forEdge = c.isLineSegments || c.isConditionalLine;
			var isPassthrough = !forEdge && colorCode === MAIN_COLOUR_CODE || forEdge && colorCode === MAIN_EDGE_COLOUR_CODE;
			if (isPassthrough) {

				colorCode = parentColorCode;

			}

			var material = null;
			if (colorCode in materialHierarchy) {

				material = materialHierarchy[colorCode];

			} else if (finalMaterialPass) {

				material = getMaterial(colorCode);
				if (material === null) {

					console.warn('LDrawLoader: Material properties for code ' + colorCode + ' not available.');

					material = missingColorMaterial;

				}

			} else {

				return colorCode;

			}

			if (c.isLineSegments) {

				material = edgeMaterialCache.get(material);

				if (c.isConditionalLine) {

					material = conditionalEdgeMaterialCache.get(material);

				}

			}

			return material;

		}

	}

	public function getMainMaterial():Dynamic {

		return getMaterial(MAIN_COLOUR_CODE);

	}

	public function getMainEdgeMaterial():Dynamic {

		var mat = getMaterial(MAIN_EDGE_COLOUR_CODE);
		return mat ? edgeMaterialCache.get(mat) : null;

	}

	public function parseColorMetaDirective(lineParser:LineParser):Dynamic {

		var code = null;

		var fillColor = '#FF00FF';
		var edgeColor = '#FF00FF';

		var alpha = 1;
		var isTransparent = false;

		var luminance = 0;

		var finishType = FINISH_TYPE_DEFAULT;

		var edgeMaterial = null;

		var name = lineParser.getToken();
		if (!name) {

			throw new Error('LDrawLoader: Material name was expected after "!COLOUR tag' + lineParser.getLineNumberString() + '.');

		}

		var token = null;
		while (true) {

			token = lineParser.getToken();

			if (!token) {

				break;

			}

			if (!parseLuminance(token)) {

				switch (token.toUpperCase()) {

					case 'CODE':

						code = lineParser.getToken();
						break;

					case 'VALUE':

						fillColor = lineParser.getToken();
						if (fillColor.startsWith('0x')) {

							fillColor = '#' + fillColor.substring(2);

						} else if (!fillColor.startsWith('#')) {

							throw new Error('LDrawLoader: Invalid color while parsing material' + lineParser.getLineNumberString() + '.');

						}

						break;

					case 'EDGE':

						edgeColor = lineParser.getToken();
						if (edgeColor.startsWith('0x')) {

							edgeColor = '#' + edgeColor.substring(2);

						} else if (!edgeColor.startsWith('#')) {

							edgeMaterial = getMaterial(edgeColor);
							if (!edgeMaterial) {

								throw new Error('LDrawLoader: Invalid edge color while parsing material' + lineParser.getLineNumberString() + '.');

							}

							edgeMaterial = edgeMaterialCache.get(edgeMaterial);

						}

						break;

					case 'ALPHA':

						alpha = parseInt(lineParser.getToken());

						if (isNaN(alpha)) {

							throw new Error('LDrawLoader: Invalid alpha value in material definition' + lineParser.getLineNumberString() + '.');

						}

						alpha = Math.max(0, Math.min(1, alpha / 255));

						if (alpha < 1) {

							isTransparent = true;

						}

						break;

					case 'LUMINANCE':

						if (!parseLuminance(lineParser.getToken())) {

							throw new Error('LDrawLoader: Invalid luminance value in material definition' + LineParser.getLineNumberString() + '.');

						}

						break;

					case 'CHROME':
						finishType = FINISH_TYPE_CHROME;
						break;

					case 'PEARLESCENT':
						finishType = FINISH_TYPE_PEARLESCENT;
						break;

					case 'RUBBER':
						finishType = FINISH_TYPE_RUBBER;
						break;

					case 'MATTE_METALLIC':
						finishType = FINISH_TYPE_MATTE_METALLIC;
						break;

					case 'METAL':
						finishType = FINISH_TYPE_METAL;
						break;

					case 'MATERIAL':
						// Not implemented
						lineParser.setToEnd();
						break;

					default:
						throw new Error('LDrawLoader: Unknown token "' + token + '" while parsing material' + lineParser.getLineNumberString() + '.');

				}

			}

		}

		var material = null;

		switch (finishType) {

			case FINISH_TYPE_DEFAULT:

				material = new MeshStandardMaterial({ roughness: 0.3, metalness: 0 });
				break;

			case FINISH_TYPE_PEARLESCENT:

				// Try to imitate pearlescency by making the surface glossy
				material = new MeshStandardMaterial({ roughness: 0.3, metalness: 0.25 });
				break;

			case FINISH_TYPE_CHROME:

				// Mirror finish surface
				material = new MeshStandardMaterial({ roughness: 0, metalness: 1 });
				break;

			case FINISH_TYPE_RUBBER:

				// Rubber finish
				material = new MeshStandardMaterial({ roughness: 0.9, metalness: 0 });
				break;

			case FINISH_TYPE_MATTE_METALLIC:

				// Brushed metal finish
				material = new MeshStandardMaterial({ roughness: 0.8, metalness: 0.4 });
				break;

			case FINISH_TYPE_METAL:

				// Average metal finish
				material = new MeshStandardMaterial({ roughness: 0.2, metalness: 0.85 });
				break;

			default:
				// Should not happen
				break;

		}

		material.color.setStyle(fillColor, COLOR_SPACE_LDRAW);
		material.transparent = isTransparent;
		material.premultipliedAlpha = true;
		material.opacity = alpha;
		material.depthWrite = !isTransparent;

		material.polygonOffset = true;
		material.polygonOffsetFactor = 1;

		if (luminance !== 0) {

			material.emissive.setStyle(fillColor, COLOR_SPACE_LDRAW).multiplyScalar(luminance);

		}

		if (!edgeMaterial) {

			// This is the material used for edges
			edgeMaterial = new LineBasicMaterial({
				color: new Color().setStyle(edgeColor, COLOR_SPACE_LDRAW),
				transparent: isTransparent,
				opacity: alpha,
				depthWrite: !isTransparent
			});
			edgeMaterial.color;
			edgeMaterial.userData.code = code;
			edgeMaterial.name = name + ' - Edge';

			// This is the material used for conditional edges
			var conditionalEdgeMaterial = new LDrawConditionalLineMaterial({

				fog: true,
				transparent: isTransparent,
				depthWrite: !isTransparent,
				color: new Color().setStyle(edgeColor, COLOR_SPACE_LDRAW),
				opacity: alpha,

			});
			conditionalEdgeMaterial.userData.code = code;
			conditionalEdgeMaterial.name = name + ' - Conditional Edge';

			conditionalEdgeMaterialCache.set(edgeMaterial, conditionalEdgeMaterial);

		}

		material.userData.code = code;
		material.name = name;

		edgeMaterialCache.set(material, edgeMaterial);

		addMaterial(material);

		return material;

		function parseLuminance(token:String):Bool {

			var lum;

			if (token.startsWith('LUMINANCE')) {

				lum = parseInt(token.substring(9));

			} else {

				lum = parseInt(token);

			}

			if (isNaN(lum)) {

				return false;

			}

			luminance = Math.max(0, Math.min(1, lum / 255));

			return true;

		}

	}

	public function computeBuildingSteps(model:Dynamic):Void {

		var stepNumber = 0;

		model.traverse(function(c) {

			if (c.isGroup) { Here is the Haxe version of the provided JavaScript code:


class LDrawLoader extends Loader {

	public var materials:Array<Dynamic>;
	public var materialLibrary:Dynamic;
	public var edgeMaterialCache:Map<Dynamic, Dynamic>;
	public var conditionalEdgeMaterialCache:Map<Dynamic, Dynamic>;
	public var partsCache:LDrawPartsGeometryCache;
	public var fileMap:Dynamic;
	public var smoothNormals:Bool;
	public var partsLibraryPath:String;
	public var missingColorMaterial:MeshStandardMaterial;
	public var missingEdgeColorMaterial:LineBasicMaterial;
	public var missingConditionalEdgeColorMaterial:LDrawConditionalLineMaterial;

	public function new(manager:Dynamic) {

		super(manager);

		materials = [];
		materialLibrary = {};
		edgeMaterialCache = new Map();
		conditionalEdgeMaterialCache = new Map();

		partsCache = new LDrawPartsGeometryCache(this);

		fileMap = {};

		setMaterials([]);

		smoothNormals = true;

		partsLibraryPath = '';

		missingColorMaterial = new MeshStandardMaterial({ name: Loader.DEFAULT_MATERIAL_NAME, color: 0xFF00FF, roughness: 0.3, metalness: 0 });
		missingEdgeColorMaterial = new LineBasicMaterial({ name: Loader.DEFAULT_MATERIAL_NAME, color: 0xFF00FF });
		missingConditionalEdgeColorMaterial = new LDrawConditionalLineMaterial({ name: Loader.DEFAULT_MATERIAL_NAME, fog: true, color: 0xFF00FF });
		edgeMaterialCache.set(missingColorMaterial, missingEdgeColorMaterial);
		conditionalEdgeMaterialCache.set(missingEdgeColorMaterial, missingConditionalEdgeColorMaterial);

	}

	public function setPartsLibraryPath(path:String):LDrawLoader {

		partsLibraryPath = path;
		return this;

	}

	public async function preloadMaterials(url:String):Void {

		var fileLoader = new FileLoader(manager);
		fileLoader.setPath(path);
		fileLoader.setRequestHeader(requestHeader);
		fileLoader.setWithCredentials(withCredentials);

		var text = await fileLoader.loadAsync(url);
		var colorLineRegex = /^0 !COLOUR/;
		var lines = text.split(/[\n\r]/g);
		var materials = [];
		for (i in 0...lines.length) {

			var line = lines[i];
			if (colorLineRegex.test(line)) {

				var directive = line.replace(colorLineRegex, '');
				var material = parseColorMetaDirective(new LineParser(directive));
				materials.push(material);

			}

		}

		setMaterials(materials);

	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {

		var fileLoader = new FileLoader(manager);
		fileLoader.setPath(path);
		fileLoader.setRequestHeader(requestHeader);
		fileLoader.setWithCredentials(withCredentials);
		fileLoader.load(url, function(text) {

			partsCache
				.parseModel(text, materialLibrary)
				.then(function(group) {

					applyMaterialsToMesh(group, MAIN_COLOUR_CODE, materialLibrary, true);
					computeBuildingSteps(group);
					group.userData.fileName = url;
					onLoad(group);

				})
				.catch(onError);

		}, onProgress, onError);

	}

	public function parse(text:String, onLoad:Dynamic, onError:Dynamic):Void {

		partsCache
			.parseModel(text, materialLibrary)
			.then(function(group) {

				applyMaterialsToMesh(group, MAIN_COLOUR_CODE, materialLibrary, true);
				computeBuildingSteps(group);
				group.userData.fileName = '';
				onLoad(group);

			})
			.catch(onError);

	}

	public function setMaterials(materials:Array<Dynamic>):LDrawLoader {

		materialLibrary = {};
		this.materials = [];
		for (i in 0...materials.length) {

			addMaterial(materials[i]);

		}

		addMaterial(parseColorMetaDirective(new LineParser('Main_Colour CODE 16 VALUE #FF8080 EDGE #333333')));
		addMaterial(parseColorMetaDirective(new LineParser('Edge_Colour CODE 24 VALUE #A0A0A0 EDGE #333333')));

		return this;

	}

	public function setFileMap(fileMap:Dynamic):LDrawLoader {

		this.fileMap = fileMap;

		return this;

	}

	public function addMaterial(material:Dynamic):LDrawLoader {

		var matLib = materialLibrary;
		if (!matLib[material.userData.code]) {

			materials.push(material);
			matLib[material.userData.code] = material;

		}

		return this;

	}

	public function getMaterial(colorCode:String):Dynamic {

		if (colorCode.startsWith('0x2')) {

			var color = colorCode.substring(3);

			return parseColorMetaDirective(new LineParser('Direct_Color_' + color + ' CODE -1 VALUE #' + color + ' EDGE #' + color + ''));

		}

		return materialLibrary[colorCode] || null;

	}

	public function applyMaterialsToMesh(group:Dynamic, parentColorCode:String, materialHierarchy:Dynamic, finalMaterialPass:Bool = false):Void {

		group.traverse(function(c) {

			if (c.isMesh || c.isLineSegments) {

				if (Array.isArray(c.material)) {

					for (i in 0...c.material.length) {

						if (!c.material[i].isMaterial) {

							c.material[i] = getMaterial(c, c.material[i]);

						}

					}

				} else if (!c.material.isMaterial) {

					c.material = getMaterial(c, c.material);

				}

			}

		});

		function getMaterial(c:Dynamic, colorCode:String):Dynamic {

			var parentIsPassthrough = parentColorCode == MAIN_COLOUR_CODE;
			if (parentIsPassthrough && ! (colorCode in materialHierarchy) && !finalMaterialPass) {

				return colorCode;

			}

			var forEdge = c.isLineSegments || c.isConditionalLine;
			var isPassthrough = !forEdge && colorCode == MAIN_COLOUR_CODE || forEdge && colorCode == MAIN_EDGE_COLOUR_CODE;
			if (isPassthrough) {

				colorCode = parentColorCode;

			}

			var material:Dynamic = null;
			if (colorCode in materialHierarchy) {

				material = materialHierarchy[colorCode];

			} else if (finalMaterialPass) {

				material = getMaterial(colorCode);
				if (material == null) {

					console.warn('LDrawLoader: Material properties for code ' + colorCode + ' not available.');

					material = missingColorMaterial;

				}

			} else {

				return colorCode;

			}

			if (c.isLineSegments) {

				material = edgeMaterialCache.get(material);

				if (c.isConditionalLine) {

					material = conditionalEdgeMaterialCache.get(material);

				}

			}

			return material;

		}

	}

	public function getMainMaterial():Dynamic {

		return getMaterial(MAIN_COLOUR_CODE);

	}

	public function getMainEdgeMaterial():Dynamic {

		var mat = getMaterial(MAIN_EDGE_COLOUR_CODE);
		return mat ? edgeMaterialCache.get(mat) : null;

	}

	public function parseColorMetaDirective(lineParser:LineParser):Dynamic {

		var code:String = null;

		var fillColor = '#FF00FF';
		var edgeColor = '#FF00FF';

		var alpha = 1;
		var isTransparent = false;
		var luminance = 0;

		var finishType = FINISH_TYPE_DEFAULT;

		var edgeMaterial:Dynamic = null;

		var name = lineParser.getToken();
		if (!name) {

			throw new Error('LDrawLoader: Material name was expected after "!COLOUR tag' + lineParser.getLineNumberString() + '.');

		}

		var token:String = null;
		while (true) {

			token = lineParser.getToken();

			if (!token) {

				break;

			}

			if (!parseLuminance(token)) {

				switch (token.toUpperCase()) {

					case 'CODE':

						code = lineParser.getToken();
						break;

					case 'VALUE':

						fillColor = lineParser.getToken();
						if (fillColor.startsWith('0x')) {

							fillColor = '#' + fillColor.substring(2);

						} else if (!fillColor.startsWith('#')) {

							throw new Error('LDrawLoader: Invalid color while parsing material' + lineParser.getLineNumberString() + '.');

						}

						break;

					case 'EDGE':

						edgeColor = lineParser.getToken();
						if (edgeColor.startsWith('0x')) {

							edgeColor = '#' + edgeColor.substring(2);

						} else if (!edgeColor.startsWith('#')) {

							edgeMaterial = getMaterial(edgeColor);
							if (!edgeMaterial) {

								throw new Error('LDrawLoader: Invalid edge color while parsing material' + lineParser.getLineNumberString() + '.');

							}

							edgeMaterial = edgeMaterialCache.get(edgeMaterial);

						}

						break;

					case 'ALPHA':

						alpha = parseInt(lineParser.getToken());

						if (isNaN(alpha)) {

							throw new Error('LDrawLoader: Invalid alpha value in material definition' + lineParser.getLineNumberString() + '.');

						}

						alpha = Math.max(0, Math.min(1, alpha / 255));

						if (alpha < 1) {

							isTransparent = true;

						}

						break;

					case 'LUMINANCE':

						if (!parseLuminance(lineParser.getToken())) {

							throw new Error('LDrawLoader: Invalid luminance value in material definition' + LineParser.getLineNumberString() + '.');

						}

						break;

					case 'CHROME':
						finishType = FINISH_TYPE_CHROME;
						break;

					case 'PEARLESCENT':
						finishType = FINISH_TYPE_PEARLESCENT;
						break;

					case 'RUBBER':
						finishType = FINISH_TYPE_RUBBER;
						break;

					case 'MATTE_METALLIC':
						finishType = FINISH_TYPE_MATTE_METALLIC;
						break;

					case 'METAL':
						finishType = FINISH_TYPE_METAL;
						break;

					case 'MATERIAL':
						// Not implemented
						lineParser.setToEnd();
						break;

					default:
						throw new Error('LDrawLoader: Unknown token "' + token + '" while parsing material' + lineParser.getLineNumberString() + '.');

				}

			}

		}

		var material:Dynamic = null;

		switch (finishType) {

			case FINISH_TYPE_DEFAULT:

				material = new MeshStandardMaterial({ roughness: 0.3, metalness: 0 });
				break;

			case FINISH_TYPE_PEARLESCENT:

				// Try to imitate pearlescency by making the surface glossy
				material = new MeshStandardMaterial({ roughness: 0.3, metalness: 0.25 });
				break;

			case FINISH_TYPE_CHROME:

				// Mirror finish surface
				material = new MeshStandardMaterial({ roughness: 0, metalness: 1 });
				break;

			case FINISH_TYPE_RUBBER:

				// Rubber finish
				material = new MeshStandardMaterial({ roughness: 0.9, metalness: 0 });
				break;

			case FINISH_TYPE_MATTE_METALLIC:

				// Brushed metal finish
				material = new MeshStandardMaterial({ roughness: 0.8, metalness: 0.4 });
				break;

			case FINISH_TYPE_METAL:

				// Average metal finish
				material = new MeshStandardMaterial({ roughness: 0.2, metalness: 0.85 });
				break;

			default:
				// Should not happen
				break;

		}

		material.color.setStyle(fillColor, COLOR_SPACE_LDRAW);
		material.transparent = isTransparent;
		material.premultipliedAlpha = true;
		material.opacity = alpha;
		material.depthWrite = !isTransparent;

		material.polygonOffset = true;
		material.polygonOffsetFactor = 1;

		if (luminance !== 0) {

			material.emissive.setStyle(fillColor, COLOR_SPACE_LDRAW).multiplyScalar(luminance);

		}

		if (!edgeMaterial) {

			// This is the material used for edges
			edgeMaterial = new LineBasicMaterial({
				color: new Color().setStyle(edgeColor, COLOR_SPACE_LDRAW),
				transparent: isTransparent,
				opacity: alpha,
				depthWrite: !isTransparent
			});
			edgeMaterial.color;
			edgeMaterial.userData.code = code;
			edgeMaterial.name = name + ' - Edge';

			// This is the material used for conditional edges
			var conditionalEdgeMaterial = new LDrawConditionalLineMaterial({

				fog: true,
				transparent: isTransparent,
				depthWrite: !isTransparent,
				color: new Color().setStyle(edgeColor, COLOR_SPACE_LDRAW),
				opacity: alpha,

			});
			conditionalEdgeMaterial.userData.code = code;
			conditionalEdgeMaterial.name = name + ' - Conditional Edge';

			conditionalEdgeMaterialCache.set(edgeMaterial, conditionalEdgeMaterial);

		}

		material.userData.code = code;
		material.name = name;

		edgeMaterialCache.set(material, edgeMaterial);

		addMaterial(material);

		return material;

		function parseLuminance(token:String):Bool {

			// Returns success

			var lum;

			if (token.startsWith('LUMINANCE')) {

				lum = parseInt(token.substring(9));

			} else {

				lum = parseInt(token);

			}

			if (isNaN(lum)) {

				return false;

			}

			luminance = Math.max(0, Math.min(1, lum / 255));

			return true;

		}

	}

	public function computeBuildingSteps(model:Dynamic):Void {

		// Sets userdata.buildingStep number in Group objects and userData.numBuildingSteps number in the root Group object.

		var stepNumber = 0;

		model.traverse(function(c) {

			if (c.isGroup) {

				if (c.userData.startingBuildingStep) {

					stepNumber++;

				}

				c.userData.buildingStep = stepNumber;

			}

		});

		model.userData.numBuildingSteps = stepNumber + 1;

	}

}