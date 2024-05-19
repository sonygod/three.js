class FBXTreeParser {

	private var textureLoader:TextureLoader;
	private var manager:Manager;

	public function new(textureLoader:TextureLoader, manager:Manager) {
		this.textureLoader = textureLoader;
		this.manager = manager;
	}

	public function parse():Geometry {
		var connections = this.parseConnections();
		var images = this.parseImages();
		var textures = this.parseTextures(images);
		var materials = this.parseMaterials(textures);
		var deformers = this.parseDeformers();
		var geometryMap = new GeometryParser().parse(deformers);
		this.parseScene(deformers, geometryMap, materials);
		return sceneGraph;
	}

	private function parseConnections():Map<Int,Map<String,Array<Int>>> {
		var connectionMap = new Map<Int,Map<String,Array<Int>>>();
		if ('Connections' in fbxTree) {
			var rawConnections = fbxTree.Connections.connections;
			for (rawConnection in rawConnections) {
				var fromID = rawConnection[0];
				var toID = rawConnection[1];
				var relationship = rawConnection[2];
				if (!connectionMap.containsKey(fromID)) {
					connectionMap.set(fromID, {
						parents: [],
						children: []
					});
				}
				var parentRelationship = {ID: toID, relationship: relationship};
				connectionMap.get(fromID).parents.push(parentRelationship);
				if (!connectionMap.containsKey(toID)) {
					connectionMap.set(toID, {
						parents: [],
						children: []
					});
				}
				var childRelationship = {ID: fromID, relationship: relationship};
				connectionMap.get(toID).children.push(childRelationship);
			}
		}
		return connectionMap;
	}

	private function parseImages():Map<Int,String> {
		var images = new Map<Int,String>();
		var blobs = new Map<String,Dynamic>();
		if ('Video' in fbxTree.Objects) {
			var videoNodes = fbxTree.Objects.Video;
			for (nodeID in videoNodes) {
				var videoNode = videoNodes[nodeID];
				var id = Std.parseInt(nodeID);
				images.set(id, videoNode.RelativeFilename || videoNode.Filename);
				if ('Content' in videoNode) {
					var arrayBufferContent = (videoNode.Content instanceof ArrayBuffer) && (videoNode.Content.byteLength > 0);
					var base64Content = (typeof videoNode.Content == 'string') && (videoNode.Content != '');
					if (arrayBufferContent || base64Content) {
						var image = this.parseImage(videoNodes[nodeID]);
						blobs.set(videoNode.RelativeFilename || videoNode.Filename, image);
					}
				}
			}
			for (id in images) {
				var filename = images[id];
				if (blobs.containsKey(filename)) images[id] = blobs[filename];
				else images[id] = images[id].split('\\').pop();
			}
		}
		return images;
	}

	private function parseImage(videoNode:Dynamic):String {
		var content = videoNode.Content;
		var fileName = videoNode.RelativeFilename || videoNode.Filename;
		var extension = fileName.slice(fileName.lastIndexOf('.') + 1).toLowerCase();
		var type:String;
		switch (extension) {
			case 'bmp':
				type = 'image/bmp';
				break;
			case 'jpg':
			case 'jpeg':
				type = 'image/jpeg';
				break;
			case 'png':
				type = 'image/png';
				break;
			case 'tif':
				type = 'image/tiff';
				break;
			case 'tga':
				if (this.manager.getHandler('.tga') == null) {
					trace('FBXLoader: TGA loader not found, skipping ' + fileName);
				}
				type = 'image/tga';
				break;
			default:
				trace('FBXLoader: Image type "' + extension + '" is not supported.');
				return;
		}
		if (typeof content == 'string') { // ASCII format
			return 'data:' + type + ';base64,' + content;
		} else { // Binary Format
			var array = new Uint8Array(content);
			return window.URL.createObjectURL(new Blob([array], {type: type}));
		}
	}

	private function parseTextures(images:Map<Int,String>):Map<Int,Texture> {
		var textureMap = new Map<Int,Texture>();
		if ('Texture' in fbxTree.Objects) {
			var textureNodes = fbxTree.Objects.Texture;
			for (nodeID in textureNodes) {
				var texture = this.parseTexture(textureNodes[nodeID], images);
				textureMap.set(Std.parseInt(nodeID), texture);
			}
		}
		return textureMap;
	}

	private function parseTexture(textureNode:Dynamic, images:Map<Int,String>):Texture {
		var texture = this.loadTexture(textureNode, images);
		texture.ID = textureNode.id;
		texture.name = textureNode.attrName;
		var wrapModeU = textureNode.WrapModeU;
		var wrapModeV = textureNode.WrapModeV;
		var valueU = (wrapModeU != undefined) ? wrapModeU.value : 0;
		var valueV = (wrapModeV != undefined) ? wrapModeV.value : 0;
		texture.wrapS = (valueU == 0) ? RepeatWrapping : ClampToEdgeWrapping;
		texture.wrapT = (valueV == 0) ? RepeatWrapping : ClampToEdgeWrapping;
		if ('Scaling' in textureNode) {
			var values = textureNode.Scaling.value;
			texture.repeat.x = values[0];
			texture.repeat.y = values[1];
		}
		if ('Translation' in textureNode) {
			var values = textureNode.Translation.value;
			texture.offset.x = values[0];
			texture.offset.y = values[1];
		}
		return texture;
	}

	private function loadTexture(textureNode:Dynamic, images:Map<Int,String>):Texture {
		var fileName;
		var currentPath = this.textureLoader.path;
		var children = connections.get(textureNode.id).children;
		if (children != undefined && children.length > 0 && images.containsKey(children[0].ID)) {
			fileName = images.get(children[0].ID);
			if (fileName.indexOf('blob:') == 0 || fileName.indexOf('data:') == 0) {
				this.textureLoader.setPath(undefined);
			}
		}
		var texture:Texture;
		var extension = textureNode.FileName.slice(-3).toLowerCase();
		if (extension == 'tga') {
			var loader = this.manager.getHandler('.tga');
			if (loader == null) {
				trace('FBXLoader: TGA loader not found, creating placeholder texture for ' + textureNode.RelativeFilename);
				texture = new Texture();
			} else {
				loader.setPath(this.textureLoader.path);
				texture = loader.load(fileName);
			}
		} else if (extension == 'dds') {
			var loader = this.manager.getHandler('.dds');
			if (loader == null) {
				trace('FBXLoader: DDS loader not found, creating placeholder texture for ' + textureNode.RelativeFilename);
				texture = new Texture();
			} else {
				loader.setPath(this.textureLoader.path);
				texture = loader.load(fileName);
			}
		} else if (extension == 'psd') {
			trace('FBXLoader: PSD textures are not supported, creating placeholder texture for ' + textureNode.RelativeFilename);
			texture = new Texture();
		} else {
			texture = this.textureLoader.load(fileName);
		}
		this.textureLoader.setPath(currentPath);
		return texture;
	}

	private function parseMaterials(textureMap:Map<Int,Texture>):Map<Int,Material> {
		var materialMap = new Map<Int,Material>();
		if ('Material' in fbxTree.Objects) {
			var materialNodes = fbxTree.Objects.Material;
			for (nodeID in materialNodes) {
				var material = this.parseMaterial(materialNodes[nodeID], textureMap);
				if (material != null) materialMap.set(Std.parseInt(nodeID), material);
			}
		}
		return materialMap;
	}

	private function parseMaterial(materialNode:Dynamic, textureMap:Map<Int,Texture>):Material {
		var ID = materialNode.id;
		var name = materialNode.attrName;
		var type = materialNode.ShadingModel;
		if (typeof type == 'object') {
			type = type.value;
		}
		if (!connections.containsKey(ID)) return null;
		var parameters = this.parseParameters(materialNode, textureMap, ID);
		var material:Material;
		switch (type.toLowerCase()) {
			case 'phong':
				material = new MeshPhongMaterial();
				break;
			case 'lambert':
				material = new MeshLambertMaterial();
				break;
			default:
				trace('THREE.FBXLoader: unknown material type "' + type + '". Defaulting to MeshPhongMaterial.');
				material = new MeshPhongMaterial();
				break;
		}
		material.setValues(parameters);
		material.name = name;
		return material;
	}

	private function parseParameters(materialNode:Dynamic, textureMap:Map<Int,Texture>, ID:Int):Dynamic {
		var parameters = {};
		if (materialNode.BumpFactor) {
			parameters.bumpScale = materialNode.BumpFactor.value;
		}
		if (materialNode.Diffuse) {
			parameters.color = new Color().fromArray(materialNode.Diffuse.value).convertSRGBToLinear();
		} else if (materialNode.DiffuseColor && (materialNode.DiffuseColor.type == 'Color' || materialNode.DiffuseColor.type == 'ColorRGB')) {
			// The blender exporter exports diffuse here instead of in materialNode.Diffuse
			parameters.color = new Color().fromArray(materialNode.DiffuseColor.value).convertSRGBToLinear();
		}
		if (materialNode.DisplacementFactor) {
			parameters.displacementScale = materialNode.DisplacementFactor.value;
		}
		if (materialNode.Emissive) {
			parameters.emissive = new Color().fromArray(materialNode.Emissive.value).convertSRGBToLinear();
		} else if (materialNode.EmissiveColor && (materialNode.EmissiveColor.type == 'Color' || materialNode.EmissiveColor.type == 'ColorRGB')) {
			// The blender exporter exports emissive color here instead of in materialNode.Emissive
			parameters.emissive = new Color().fromArray(materialNode.EmissiveColor.value).convertSRGBToLinear();
		}
		if (materialNode.EmissiveFactor) {
			parameters.emissiveIntensity = parseFloat(materialNode.EmissiveFactor.value);
		}
		if (materialNode.Opacity) {
			parameters.opacity = parseFloat(materialNode.Opacity.value);
		}
		if (parameters.opacity < 1.0) {
			parameters.transparent = true;
		}
		if (materialNode.ReflectionFactor) {
			parameters.reflectivity = materialNode.ReflectionFactor.value;
		}
		if (materialNode.Shininess) {
			parameters.shininess = materialNode.Shininess.value;
		}
		if (materialNode.Specular) {
			parameters.specular = new Color().fromArray(materialNode.Specular.value).convertSRGBToLinear();
		} else if (materialNode.SpecularColor && materialNode.SpecularColor.type == 'Color') {
			// The blender exporter exports specular color here instead of in materialNode.Specular
			parameters.specular = new Color().fromArray(materialNode.SpecularColor.value).convertSRGBToLinear();
		}
		var scope = this;
		connections.get(ID).children.forEach(function(child) {
			var type = child.relationship;
			switch (type) {
				case 'Bump':
					parameters.bumpMap = scope.getTexture(textureMap, child.ID);
					break;
				case 'Maya|TEX_ao_map':
					parameters.aoMap = scope.getTexture(textureMap, child.ID);
					break;
				case 'DiffuseColor':
				case 'Maya|TEX_color_map':
					parameters.map = scope.getTexture(textureMap, child.ID);
					if (parameters.map != undefined) {
						parameters.map.colorSpace = SRGBColorSpace;
					}
					break;
				case 'DisplacementColor':
					parameters.displacementMap = scope.getTexture(textureMap, child.ID);
					break;
				case 'EmissiveColor':
					parameters.emissiveMap = scope.getTexture(textureMap, child.ID);
					if (parameters.emissiveMap != undefined) {
						parameters.emissiveMap.colorSpace = SRGBColorSpace;
					}
					break;
				case 'NormalMap':
				case 'Maya|TEX_normal_map':
					parameters.normalMap = scope.getTexture(textureMap, child.ID);
					break;
				case 'ReflectionColor':
					parameters.envMap = scope.getTexture(textureMap, child.ID);
					if (parameters.envMap != undefined) {
						parameters.envMap.mapping = EquirectangularReflectionMapping;
						parameters.envMap.colorSpace = SRGBColorSpace;
					}
					break;
				case 'SpecularColor':
					parameters.specularMap = scope.getTexture(textureMap, child.ID);
					if (parameters.specularMap != undefined) {
						parameters.specularMap.colorSpace = SRGBColorSpace;
					}
					break;
				case 'TransparentColor':
				case 'TransparencyFactor':
					parameters.alphaMap = scope.getTexture(textureMap, child.ID);
					parameters.transparent = true;
					break;
				case 'AmbientColor':
				case 'ShininessExponent': // AKA glossiness map
				case 'SpecularFactor': // AKA specularLevel
				case 'VectorDisplacementColor': // NOTE: Seems to be a copy of DisplacementColor
				default:
					trace('THREE.FBXLoader: ' + type + ' map is not supported in three.js, skipping texture.');
					break;
			}
		});
		return parameters;
	}

	private function getTexture(textureMap:Map<Int,Texture>, id:Int):Texture {
		// if the texture is a layered texture, just use the first layer and issue a warning
		if ('LayeredTexture' in fbxTree.Objects && id in fbxTree.Objects.LayeredTexture) {
			trace('THREE.FBXLoader: layered textures are not supported in three.js. Discarding all but first layer.');
			id = connections.get(id).children[0].ID;
		}
		return textureMap.get(id);
	}

	private function parseDeformers():Map<String,Dynamic> {
		var deformers = new Map<String,Dynamic>();
		if ('Deformer' in fbxTree.Objects) {
			var deformerNodes = fbxTree.Objects.Deformer;
			for (nodeID in deformerNodes) {
				var deformer = this.parseDeformer(deformerNodes[nodeID]);
				deformers.set(nodeID, deformer);
			}
		}
		return deformers;
	}

	private function parseDeformer(deformerNode:Dynamic):Dynamic {
		// TODO: Implement the parseDeformer function
		return null;
	}

	// ... other parse functions

}