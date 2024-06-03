package;

import three.AddOperation;
import three.BackSide;
import three.BufferGeometry;
import three.ClampToEdgeWrapping;
import three.Color;
import three.DoubleSide;
import three.EquirectangularReflectionMapping;
import three.EquirectangularRefractionMapping;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.FrontSide;
import three.LineBasicMaterial;
import three.LineSegments;
import three.Loader;
import three.Mesh;
import three.MeshPhongMaterial;
import three.MeshPhysicalMaterial;
import three.MeshStandardMaterial;
import three.MirroredRepeatWrapping;
import three.Points;
import three.PointsMaterial;
import three.RepeatWrapping;
import three.SRGBColorSpace;
import three.TextureLoader;
import three.Vector2;

import lwo.IFFParser;

class LWOLoader extends Loader {

	public var resourcePath:String;

	public function new(manager:Loader, ?parameters:Dynamic) {
		super(manager);
		this.resourcePath = (parameters.resourcePath != null) ? parameters.resourcePath : "";
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var scope = this;
		var path = (scope.path == "") ? extractParentUrl(url, "Objects") : scope.path;
		var modelName = url.split(path).pop().split(".").shift();
		var loader = new FileLoader(this.manager);
		loader.setPath(scope.path);
		loader.setResponseType("arraybuffer");
		loader.load(url, function(buffer:haxe.io.Bytes) {
			try {
				onLoad(scope.parse(buffer, path, modelName));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(iffBuffer:haxe.io.Bytes, path:String, modelName:String):Dynamic {
		_lwoTree = new IFFParser().parse(iffBuffer);
		var textureLoader = new TextureLoader(this.manager).setPath(this.resourcePath != "" ? this.resourcePath : path).setCrossOrigin(this.crossOrigin);
		return new LWOTreeParser(textureLoader).parse(modelName);
	}
}

class LWOTreeParser {

	public var textureLoader:TextureLoader;

	public function new(textureLoader:TextureLoader) {
		this.textureLoader = textureLoader;
	}

	public function parse(modelName:String):Dynamic {
		this.materials = new MaterialParser(this.textureLoader).parse();
		this.defaultLayerName = modelName;
		this.meshes = this.parseLayers();
		return {
			materials: this.materials,
			meshes: this.meshes,
		};
	}

	private var materials:Array<Dynamic>;
	private var defaultLayerName:String;
	private var meshes:Array<Dynamic>;

	private function parseLayers():Array<Dynamic> {
		var meshes = new Array<Dynamic>();
		var finalMeshes = new Array<Dynamic>();
		var geometryParser = new GeometryParser();
		var scope = this;
		_lwoTree.layers.forEach(function(layer:Dynamic) {
			var geometry = geometryParser.parse(layer.geometry, layer);
			var mesh = scope.parseMesh(geometry, layer);
			meshes[layer.number] = mesh;
			if (layer.parent == -1) finalMeshes.push(mesh);
			else meshes[layer.parent].add(mesh);
		});
		this.applyPivots(finalMeshes);
		return finalMeshes;
	}

	private function parseMesh(geometry:BufferGeometry, layer:Dynamic):Dynamic {
		var mesh:Dynamic;
		var materials = this.getMaterials(geometry.userData.matNames, layer.geometry.type);
		if (layer.geometry.type == "points") mesh = new Points(geometry, materials);
		else if (layer.geometry.type == "lines") mesh = new LineSegments(geometry, materials);
		else mesh = new Mesh(geometry, materials);
		if (layer.name != null) mesh.name = layer.name;
		else mesh.name = this.defaultLayerName + "_layer_" + layer.number;
		mesh.userData.pivot = layer.pivot;
		return mesh;
	}

	private function applyPivots(meshes:Array<Dynamic>):Void {
		meshes.forEach(function(mesh:Dynamic) {
			mesh.traverse(function(child:Dynamic) {
				var pivot = child.userData.pivot;
				child.position.x += pivot[0];
				child.position.y += pivot[1];
				child.position.z += pivot[2];
				if (child.parent != null) {
					var parentPivot = child.parent.userData.pivot;
					child.position.x -= parentPivot[0];
					child.position.y -= parentPivot[1];
					child.position.z -= parentPivot[2];
				}
			});
		});
	}

	private function getMaterials(namesArray:Array<String>, type:String):Dynamic {
		var materials = new Array<Dynamic>();
		var scope = this;
		namesArray.forEach(function(name:String, i:Int) {
			materials[i] = scope.getMaterialByName(name);
		});
		if (type == "points" || type == "lines") {
			materials.forEach(function(mat:Dynamic, i:Int) {
				var spec = {
					color: mat.color,
				};
				if (type == "points") {
					spec.size = 0.1;
					spec.map = mat.map;
					materials[i] = new PointsMaterial(spec);
				} else if (type == "lines") {
					materials[i] = new LineBasicMaterial(spec);
				}
			});
		}
		var filtered = materials.filter(function(m:Dynamic) {
			return m != null;
		});
		if (filtered.length == 1) return filtered[0];
		return materials;
	}

	private function getMaterialByName(name:String):Dynamic {
		return this.materials.filter(function(m:Dynamic) {
			return m.name == name;
		})[0];
	}

}

class MaterialParser {

	public var textureLoader:TextureLoader;

	public function new(textureLoader:TextureLoader) {
		this.textureLoader = textureLoader;
	}

	public function parse():Array<Dynamic> {
		var materials = new Array<Dynamic>();
		this.textures = new haxe.ds.StringMap();
		for (name in _lwoTree.materials) {
			if (_lwoTree.format == "LWO3") {
				materials.push(this.parseMaterial(_lwoTree.materials[name], name, _lwoTree.textures));
			} else if (_lwoTree.format == "LWO2") {
				materials.push(this.parseMaterialLwo2(_lwoTree.materials[name], name, _lwoTree.textures));
			}
		}
		return materials;
	}

	private var textures:haxe.ds.StringMap<Dynamic>;

	private function parseMaterial(materialData:Dynamic, name:String, textures:Array<Dynamic>):Dynamic {
		var params = {
			name: name,
			side: this.getSide(materialData.attributes),
			flatShading: this.getSmooth(materialData.attributes),
		};
		var connections = this.parseConnections(materialData.connections, materialData.nodes);
		var maps = this.parseTextureNodes(connections.maps);
		this.parseAttributeImageMaps(connections.attributes, textures, maps, materialData.maps);
		var attributes = this.parseAttributes(connections.attributes, maps);
		this.parseEnvMap(connections, maps, attributes);
		params = haxe.ds.StringMap.merge(maps, params);
		params = haxe.ds.StringMap.merge(params, attributes);
		var materialType = this.getMaterialType(connections.attributes);
		if (materialType != MeshPhongMaterial) delete params.refractionRatio;
		return Type.createInstance(materialType, params);
	}

	private function parseMaterialLwo2(materialData:Dynamic, name:String, textures:Array<Dynamic>):Dynamic {
		var params = {
			name: name,
			side: this.getSide(materialData.attributes),
			flatShading: this.getSmooth(materialData.attributes),
		};
		var attributes = this.parseAttributes(materialData.attributes, {});
		params = haxe.ds.StringMap.merge(params, attributes);
		return new MeshPhongMaterial(params);
	}

	private function getSide(attributes:Dynamic):Int {
		if (attributes.side == null) return BackSide;
		switch (attributes.side) {
		case 0:
		case 1:
			return BackSide;
		case 2: return FrontSide;
		case 3: return DoubleSide;
		}
		return BackSide;
	}

	private function getSmooth(attributes:Dynamic):Bool {
		if (attributes.smooth == null) return true;
		return !attributes.smooth;
	}

	private function parseConnections(connections:Dynamic, nodes:Dynamic):Dynamic {
		var materialConnections = {
			maps: new haxe.ds.StringMap(),
		};
		var inputName = connections.inputName;
		var inputNodeName = connections.inputNodeName;
		var nodeName = connections.nodeName;
		var scope = this;
		inputName.forEach(function(name:String, index:Int) {
			if (name == "Material") {
				var matNode = scope.getNodeByRefName(inputNodeName[index], nodes);
				materialConnections.attributes = matNode.attributes;
				materialConnections.envMap = matNode.fileName;
				materialConnections.name = inputNodeName[index];
			}
		});
		nodeName.forEach(function(name:String, index:Int) {
			if (name == materialConnections.name) {
				materialConnections.maps.set(inputName[index], scope.getNodeByRefName(inputNodeName[index], nodes));
			}
		});
		return materialConnections;
	}

	private function getNodeByRefName(refName:String, nodes:Dynamic):Dynamic {
		for (name in nodes) {
			if (nodes[name].refName == refName) return nodes[name];
		}
		return null;
	}

	private function parseTextureNodes(textureNodes:haxe.ds.StringMap<Dynamic>):haxe.ds.StringMap<Dynamic> {
		var maps = new haxe.ds.StringMap<Dynamic>();
		for (name in textureNodes) {
			var node = textureNodes.get(name);
			var path = node.fileName;
			if (path == null) return maps;
			var texture = this.loadTexture(path);
			if (node.widthWrappingMode != null) texture.wrapS = this.getWrappingType(node.widthWrappingMode);
			if (node.heightWrappingMode != null) texture.wrapT = this.getWrappingType(node.heightWrappingMode);
			switch (name) {
			case "Color":
				maps.set("map", texture);
				texture.colorSpace = SRGBColorSpace;
				break;
			case "Roughness":
				maps.set("roughnessMap", texture);
				maps.set("roughness", 1);
				break;
			case "Specular":
				maps.set("specularMap", texture);
				texture.colorSpace = SRGBColorSpace;
				maps.set("specular", 0xffffff);
				break;
			case "Luminous":
				maps.set("emissiveMap", texture);
				texture.colorSpace = SRGBColorSpace;
				maps.set("emissive", 0x808080);
				break;
			case "Luminous Color":
				maps.set("emissive", 0x808080);
				break;
			case "Metallic":
				maps.set("metalnessMap", texture);
				maps.set("metalness", 1);
				break;
			case "Transparency":
			case "Alpha":
				maps.set("alphaMap", texture);
				maps.set("transparent", true);
				break;
			case "Normal":
				maps.set("normalMap", texture);
				if (node.amplitude != null) maps.set("normalScale", new Vector2(node.amplitude, node.amplitude));
				break;
			case "Bump":
				maps.set("bumpMap", texture);
				break;
			}
		}
		if (maps.exists("roughnessMap") && maps.exists("specularMap")) maps.remove("specularMap");
		return maps;
	}

	private function parseAttributeImageMaps(attributes:Dynamic, textures:Array<Dynamic>, maps:haxe.ds.StringMap<Dynamic>, materialMaps:Array<Dynamic>):Void {
		for (name in attributes) {
			var attribute = attributes[name];
			if (attribute.maps != null) {
				var mapData = attribute.maps[0];
				var path = this.getTexturePathByIndex(mapData.imageIndex, textures);
				if (path == null) return;
				var texture = this.loadTexture(path);
				if (mapData.wrap != null) texture.wrapS = this.getWrappingType(mapData.wrap.w);
				if (mapData.wrap != null) texture.wrapT = this.getWrappingType(mapData.wrap.h);
				switch (name) {
				case "Color":
					maps.set("map", texture);
					texture.colorSpace = SRGBColorSpace;
					break;
				case "Diffuse":
					maps.set("aoMap", texture);
					break;
				case "Roughness":
					maps.set("roughnessMap", texture);
					maps.set("roughness", 1);
					break;
				case "Specular":
					maps.set("specularMap", texture);
					texture.colorSpace = SRGBColorSpace;
					maps.set("specular", 0xffffff);
					break;
				case "Luminosity":
					maps.set("emissiveMap", texture);
					texture.colorSpace = SRGBColorSpace;
					maps.set("emissive", 0x808080);
					break;
				case "Metallic":
					maps.set("metalnessMap", texture);
					maps.set("metalness", 1);
					break;
				case "Transparency":
				case "Alpha":
					maps.set("alphaMap", texture);
					maps.set("transparent", true);
					break;
				case "Normal":
					maps.set("normalMap", texture);
					break;
				case "Bump":
					maps.set("bumpMap", texture);
					break;
				}
			}
		}
	}

	private function parseAttributes(attributes:Dynamic, maps:haxe.ds.StringMap<Dynamic>):haxe.ds.StringMap<Dynamic> {
		var params = new haxe.ds.StringMap<Dynamic>();
		if (attributes.Color != null && !maps.exists("map")) {
			params.set("color", new Color().fromArray(attributes.Color.value));
		} else {
			params.set("color", new Color());
		}
		if (attributes.Transparency != null && attributes.Transparency.value != 0) {
			params.set("opacity", 1 - attributes.Transparency.value);
			params.set("transparent", true);
		}
		if (attributes["Bump Height"] != null) params.set("bumpScale", attributes["Bump Height"].value * 0.1);
		this.parsePhysicalAttributes(params, attributes, maps);
		this.parseStandardAttributes(params, attributes, maps);
		this.parsePhongAttributes(params, attributes, maps);
		return params;
	}

	private function parsePhysicalAttributes(params:haxe.ds.StringMap<Dynamic>, attributes:Dynamic, maps:haxe.ds.StringMap<Dynamic>):Void {
		if (attributes.Clearcoat != null && attributes.Clearcoat.value > 0) {
			params.set("clearcoat", attributes.Clearcoat.value);
			if (attributes["Clearcoat Gloss"] != null) {
				params.set("clearcoatRoughness", 0.5 * (1 - attributes["Clearcoat Gloss"].value));
			}
		}
	}

	private function parseStandardAttributes(params:haxe.ds.StringMap<Dynamic>, attributes:Dynamic, maps:haxe.ds.StringMap<Dynamic>):Void {
		if (attributes.Luminous != null) {
			params.set("emissiveIntensity", attributes.Luminous.value);
			if (attributes["Luminous Color"] != null && !maps.exists("emissive")) {
				params.set("emissive", new Color().fromArray(attributes["Luminous Color"].value));
			} else {
				params.set("emissive", new Color(0x808080));
			}
		}
		if (attributes.Roughness != null && !maps.exists("roughnessMap")) params.set("roughness", attributes.Roughness.value);
		if (attributes.Metallic != null && !maps.exists("metalnessMap")) params.set("metalness", attributes.Metallic.value);
	}

	private function parsePhongAttributes(params:haxe.ds.StringMap<Dynamic>, attributes:Dynamic, maps:haxe.ds.StringMap<Dynamic>):Void {
		if (attributes["Refraction Index"] != null) params.set("refractionRatio", 0.98 / attributes["Refraction Index"].value);
		if (attributes.Diffuse != null) params.get("color").multiplyScalar(attributes.Diffuse.value);
		if (attributes.Reflection != null) {
			params.set("reflectivity", attributes.Reflection.value);
			params.set("combine", AddOperation);
		}
		if (attributes.Luminosity != null) {
			params.set("emissiveIntensity", attributes.Luminosity.value);
			if (!maps.exists("emissiveMap") && !maps.exists("map")) {
				params.set("emissive", params.get("color"));
			} else {
				params.set("emissive", new Color(0x808080));
			}
		}
		if (attributes.Roughness == null && attributes.Specular != null && !maps.exists("specularMap")) {
			if (attributes["Color Highlight"] != null) {
				params.set("specular", new Color().setScalar(attributes.Specular.value).lerp(params.get("color").clone().multiplyScalar(attributes.Specular.value), attributes["Color Highlight"].value));
			} else {
				params.set("specular", new Color().setScalar(attributes.Specular.value));
			}
		}
		if (params.exists("specular") && attributes.Glossiness != null) params.set("shininess", 7 + Math.pow(2, attributes.Glossiness.value * 12 + 2));
	}

	private function parseEnvMap(connections:Dynamic, maps:haxe.ds.StringMap<Dynamic>, attributes:haxe.ds.StringMap<Dynamic>):Void {
		if (connections.envMap != null) {
			var envMap = this.loadTexture(connections.envMap);
			if (attributes.exists("transparent") && attributes.get("opacity") < 0.999) {
				envMap.mapping = EquirectangularRefractionMapping;
				if (attributes.exists("reflectivity")) {
					attributes.remove("reflectivity");
					attributes.remove("combine");
				}
				if (attributes.exists("metalness")) {
					attributes.set("metalness", 1);
				}
				attributes.set("opacity", 1);
			} else envMap.mapping = EquirectangularReflectionMapping;
			maps.set("envMap", envMap);
		}
	}

	private function getTexturePathByIndex(index:Int, textures:Array<Dynamic>):String {
		var fileName = "";
		if (textures == null) return fileName;
		textures.forEach(function(texture:Dynamic) {
			if (texture.index == index) fileName = texture.fileName;
		});
		return fileName;
	}

	private function loadTexture(path:String):Dynamic {
		if (path == null) return null;
		return this.textureLoader.load(path, null, null, function() {
			console.warn("LWOLoader: non-standard resource hierarchy. Use `resourcePath` parameter to specify root content directory.");
		});
	}

	private function getWrappingType(num:Int):Int {
		switch (num) {
		case 0:
			console.warn("LWOLoader: \"Reset\" texture wrapping type is not supported in three.js");
			return ClampToEdgeWrapping;
		case 1: return RepeatWrapping;
		case 2: return MirroredRepeatWrapping;
		case 3: return ClampToEdgeWrapping;
		}
		return ClampToEdgeWrapping;
	}

	private function getMaterialType(nodeData:Dynamic):Class<Dynamic> {
		if (nodeData.Clearcoat != null && nodeData.Clearcoat.value > 0) return MeshPhysicalMaterial;
		if (nodeData.Roughness != null) return MeshStandardMaterial;
		return MeshPhongMaterial;
	}

}

class GeometryParser {

	public function parse(geoData:Dynamic, layer:Dynamic):BufferGeometry {
		var geometry = new BufferGeometry();
		geometry.setAttribute("position", new Float32BufferAttribute(geoData.points, 3));
		var indices = this.splitIndices(geoData.vertexIndices, geoData.polygonDimensions);
		geometry.setIndex(indices);
		this.parseGroups(geometry, geoData);
		geometry.computeVertexNormals();
		this.parseUVs(geometry, layer, indices);
		this.parseMorphTargets(geometry, layer, indices);
		geometry.translate(-layer.pivot[0], -layer.pivot[1], -layer.pivot[2]);
		return geometry;
	}

	private function splitIndices(indices:Array<Int>, polygonDimensions:Array<Int>):Array<Int> {
		var remappedIndices = new Array<Int>();
		var i = 0;
		polygonDimensions.forEach(function(dim:Int) {
			if (dim < 4) {
				for (k in 0...dim) remappedIndices.push(indices[i + k]);
			} else if (dim == 4) {
				remappedIndices.push(indices[i], indices[i + 1], indices[i + 2], indices[i], indices[i + 2], indices[i + 3]);
			} else if (dim > 4) {
				for (k in 1...dim - 1) {
					remappedIndices.push(indices[i], indices[i + k], indices[i + k + 1]);
				}
				console.warn("LWOLoader: polygons with greater than 4 sides are not supported");
			}
			i += dim;
		});
		return remappedIndices;
	}

	private function parseGroups(geometry:BufferGeometry, geoData:Dynamic):Void {
		var tags = _lwoTree.tags;
		var matNames = new Array<String>();
		var elemSize = 3;
		if (geoData.type == "lines") elemSize = 2;
		if (geoData.type == "points") elemSize = 1;
		var remappedIndices = this.splitMaterialIndices(geoData.polygonDimensions, geoData.materialIndices);
		var indexNum = 0;
		var indexPairs = new haxe.ds.StringMap<Int>();
		var prevMaterialIndex:Null<Int> = null;
		var materialIndex:Int;
		var prevStart = 0;
		var currentCount = 0;
		for (i in 0...remappedIndices.length) {
			if (i % 2 == 0) {
				materialIndex = remappedIndices[i + 1];
				if (i == 0) matNames[indexNum] = tags[materialIndex];
				if (prevMaterialIndex == null) prevMaterialIndex = materialIndex;
				if (materialIndex != prevMaterialIndex) {
					var currentIndex:Int;
					if (indexPairs.exists(tags[prevMaterialIndex])) {
						currentIndex = indexPairs.get(tags[prevMaterialIndex]);
					} else {
						currentIndex = indexNum;
						indexPairs.set(tags[prevMaterialIndex], indexNum);
						matNames[indexNum] = tags[prevMaterialIndex];
						indexNum++;
					}
					geometry.addGroup(prevStart, currentCount, currentIndex);
					prevStart += currentCount;
					prevMaterialIndex = materialIndex;
					currentCount = 0;
				}
				currentCount += elemSize;
			}
		}
		if (geometry.groups.length > 0) {
			var currentIndex:Int;
			if (indexPairs.exists(tags[materialIndex])) {
				currentIndex = indexPairs.get(tags[materialIndex]);
			} else {
				currentIndex = indexNum;
				indexPairs.set(tags[materialIndex], indexNum);
				matNames[indexNum] = tags[materialIndex];
			}
			geometry.addGroup(prevStart, currentCount, currentIndex);
		}
		geometry.userData.matNames = matNames;
	}

	private function splitMaterialIndices(polygonDimensions:Array<Int>, indices:Array<Int>):Array<Int> {
		var remappedIndices = new Array<Int>();
		polygonDimensions.forEach(function(dim:Int, i:Int) {
			if (dim <= 3) {
				remappedIndices.push(indices[i * 2], indices[i * 2 + 1]);
			} else if (dim == 4) {
				remappedIndices.push(indices[i * 2], indices[i * 2 + 1], indices[i * 2], indices[i * 2 + 1]);
			} else {
				for (k in 0...dim - 2) {
					remappedIndices.push(indices[i * 2], indices[i * 2 + 1]);
				}
			}
		});
		return remappedIndices;
	}

	private function parseUVs(geometry:BufferGeometry, layer:Dynamic, indices:Array<Int>):Void {
		var remappedUVs = Array.from(Array.fill(geometry.attributes.position.count * 2, 0));
		for (name in layer.uvs) {
			var uvs = layer.uvs[name].uvs;
			var uvIndices = layer.uvs[name].uvIndices;
			uvIndices.forEach(function(i:Int, j:Int) {
				remappedUVs[i * 2] = uvs[j * 2];
				remappedUVs[i * 2 + 1] = uvs[j * 2 + 1];
			});
		}
		geometry.setAttribute("uv", new Float32BufferAttribute(remappedUVs, 2));
	}

	private function parseMorphTargets(geometry:BufferGeometry, layer:Dynamic, indices:Array<Int>):Void {
		var num = 0;
		for (name in layer.morphTargets) {
			var remappedPoints = geometry.attributes.position.array.slice();
			if (geometry.morphAttributes.position == null) geometry.morphAttributes.position = new Array<Float32BufferAttribute>();
			var morphPoints = layer.morphTargets[name].points;
			var morphIndices = layer.morphTargets[name].indices;
			var type = layer.morphTargets[name].type;
			morphIndices.forEach(function(i:Int, j:Int) {
				if (type == "relative") {
					remappedPoints[i * 3] += morphPoints[j * 3];
					remappedPoints[i * 3 + 1] += morphPoints[j * 3 + 1];
					remappedPoints[i * 3 + 2] += morphPoints[j * 3 + 2];
				} else {
					remappedPoints[i * 3] = morphPoints[j * 3];
					remappedPoints[i * 3 + 1] = morphPoints[j * 3 + 1];
					remappedPoints[i * 3 + 2] = morphPoints[j * 3 + 2];
				}
			});
			geometry.morphAttributes.position[num] = new Float32BufferAttribute(remappedPoints, 3);
			geometry.morphAttributes.position[num].name = name;
			num++;
		}
		geometry.morphTargetsRelative = false;
	}

}

private var _lwoTree:Dynamic;

private function extractParentUrl(url:String, dir:String):String {
	var index = url.indexOf(dir);
	if (index == -1) return "./";
	return url.slice(0, index);
}