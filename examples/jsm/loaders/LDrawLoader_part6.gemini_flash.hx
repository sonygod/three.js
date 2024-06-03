import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.StringInput;
import haxe.io.Path;
import haxe.ds.StringMap;
import haxe.ds.WeakMap;
import haxe.ds.IntMap;
import haxe.ds.Vector;
import haxe.Exception;
import three.core.Object3D;
import three.core.Group;
import three.core.Mesh;
import three.core.LineSegments;
import three.materials.MeshStandardMaterial;
import three.materials.LineBasicMaterial;
import three.materials.Color;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.extras.LDrawConditionalLineMaterial;

class LDrawLoader extends Loader {
	public var materials:Array<MeshStandardMaterial>;
	public var materialLibrary:StringMap<MeshStandardMaterial>;
	public var edgeMaterialCache:WeakMap<MeshStandardMaterial,LineBasicMaterial>;
	public var conditionalEdgeMaterialCache:WeakMap<LineBasicMaterial,LDrawConditionalLineMaterial>;
	public var partsCache:LDrawPartsGeometryCache;
	public var fileMap:StringMap<String>;
	public var smoothNormals:Bool;
	public var partsLibraryPath:String;
	public var missingColorMaterial:MeshStandardMaterial;
	public var missingEdgeColorMaterial:LineBasicMaterial;
	public var missingConditionalEdgeColorMaterial:LDrawConditionalLineMaterial;

	public function new(manager:Loader) {
		super(manager);
		this.materials = [];
		this.materialLibrary = new StringMap();
		this.edgeMaterialCache = new WeakMap();
		this.conditionalEdgeMaterialCache = new WeakMap();
		this.partsCache = new LDrawPartsGeometryCache(this);
		this.fileMap = new StringMap();
		this.setMaterials([]);
		this.smoothNormals = true;
		this.partsLibraryPath = "";
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

	public function preloadMaterials(url:String):Dynamic {
		var fileLoader = new FileLoader(this.manager);
		fileLoader.setPath(this.path);
		fileLoader.setRequestHeader(this.requestHeader);
		fileLoader.setWithCredentials(this.withCredentials);
		return fileLoader.loadAsync(url).then(text => {
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

	public function load(url:String, onLoad:Object3D->Void, onProgress:Bytes->Void, onError:Dynamic->Void):Void {
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

	public function parse(text:String, onLoad:Object3D->Void, onError:Dynamic->Void):Void {
		this.partsCache.parseModel(text, this.materialLibrary).then(group => {
			this.applyMaterialsToMesh(group, MAIN_COLOUR_CODE, this.materialLibrary, true);
			this.computeBuildingSteps(group);
			group.userData.fileName = "";
			onLoad(group);
		}).catch(onError);
	}

	public function setMaterials(materials:Array<MeshStandardMaterial>):LDrawLoader {
		this.materialLibrary = new StringMap();
		this.materials = [];
		for (i in 0...materials.length) {
			this.addMaterial(materials[i]);
		}
		this.addMaterial(this.parseColorMetaDirective(new LineParser("Main_Colour CODE 16 VALUE #FF8080 EDGE #333333")));
		this.addMaterial(this.parseColorMetaDirective(new LineParser("Edge_Colour CODE 24 VALUE #A0A0A0 EDGE #333333")));
		return this;
	}

	public function setFileMap(fileMap:StringMap<String>):LDrawLoader {
		this.fileMap = fileMap;
		return this;
	}

	public function addMaterial(material:MeshStandardMaterial):Void {
		var matLib = this.materialLibrary;
		if (!matLib.exists(material.userData.code)) {
			this.materials.push(material);
			matLib.set(material.userData.code, material);
		}
	}

	public function getMaterial(colorCode:String):MeshStandardMaterial {
		if (colorCode.startsWith("0x2")) {
			var color = colorCode.substring(3);
			return this.parseColorMetaDirective(new LineParser("Direct_Color_" + color + " CODE -1 VALUE #" + color + " EDGE #" + color + ""));
		}
		return this.materialLibrary.get(colorCode) || null;
	}

	public function applyMaterialsToMesh(group:Group, parentColorCode:String, materialHierarchy:StringMap<MeshStandardMaterial>, finalMaterialPass:Bool = false):Void {
		var loader = this;
		var parentIsPassthrough = parentColorCode == MAIN_COLOUR_CODE;
		group.traverse(c => {
			if (c.isMesh || c.isLineSegments) {
				if (Std.isOfType(c.material, Array)) {
					for (i in 0...c.material.length) {
						if (!Std.isOfType(c.material[i], MeshStandardMaterial)) {
							c.material[i] = getMaterial(c, c.material[i]);
						}
					}
				} else if (!Std.isOfType(c.material, MeshStandardMaterial)) {
					c.material = getMaterial(c, c.material);
				}
			}
		});

		function getMaterial(c:Object3D, colorCode:Dynamic):MeshStandardMaterial {
			if (parentIsPassthrough && !materialHierarchy.exists(colorCode) && !finalMaterialPass) {
				return colorCode;
			}
			var forEdge = c.isLineSegments || Std.isOfType(c, LDrawConditionalLineMaterial);
			var isPassthrough = !forEdge && colorCode == MAIN_COLOUR_CODE || forEdge && colorCode == MAIN_EDGE_COLOUR_CODE;
			if (isPassthrough) {
				colorCode = parentColorCode;
			}
			var material:MeshStandardMaterial = null;
			if (materialHierarchy.exists(colorCode)) {
				material = materialHierarchy.get(colorCode);
			} else if (finalMaterialPass) {
				material = loader.getMaterial(colorCode);
				if (material == null) {
					console.warn("LDrawLoader: Material properties for code " + colorCode + " not available.");
					material = loader.missingColorMaterial;
				}
			} else {
				return colorCode;
			}
			if (c.isLineSegments) {
				material = loader.edgeMaterialCache.get(material);
				if (Std.isOfType(c, LDrawConditionalLineMaterial)) {
					material = loader.conditionalEdgeMaterialCache.get(material);
				}
			}
			return material;
		}
	}

	public function getMainMaterial():MeshStandardMaterial {
		return this.getMaterial(MAIN_COLOUR_CODE);
	}

	public function getMainEdgeMaterial():LineBasicMaterial {
		var mat = this.getMaterial(MAIN_EDGE_COLOUR_CODE);
		return mat != null ? this.edgeMaterialCache.get(mat) : null;
	}

	public function parseColorMetaDirective(lineParser:LineParser):MeshStandardMaterial {
		var code:String = null;
		var fillColor:String = "#FF00FF";
		var edgeColor:String = "#FF00FF";
		var alpha:Float = 1;
		var isTransparent:Bool = false;
		var luminance:Float = 0;
		var finishType:Int = FINISH_TYPE_DEFAULT;
		var edgeMaterial:LineBasicMaterial = null;
		var name = lineParser.getToken();
		if (name == null) {
			throw new Exception("LDrawLoader: Material name was expected after \"!COLOUR tag" + lineParser.getLineNumberString() + ".");
		}
		var token:String = null;
		while (true) {
			token = lineParser.getToken();
			if (token == null) {
				break;
			}
			if (!parseLuminance(token)) {
				switch (token.toUpperCase()) {
					case "CODE":
						code = lineParser.getToken();
						break;
					case "VALUE":
						fillColor = lineParser.getToken();
						if (fillColor.startsWith("0x")) {
							fillColor = "#" + fillColor.substring(2);
						} else if (!fillColor.startsWith("#")) {
							throw new Exception("LDrawLoader: Invalid color while parsing material" + lineParser.getLineNumberString() + ".");
						}
						break;
					case "EDGE":
						edgeColor = lineParser.getToken();
						if (edgeColor.startsWith("0x")) {
							edgeColor = "#" + edgeColor.substring(2);
						} else if (!edgeColor.startsWith("#")) {
							edgeMaterial = this.getMaterial(edgeColor);
							if (edgeMaterial == null) {
								throw new Exception("LDrawLoader: Invalid edge color while parsing material" + lineParser.getLineNumberString() + ".");
							}
							edgeMaterial = this.edgeMaterialCache.get(edgeMaterial);
						}
						break;
					case "ALPHA":
						alpha = Std.parseInt(lineParser.getToken());
						if (Math.isNaN(alpha)) {
							throw new Exception("LDrawLoader: Invalid alpha value in material definition" + lineParser.getLineNumberString() + ".");
						}
						alpha = Math.max(0, Math.min(1, alpha / 255));
						if (alpha < 1) {
							isTransparent = true;
						}
						break;
					case "LUMINANCE":
						if (!parseLuminance(lineParser.getToken())) {
							throw new Exception("LDrawLoader: Invalid luminance value in material definition" + LineParser.getLineNumberString() + ".");
						}
						break;
					case "CHROME":
						finishType = FINISH_TYPE_CHROME;
						break;
					case "PEARLESCENT":
						finishType = FINISH_TYPE_PEARLESCENT;
						break;
					case "RUBBER":
						finishType = FINISH_TYPE_RUBBER;
						break;
					case "MATTE_METALLIC":
						finishType = FINISH_TYPE_MATTE_METALLIC;
						break;
					case "METAL":
						finishType = FINISH_TYPE_METAL;
						break;
					case "MATERIAL":
						lineParser.setToEnd();
						break;
					default:
						throw new Exception("LDrawLoader: Unknown token \"" + token + "\" while parsing material" + lineParser.getLineNumberString() + ".");
				}
			}
		}
		var material:MeshStandardMaterial = null;
		switch (finishType) {
			case FINISH_TYPE_DEFAULT:
				material = new MeshStandardMaterial({ roughness: 0.3, metalness: 0 });
				break;
			case FINISH_TYPE_PEARLESCENT:
				material = new MeshStandardMaterial({ roughness: 0.3, metalness: 0.25 });
				break;
			case FINISH_TYPE_CHROME:
				material = new MeshStandardMaterial({ roughness: 0, metalness: 1 });
				break;
			case FINISH_TYPE_RUBBER:
				material = new MeshStandardMaterial({ roughness: 0.9, metalness: 0 });
				break;
			case FINISH_TYPE_MATTE_METALLIC:
				material = new MeshStandardMaterial({ roughness: 0.8, metalness: 0.4 });
				break;
			case FINISH_TYPE_METAL:
				material = new MeshStandardMaterial({ roughness: 0.2, metalness: 0.85 });
				break;
			default:
				break;
		}
		material.color.setStyle(fillColor, COLOR_SPACE_LDRAW);
		material.transparent = isTransparent;
		material.premultipliedAlpha = true;
		material.opacity = alpha;
		material.depthWrite = !isTransparent;
		material.polygonOffset = true;
		material.polygonOffsetFactor = 1;
		if (luminance != 0) {
			material.emissive.setStyle(fillColor, COLOR_SPACE_LDRAW).multiplyScalar(luminance);
		}
		if (edgeMaterial == null) {
			edgeMaterial = new LineBasicMaterial({
				color: new Color().setStyle(edgeColor, COLOR_SPACE_LDRAW),
				transparent: isTransparent,
				opacity: alpha,
				depthWrite: !isTransparent
			});
			edgeMaterial.userData.code = code;
			edgeMaterial.name = name + " - Edge";
			var conditionalEdgeMaterial = new LDrawConditionalLineMaterial({
				fog: true,
				transparent: isTransparent,
				depthWrite: !isTransparent,
				color: new Color().setStyle(edgeColor, COLOR_SPACE_LDRAW),
				opacity: alpha
			});
			conditionalEdgeMaterial.userData.code = code;
			conditionalEdgeMaterial.name = name + " - Conditional Edge";
			this.conditionalEdgeMaterialCache.set(edgeMaterial, conditionalEdgeMaterial);
		}
		material.userData.code = code;
		material.name = name;
		this.edgeMaterialCache.set(material, edgeMaterial);
		this.addMaterial(material);
		return material;

		function parseLuminance(token:String):Bool {
			var lum:Int;
			if (token.startsWith("LUMINANCE")) {
				lum = Std.parseInt(token.substring(9));
			} else {
				lum = Std.parseInt(token);
			}
			if (Math.isNaN(lum)) {
				return false;
			}
			luminance = Math.max(0, Math.min(1, lum / 255));
			return true;
		}
	}

	public function computeBuildingSteps(model:Group):Void {
		var stepNumber:Int = 0;
		model.traverse(c => {
			if (Std.isOfType(c, Group)) {
				if (c.userData.startingBuildingStep) {
					stepNumber++;
				}
				c.userData.buildingStep = stepNumber;
			}
		});
		model.userData.numBuildingSteps = stepNumber + 1;
	}
}

class LineParser {
	public var tokens:Array<String>;
	public var currentToken:Int;
	public var lineNumber:Int;
	public var line:String;

	public function new(line:String, lineNumber:Int = 0) {
		this.tokens = line.split(/\s+/g);
		this.currentToken = 0;
		this.lineNumber = lineNumber;
		this.line = line;
	}

	public function getToken():String {
		if (this.currentToken < this.tokens.length) {
			return this.tokens[this.currentToken ++];
		}
		return null;
	}

	public function setToEnd():Void {
		this.currentToken = this.tokens.length;
	}

	public function getLineNumberString():String {
		return " (line " + (this.lineNumber + 1) + ")";
	}
}

class LDrawPartsGeometryCache {
	public var loader:LDrawLoader;
	public var geometryCache:StringMap<Dynamic>;

	public function new(loader:LDrawLoader) {
		this.loader = loader;
		this.geometryCache = new StringMap();
	}

	public function parseModel(text:String, materialLibrary:StringMap<MeshStandardMaterial>):Dynamic {
		var lines = text.split(/[\n\r]/g);
		var lineNumber = 0;
		var group = new Group();
		var currentGroup = group;
		var currentMaterial = null;
		var parseScopeStack = [];
		var parseScope = {
			materials: materialLibrary,
			group: currentGroup
		};
		parseScopeStack.push(parseScope);
		var buildingStep = false;
		var startingBuildingStep = false;
		var currentStepNumber = 0;
		var currentStep = null;
		var lastStepNumber = 0;

		for (i in 0...lines.length) {
			var line = lines[i];
			var lineParser = new LineParser(line, lineNumber);
			var token = lineParser.getToken();
			if (token == null) {
				lineNumber++;
				continue;
			}
			switch (token) {
				case "0":
					var subtoken = lineParser.getToken();
					if (subtoken == null) {
						throw new Exception("LDrawLoader: Unexpected end of line." + lineParser.getLineNumberString());
					}
					switch (subtoken) {
						case "FILE":
							this.parseFileLine(lineParser, group);
							break;
						case "STEP":
							buildingStep = true;
							startingBuildingStep = true;
							currentStepNumber = Std.parseInt(lineParser.getToken());
							currentStep = new Group();
							currentStep.userData.startingBuildingStep = true;
							currentStep.userData.buildingStep = currentStepNumber;
							currentGroup.add(currentStep);
							currentGroup = currentStep;
							break;
						case "SUBSTEP":
							buildingStep = true;
							startingBuildingStep = false;
							currentStepNumber = Std.parseInt(lineParser.getToken());
							currentStep = new Group();
							currentStep.userData.buildingStep = currentStepNumber;
							currentGroup.add(currentStep);
							currentGroup = currentStep;
							break;
						case "GROUP":
							var groupName = lineParser.getToken();
							if (groupName == null) {
								throw new Exception("LDrawLoader: Group name expected." + lineParser.getLineNumberString());
							}
							var group = new Group();
							group.name = groupName;
							currentGroup.add(group);
							currentGroup = group;
							break;
						case "PART":
							var part = this.parsePartLine(lineParser);
							if (part != null) {
								currentGroup.add(part);
							}
							break;
						case "LINE":
							var line = this.parseLineLine(lineParser);
							if (line != null) {
								currentGroup.add(line);
							}
							break;
						case "TRI":
							var triangle = this.parseTriangleLine(lineParser);
							if (triangle != null) {
								currentGroup.add(triangle);
							}
							break;
						case "QUAD":
							var quad = this.parseQuadLine(lineParser);
							if (quad != null) {
								currentGroup.add(quad);
							}
							break;
						case "COMMENT":
							var comment = this.parseCommentLine(lineParser);
							if (comment != null) {
								currentGroup.add(comment);
							}
							break;
						case "COLOUR":
							var material = this.loader.parseColorMetaDirective(lineParser);
							currentMaterial = material;
							parseScopeStack.push({
								materials: new StringMap(),
								group: currentGroup
							});
							parseScopeStack[parseScopeStack.length - 1].materials.set(material.userData.code, material);
							break;
						case "MATERIAL":
							var material = this.loader.parseColorMetaDirective(lineParser);
							currentMaterial = material;
							break;
						case "BFC":
							var bfc = lineParser.getToken();
							if (bfc == null) {
								throw new Exception("LDrawLoader: Missing BFC value." + lineParser.getLineNumberString());
							}
							currentGroup.userData.bfc = bfc;
							break;
						case "END":
							if (buildingStep) {
								buildingStep = false;
								if (currentGroup.parent != null) {
									currentGroup = cast currentGroup.parent;
								}
							} else {
								if (parseScopeStack.length > 1) {
									parseScopeStack.pop();
									currentGroup = parseScopeStack[parseScopeStack.length - 1].group;
								}
							}
							break;
						default:
							throw new Exception("LDrawLoader: Unknown directive " + subtoken + "." + lineParser.getLineNumberString());
					}
					break;
				case "1":
					var subtoken = lineParser.getToken();
					if (subtoken == null) {
						throw new Exception("LDrawLoader: Unexpected end of line." + lineParser.getLineNumberString());
					}
					switch (subtoken) {
						case "FILE":
							this.parseFileLine(lineParser, group);
							break;
						default:
							throw new Exception("LDrawLoader: Unknown directive " + subtoken + "." + lineParser.getLineNumberString());
					}
					break;
				case "2":
					var subtoken = lineParser.getToken();
					if (subtoken == null) {
						throw new Exception("LDrawLoader: Unexpected end of line." + lineParser.getLineNumberString());
					}
					switch (subtoken) {
						case "FILE":
							this.parseFileLine(lineParser, group);
							break;
						default:
							throw new Exception("LDrawLoader: Unknown directive " + subtoken + "." + lineParser.getLineNumberString());
					}
					break;
				case "3":
					var subtoken = lineParser.getToken();
					if (subtoken == null) {
						throw new Exception("LDrawLoader: Unexpected end of line." + lineParser.getLineNumberString());
					}
					switch (subtoken) {
						case "FILE":
							this.parseFileLine(lineParser, group);
							break;
						default:
							throw new Exception("LDrawLoader: Unknown directive " + subtoken + "." + lineParser.getLineNumberString());
					}
					break;
				case "4":
					var subtoken = lineParser.getToken();
					if (subtoken == null) {
						throw new Exception("LDrawLoader: Unexpected end of line." + lineParser.getLineNumberString());
					}
					switch (subtoken) {
						case "FILE":
							this.parseFileLine(lineParser, group);
							break;
						default:
							throw new Exception("LDrawLoader: Unknown directive " + subtoken + "." + lineParser.getLineNumberString());
					}
					break;
				case "5":
					var subtoken = lineParser.getToken();
					if (subtoken == null) {
						throw new Exception("LDrawLoader: Unexpected end of line." + lineParser.getLineNumberString());
					}
					switch (subtoken) {
						case "FILE":
							this.parseFileLine(lineParser, group);
							break;
						default:
							throw new Exception("LDrawLoader: Unknown directive " + subtoken + "." + lineParser.getLineNumberString());
					}
					break;
				default:
					throw new Exception("LDrawLoader: Unknown directive " + token + "." + lineParser.getLineNumberString());
			}
			lineNumber++;
		}
		return group;
	}

	public function parseFileLine(lineParser:LineParser, group:Group):Void {
		var fileName = lineParser.getToken();
		if (fileName == null) {
			throw new Exception("LDrawLoader: File name expected." + lineParser.getLineNumberString());
		}
		var fileMap = this.loader.fileMap;
		var filePath = null;
		if (fileMap.exists(fileName)) {
			filePath = fileMap.get(fileName);
		} else {
			filePath = this.loader.partsLibraryPath + fileName;
		}
		var fileLoader = new FileLoader(this.loader.manager);
		fileLoader.setPath(filePath);
		fileLoader.setRequestHeader(this.loader.requestHeader);
		fileLoader.setWithCredentials(this.loader.withCredentials);
		fileLoader.load(fileName, text => {
			var subGroup = cast this.parseModel(text, parseScopeStack[parseScopeStack.length - 1].materials);
			group.add(subGroup);
			// Apply material library to the loaded part
			this.loader.applyMaterialsToMesh(subGroup, MAIN_COLOUR_CODE, parseScopeStack[parseScopeStack.length - 1].materials, true);
		});
	}

	public function parsePartLine(lineParser:LineParser):Object3D {
		var colorCode = lineParser.getToken();
		if (colorCode == null) {
			throw new Exception("LDrawLoader: Color code expected." + lineParser.getLineNumberString());
		}
		var fileName = lineParser.getToken();
		if (fileName == null) {
			throw new Exception("LDrawLoader: File name expected." + lineParser.getLineNumberString());
		}
		var fileMap = this.loader.fileMap;
		var filePath = null;
		if (fileMap.exists(fileName)) {
			filePath = fileMap.get(fileName);
		} else {
			filePath = this.loader.partsLibraryPath + fileName;
		}
		var matrix = this.parseMatrix(lineParser);
		if (this.geometryCache.exists(filePath)) {
			var group = cast this.geometryCache.get(filePath);
			group.matrix.copy(matrix);
			group.matrixAutoUpdate = false;
			group.updateMatrixWorld(true);
			return group;
		}
		var fileLoader = new FileLoader(this.loader.manager);
		fileLoader.setPath(filePath);
		fileLoader.setRequestHeader(this.loader.requestHeader);
		fileLoader.setWithCredentials(this.loader.withCredentials);
		return fileLoader.loadAsync(fileName).then(text => {
			var group = cast this.parseModel(text, parseScopeStack[parseScopeStack.length - 1].materials);
			group.matrix.copy(matrix);
			group.matrixAutoUpdate = false;
			group.updateMatrixWorld(true);
			this.geometryCache.set(filePath, group);
			return group;
		});
	}

	public function parseLineLine(lineParser:LineParser):LineSegments {
		var colorCode = lineParser.getToken();
		if (colorCode == null) {
			throw new Exception("LDrawLoader: Color code expected." + lineParser.getLineNumberString());
		}
		var v1 = this.parseVector(lineParser);
		var v2 = this.parseVector(lineParser);
		var material:LineBasicMaterial = this.loader.getMaterial(colorCode);
		if (material == null) {
			material = this.loader.missingEdgeColorMaterial;
		}
		var geometry = new three.geometries.BufferGeometry();
		geometry.setAttribute("position", new three.core.BufferAttribute(new Float32Array([v1.x, v1.y, v1.z, v2.x, v2.y, v2.z]), 3));
		return new LineSegments(geometry, material);
	}

	public function parseTriangleLine(lineParser:LineParser):Mesh {
		var colorCode = lineParser.getToken();
		if (colorCode == null) {
			throw new Exception("LDrawLoader: Color code expected." + lineParser.getLineNumberString());
		}
		var v1 = this.parseVector(lineParser);
		var v2 = this.parseVector(lineParser);
		var v3 = this.parseVector(lineParser);
		var material:MeshStandardMaterial = this.loader.getMaterial(colorCode);
		if (material == null) {
			material = this.loader.missingColorMaterial;
		}
		var geometry = new three.geometries.BufferGeometry();
		geometry.setAttribute("position", new three.core.BufferAttribute(new Float32Array([v1.x, v1.y, v1.z, v2.x, v2.y, v2.z, v3.x, v3.y, v3.z]), 3));
		geometry.computeVertexNormals();
		return new Mesh(geometry, material);
	}

	public function parseQuadLine(lineParser:LineParser):Mesh {
		var colorCode = lineParser.getToken();
		if (colorCode == null) {
			throw new Exception("LDrawLoader: Color code expected." + lineParser.getLineNumberString());
		}
		var v1 = this.parseVector(lineParser);
		var v2 = this.parseVector(lineParser);
		var v3 = this.parseVector(lineParser);
		var v4 = this.parseVector(lineParser);
		var material:MeshStandardMaterial = this.loader.getMaterial(colorCode);
		if (material == null) {
			material = this.loader.missingColorMaterial;
		}
		var geometry = new three.geometries.BufferGeometry();
		geometry.setAttribute("position", new three.core.BufferAttribute(new Float32Array([v1.x, v1.y, v1.z, v2.x, v2.y, v2.z, v3.x, v3.y, v3.z, v4.x, v4.y, v4.z]), 3));
		geometry.computeVertexNormals();
		return new Mesh(geometry, material);
	}

	public function parseCommentLine(lineParser:LineParser):Object3D {
		return null;
	}

	public function parseMatrix(lineParser:LineParser):three.math.Matrix4 {
		var matrix = new three.math.Matrix4();
		var m11 = Std.parseFloat(lineParser.getToken());
		var m12 = Std.parseFloat(lineParser.getToken());
		var m13 = Std.parseFloat(lineParser.getToken());
		var m14 = Std.parseFloat(lineParser.getToken());
		var m21 = Std.parseFloat(lineParser.getToken());
		var m22 = Std.parseFloat(lineParser.getToken());
		var m23 = Std.parseFloat(lineParser.getToken());
		var m24 = Std.parseFloat(lineParser.getToken());
		var m31 = Std.parseFloat(lineParser.getToken());
		var m32 = Std.parseFloat(lineParser.getToken());
		var m33 = Std.parseFloat(lineParser.getToken());
		var m34 = Std.parseFloat(lineParser.getToken());
		var m41 = Std.parseFloat(lineParser.getToken());
		var m42 = Std.parseFloat(lineParser.getToken());
		var m43 = Std.parseFloat(lineParser.getToken());
		var m44 = Std.parseFloat(lineParser.getToken());
		matrix.set(m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44);
		return matrix;
	}

	public function parseVector(lineParser:LineParser):three.math.Vector3 {
		var x = Std.parseFloat(lineParser.getToken());
		var y = Std.parseFloat(lineParser.getToken());
		var z = Std.parseFloat(lineParser.getToken());
		return new three.math.Vector3(x, y, z);
	}
}

class LDrawConditionalLineMaterial extends LDrawConditionalLineMaterial {
	public var userData:Dynamic;
	public var name:String;

	public function new(parameters:Dynamic) {
		super(parameters);
		this.userData = new Dynamic();
	}
}

const MAIN_COLOUR_CODE:String = "16";
const MAIN_EDGE_COLOUR_CODE:String = "24";
const COLOR_SPACE_LDRAW:String = "srgb";
const FINISH_TYPE_DEFAULT:Int = 0;
const FINISH_TYPE_PEARLESCENT:Int = 1;
const FINISH_TYPE_CHROME:Int = 2;
const FINISH_TYPE_RUBBER:Int = 3;
const FINISH_TYPE_MATTE_METALLIC:Int = 4;
const FINISH_TYPE_METAL:Int = 5;