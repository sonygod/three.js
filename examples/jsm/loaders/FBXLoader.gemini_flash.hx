import three.core.AmbientLight;
import three.core.AnimationClip;
import three.core.Bone;
import three.core.BufferGeometry;
import three.core.ClampToEdgeWrapping;
import three.core.Color;
import three.core.DirectionalLight;
import three.core.EquirectangularReflectionMapping;
import three.core.Euler;
import three.core.FileLoader;
import three.core.Float32BufferAttribute;
import three.core.Group;
import three.core.Line;
import three.core.LineBasicMaterial;
import three.core.Loader;
import three.core.LoaderUtils;
import three.core.MathUtils;
import three.core.Matrix3;
import three.core.Matrix4;
import three.core.Mesh;
import three.core.MeshLambertMaterial;
import three.core.MeshPhongMaterial;
import three.core.NumberKeyframeTrack;
import three.core.Object3D;
import three.core.OrthographicCamera;
import three.core.PerspectiveCamera;
import three.core.PointLight;
import three.core.PropertyBinding;
import three.core.Quaternion;
import three.core.QuaternionKeyframeTrack;
import three.core.RepeatWrapping;
import three.core.Skeleton;
import three.core.SkinnedMesh;
import three.core.SpotLight;
import three.core.Texture;
import three.core.TextureLoader;
import three.core.Uint16BufferAttribute;
import three.core.Vector2;
import three.core.Vector3;
import three.core.Vector4;
import three.core.VectorKeyframeTrack;
import three.math.ShapeUtils;
import three.renderers.SRGBColorSpace;
import three.curves.NURBSCurve;
import fflate.FFlate;
import haxe.io.Bytes;

class FBXLoader extends Loader {
	public function new(manager:Loader = null) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
		final path = (this.path == "") ? LoaderUtils.extractUrlBase(url) : this.path;
		final loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, (buffer) -> {
			try {
				onLoad(this.parse(buffer, path));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				this.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(FBXBuffer:Bytes, path:String):Dynamic {
		var fbxTree:FBXTree;
		var connections:Map<Int, FBXConnection>;
		var sceneGraph:Group;
		if (isFbxFormatBinary(FBXBuffer)) {
			fbxTree = new BinaryParser().parse(FBXBuffer);
		} else {
			final FBXText = convertArrayBufferToString(FBXBuffer);
			if (!isFbxFormatASCII(FBXText)) {
				throw new Error('THREE.FBXLoader: Unknown format.');
			}
			if (getFbxVersion(FBXText) < 7000) {
				throw new Error('THREE.FBXLoader: FBX version not supported, FileVersion: ' + getFbxVersion(FBXText));
			}
			fbxTree = new TextParser().parse(FBXText);
		}
		final textureLoader = new TextureLoader(this.manager).setPath(this.resourcePath != null ? this.resourcePath : path).setCrossOrigin(this.crossOrigin);
		return new FBXTreeParser(textureLoader, this.manager).parse(fbxTree);
	}
}

class FBXTreeParser {
	var textureLoader:TextureLoader;
	var manager:Loader;

	public function new(textureLoader:TextureLoader, manager:Loader) {
		this.textureLoader = textureLoader;
		this.manager = manager;
	}

	public function parse(fbxTree:FBXTree):Dynamic {
		connections = this.parseConnections();
		final images = this.parseImages();
		final textures = this.parseTextures(images);
		final materials = this.parseMaterials(textures);
		final deformers = this.parseDeformers();
		final geometryMap = new GeometryParser().parse(deformers);
		this.parseScene(deformers, geometryMap, materials);
		return sceneGraph;
	}

	public function parseConnections():Map<Int, FBXConnection> {
		final connectionMap = new Map<Int, FBXConnection>();
		if ('Connections' in fbxTree) {
			final rawConnections = fbxTree.Connections.connections;
			rawConnections.forEach((rawConnection) -> {
				final fromID = rawConnection[0];
				final toID = rawConnection[1];
				final relationship = rawConnection[2];
				if (!connectionMap.exists(fromID)) {
					connectionMap.set(fromID, {
						parents: [],
						children: []
					});
				}
				final parentRelationship = {ID: toID, relationship: relationship};
				connectionMap.get(fromID).parents.push(parentRelationship);
				if (!connectionMap.exists(toID)) {
					connectionMap.set(toID, {
						parents: [],
						children: []
					});
				}
				final childRelationship = {ID: fromID, relationship: relationship};
				connectionMap.get(toID).children.push(childRelationship);
			});
		}
		return connectionMap;
	}

	public function parseImages():Map<Int, String> {
		final images = new Map<Int, String>();
		final blobs = new Map<String, String>();
		if ('Video' in fbxTree.Objects) {
			final videoNodes = fbxTree.Objects.Video;
			for (nodeID in videoNodes) {
				final videoNode = videoNodes[nodeID];
				final id = Std.parseInt(nodeID);
				images.set(id, videoNode.RelativeFilename != null ? videoNode.RelativeFilename : videoNode.Filename);
				if ('Content' in videoNode) {
					final arrayBufferContent = (videoNode.Content is Bytes) && (videoNode.Content.length > 0);
					final base64Content = (Std.isOfType(videoNode.Content, String)) && (videoNode.Content != "");
					if (arrayBufferContent || base64Content) {
						final image = this.parseImage(videoNodes[nodeID]);
						blobs.set(videoNode.RelativeFilename != null ? videoNode.RelativeFilename : videoNode.Filename, image);
					}
				}
			}
		}
		for (id in images) {
			final filename = images.get(id);
			if (blobs.exists(filename)) images.set(id, blobs.get(filename));
			else images.set(id, filename.split("\\").pop());
		}
		return images;
	}

	public function parseImage(videoNode:Dynamic):String {
		final content = videoNode.Content;
		final fileName = videoNode.RelativeFilename != null ? videoNode.RelativeFilename : videoNode.Filename;
		final extension = fileName.substring(fileName.lastIndexOf(".") + 1).toLowerCase();
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
					console.warn('FBXLoader: TGA loader not found, skipping ', fileName);
				}
				type = 'image/tga';
				break;
			default:
				console.warn('FBXLoader: Image type "' + extension + '" is not supported.');
				return null;
		}
		if (Std.isOfType(content, String)) {
			return 'data:' + type + ';base64,' + content;
		} else {
			final array = new Uint8Array(content);
			return js.html.URL.createObjectURL(new js.html.Blob([array], {type: type}));
		}
	}

	public function parseTextures(images:Map<Int, String>):Map<Int, Texture> {
		final textureMap = new Map<Int, Texture>();
		if ('Texture' in fbxTree.Objects) {
			final textureNodes = fbxTree.Objects.Texture;
			for (nodeID in textureNodes) {
				final texture = this.parseTexture(textureNodes[nodeID], images);
				textureMap.set(Std.parseInt(nodeID), texture);
			}
		}
		return textureMap;
	}

	public function parseTexture(textureNode:Dynamic, images:Map<Int, String>):Texture {
		final texture = this.loadTexture(textureNode, images);
		texture.ID = textureNode.id;
		texture.name = textureNode.attrName;
		final wrapModeU = textureNode.WrapModeU;
		final wrapModeV = textureNode.WrapModeV;
		final valueU = wrapModeU != null ? wrapModeU.value : 0;
		final valueV = wrapModeV != null ? wrapModeV.value : 0;
		texture.wrapS = valueU == 0 ? RepeatWrapping : ClampToEdgeWrapping;
		texture.wrapT = valueV == 0 ? RepeatWrapping : ClampToEdgeWrapping;
		if ('Scaling' in textureNode) {
			final values = textureNode.Scaling.value;
			texture.repeat.x = values[0];
			texture.repeat.y = values[1];
		}
		if ('Translation' in textureNode) {
			final values = textureNode.Translation.value;
			texture.offset.x = values[0];
			texture.offset.y = values[1];
		}
		return texture;
	}

	public function loadTexture(textureNode:Dynamic, images:Map<Int, String>):Texture {
		var fileName:String;
		final currentPath = this.textureLoader.path;
		final children = connections.get(textureNode.id).children;
		if (children != null && children.length > 0 && images.exists(children[0].ID)) {
			fileName = images.get(children[0].ID);
			if (fileName.indexOf('blob:') == 0 || fileName.indexOf('data:') == 0) {
				this.textureLoader.setPath(null);
			}
		}
		var texture:Texture;
		final extension = textureNode.FileName.substring(textureNode.FileName.length - 3).toLowerCase();
		if (extension == 'tga') {
			final loader = this.manager.getHandler('.tga');
			if (loader == null) {
				console.warn('FBXLoader: TGA loader not found, creating placeholder texture for', textureNode.RelativeFilename);
				texture = new Texture();
			} else {
				loader.setPath(this.textureLoader.path);
				texture = loader.load(fileName);
			}
		} else if (extension == 'dds') {
			final loader = this.manager.getHandler('.dds');
			if (loader == null) {
				console.warn('FBXLoader: DDS loader not found, creating placeholder texture for', textureNode.RelativeFilename);
				texture = new Texture();
			} else {
				loader.setPath(this.textureLoader.path);
				texture = loader.load(fileName);
			}
		} else if (extension == 'psd') {
			console.warn('FBXLoader: PSD textures are not supported, creating placeholder texture for', textureNode.RelativeFilename);
			texture = new Texture();
		} else {
			texture = this.textureLoader.load(fileName);
		}
		this.textureLoader.setPath(currentPath);
		return texture;
	}

	public function parseMaterials(textureMap:Map<Int, Texture>):Map<Int, Dynamic> {
		final materialMap = new Map<Int, Dynamic>();
		if ('Material' in fbxTree.Objects) {
			final materialNodes = fbxTree.Objects.Material;
			for (nodeID in materialNodes) {
				final material = this.parseMaterial(materialNodes[nodeID], textureMap);
				if (material != null) materialMap.set(Std.parseInt(nodeID), material);
			}
		}
		return materialMap;
	}

	public function parseMaterial(materialNode:Dynamic, textureMap:Map<Int, Texture>):Dynamic {
		final ID = materialNode.id;
		final name = materialNode.attrName;
		var type = materialNode.ShadingModel;
		if (Std.isOfType(type, Dynamic)) {
			type = type.value;
		}
		if (!connections.exists(ID)) return null;
		final parameters = this.parseParameters(materialNode, textureMap, ID);
		var material:Dynamic;
		switch (type.toLowerCase()) {
			case 'phong':
				material = new MeshPhongMaterial();
				break;
			case 'lambert':
				material = new MeshLambertMaterial();
				break;
			default:
				console.warn('THREE.FBXLoader: unknown material type "%s". Defaulting to MeshPhongMaterial.', type);
				material = new MeshPhongMaterial();
				break;
		}
		material.setValues(parameters);
		material.name = name;
		return material;
	}

	public function parseParameters(materialNode:Dynamic, textureMap:Map<Int, Texture>, ID:Int):Dynamic {
		final parameters = {
			color: null,
			emissive: null,
			specular: null,
			bumpScale: null,
			displacementScale: null,
			emissiveIntensity: null,
			opacity: null,
			reflectivity: null,
			shininess: null,
			transparent: false,
			bumpMap: null,
			aoMap: null,
			map: null,
			displacementMap: null,
			emissiveMap: null,
			normalMap: null,
			envMap: null,
			specularMap: null,
			alphaMap: null
		};
		if (materialNode.BumpFactor != null) {
			parameters.bumpScale = materialNode.BumpFactor.value;
		}
		if (materialNode.Diffuse != null) {
			parameters.color = new Color().fromArray(materialNode.Diffuse.value).convertSRGBToLinear();
		} else if (materialNode.DiffuseColor != null && (materialNode.DiffuseColor.type == 'Color' || materialNode.DiffuseColor.type == 'ColorRGB')) {
			parameters.color = new Color().fromArray(materialNode.DiffuseColor.value).convertSRGBToLinear();
		}
		if (materialNode.DisplacementFactor != null) {
			parameters.displacementScale = materialNode.DisplacementFactor.value;
		}
		if (materialNode.Emissive != null) {
			parameters.emissive = new Color().fromArray(materialNode.Emissive.value).convertSRGBToLinear();
		} else if (materialNode.EmissiveColor != null && (materialNode.EmissiveColor.type == 'Color' || materialNode.EmissiveColor.type == 'ColorRGB')) {
			parameters.emissive = new Color().fromArray(materialNode.EmissiveColor.value).convertSRGBToLinear();
		}
		if (materialNode.EmissiveFactor != null) {
			parameters.emissiveIntensity = Std.parseFloat(materialNode.EmissiveFactor.value);
		}
		if (materialNode.Opacity != null) {
			parameters.opacity = Std.parseFloat(materialNode.Opacity.value);
		}
		if (parameters.opacity < 1.0) {
			parameters.transparent = true;
		}
		if (materialNode.ReflectionFactor != null) {
			parameters.reflectivity = materialNode.ReflectionFactor.value;
		}
		if (materialNode.Shininess != null) {
			parameters.shininess = materialNode.Shininess.value;
		}
		if (materialNode.Specular != null) {
			parameters.specular = new Color().fromArray(materialNode.Specular.value).convertSRGBToLinear();
		} else if (materialNode.SpecularColor != null && materialNode.SpecularColor.type == 'Color') {
			parameters.specular = new Color().fromArray(materialNode.SpecularColor.value).convertSRGBToLinear();
		}
		connections.get(ID).children.forEach((child) -> {
			final type = child.relationship;
			switch (type) {
				case 'Bump':
					parameters.bumpMap = this.getTexture(textureMap, child.ID);
					break;
				case 'Maya|TEX_ao_map':
					parameters.aoMap = this.getTexture(textureMap, child.ID);
					break;
				case 'DiffuseColor':
				case 'Maya|TEX_color_map':
					parameters.map = this.getTexture(textureMap, child.ID);
					if (parameters.map != null) {
						parameters.map.colorSpace = SRGBColorSpace;
					}
					break;
				case 'DisplacementColor':
					parameters.displacementMap = this.getTexture(textureMap, child.ID);
					break;
				case 'EmissiveColor':
					parameters.emissiveMap = this.getTexture(textureMap, child.ID);
					if (parameters.emissiveMap != null) {
						parameters.emissiveMap.colorSpace = SRGBColorSpace;
					}
					break;
				case 'NormalMap':
				case 'Maya|TEX_normal_map':
					parameters.normalMap = this.getTexture(textureMap, child.ID);
					break;
				case 'ReflectionColor':
					parameters.envMap = this.getTexture(textureMap, child.ID);
					if (parameters.envMap != null) {
						parameters.envMap.mapping = EquirectangularReflectionMapping;
						parameters.envMap.colorSpace = SRGBColorSpace;
					}
					break;
				case 'SpecularColor':
					parameters.specularMap = this.getTexture(textureMap, child.ID);
					if (parameters.specularMap != null) {
						parameters.specularMap.colorSpace = SRGBColorSpace;
					}
					break;
				case 'TransparentColor':
				case 'TransparencyFactor':
					parameters.alphaMap = this.getTexture(textureMap, child.ID);
					parameters.transparent = true;
					break;
				case 'AmbientColor':
				case 'ShininessExponent':
				case 'SpecularFactor':
				case 'VectorDisplacementColor':
				default:
					console.warn('THREE.FBXLoader: %s map is not supported in three.js, skipping texture.', type);
					break;
			}
		});
		return parameters;
	}

	public function getTexture(textureMap:Map<Int, Texture>, id:Int):Texture {
		if ('LayeredTexture' in fbxTree.Objects && id in fbxTree.Objects.LayeredTexture) {
			console.warn('THREE.FBXLoader: layered textures are not supported in three.js. Discarding all but first layer.');
			id = connections.get(id).children[0].ID;
		}
		return textureMap.get(id);
	}

	public function parseDeformers():FBXDeformers {
		final skeletons = new Map<Int, FBXSkeleton>();
		final morphTargets = new Map<Int, FBXMorphTarget>();
		if ('Deformer' in fbxTree.Objects) {
			final DeformerNodes = fbxTree.Objects.Deformer;
			for (nodeID in DeformerNodes) {
				final deformerNode = DeformerNodes[nodeID];
				final relationships = connections.get(Std.parseInt(nodeID));
				if (deformerNode.attrType == 'Skin') {
					final skeleton = this.parseSkeleton(relationships, DeformerNodes);
					skeleton.ID = nodeID;
					if (relationships.parents.length > 1) console.warn('THREE.FBXLoader: skeleton attached to more than one geometry is not supported.');
					skeleton.geometryID = relationships.parents[0].ID;
					skeletons.set(Std.parseInt(nodeID), skeleton);
				} else if (deformerNode.attrType == 'BlendShape') {
					final morphTarget = {
						id: nodeID,
						rawTargets: null
					};
					morphTarget.rawTargets = this.parseMorphTargets(relationships, DeformerNodes);
					morphTarget.id = nodeID;
					if (relationships.parents.length > 1) console.warn('THREE.FBXLoader: morph target attached to more than one geometry is not supported.');
					morphTargets.set(Std.parseInt(nodeID), morphTarget);
				}
			}
		}
		return {
			skeletons: skeletons,
			morphTargets: morphTargets
		};
	}

	public function parseSkeleton(relationships:FBXConnection, deformerNodes:Dynamic):FBXSkeleton {
		final rawBones = [];
		relationships.children.forEach((child) -> {
			final boneNode = deformerNodes[child.ID];
			if (boneNode.attrType != 'Cluster') return;
			final rawBone = {
				ID: child.ID,
				indices: [],
				weights: [],
				transformLink: new Matrix4().fromArray(boneNode.TransformLink.a),
				transform: new Matrix4().fromArray(boneNode.Transform.a),
				linkMode: boneNode.Mode
			};
			if ('Indexes' in boneNode) {
				rawBone.indices = boneNode.Indexes.a;
				rawBone.weights = boneNode.Weights.a;
			}
			rawBones.push(rawBone);
		});
		return {
			rawBones: rawBones,
			bones: []
		};
	}

	public function parseMorphTargets(relationships:FBXConnection, deformerNodes:Dynamic):Array<FBXMorphTarget> {
		final rawMorphTargets = [];
		for (i in 0...relationships.children.length) {
			final child = relationships.children[i];
			final morphTargetNode = deformerNodes[child.ID];
			final rawMorphTarget = {
				name: morphTargetNode.attrName,
				initialWeight: morphTargetNode.DeformPercent,
				id: morphTargetNode.id,
				fullWeights: morphTargetNode.FullWeights.a,
				geoID: null
			};
			if (morphTargetNode.attrType != 'BlendShapeChannel') return [];
			rawMorphTarget.geoID = connections.get(Std.parseInt(child.ID)).children.filter((child) -> child.relationship == null)[0].ID;
			rawMorphTargets.push(rawMorphTarget);
		}
		return rawMorphTargets;
	}

	public function parseScene(deformers:FBXDeformers, geometryMap:Map<Int, BufferGeometry>, materialMap:Map<Int, Dynamic>) {
		sceneGraph = new Group();
		final modelMap = this.parseModels(deformers.skeletons, geometryMap, materialMap);
		final modelNodes = fbxTree.Objects.Model;
		modelMap.forEach((model) -> {
			final modelNode = modelNodes[model.ID];
			this.setLookAtProperties(model, modelNode);
			final parentConnections = connections.get(model.ID).parents;
			parentConnections.forEach((connection) -> {
				final parent = modelMap.get(connection.ID);
				if (parent != null) parent.add(model);
			});
			if (model.parent == null) {
				sceneGraph.add(model);
			}
		});
		this.bindSkeleton(deformers.skeletons, geometryMap, modelMap);
		this.addGlobalSceneSettings();
		sceneGraph.traverse((node) -> {
			if (node.userData.transformData != null) {
				if (node.parent != null) {
					node.userData.transformData.parentMatrix = node.parent.matrix;
					node.userData.transformData.parentMatrixWorld = node.parent.matrixWorld;
				}
				final transform = generateTransform(node.userData.transformData);
				node.applyMatrix4(transform);
				node.updateWorldMatrix();
			}
		});
		final animations = new AnimationParser().parse();
		if (sceneGraph.children.length == 1 && sceneGraph.children[0].isGroup) {
			sceneGraph.children[0].animations = animations;
			sceneGraph = sceneGraph.children[0];
		}
		sceneGraph.animations = animations;
	}

	public function parseModels(skeletons:Map<Int, FBXSkeleton>, geometryMap:Map<Int, BufferGeometry>, materialMap:Map<Int, Dynamic>):Map<Int, Dynamic> {
		final modelMap = new Map<Int, Dynamic>();
		final modelNodes = fbxTree.Objects.Model;
		for (nodeID in modelNodes) {
			final id = Std.parseInt(nodeID);
			final node = modelNodes[nodeID];
			final relationships = connections.get(id);
			var model = this.buildSkeleton(relationships, skeletons, id, node.attrName);
			if (model == null) {
				switch (node.attrType) {
					case 'Camera':
						model = this.createCamera(relationships);
						break;
					case 'Light':
						model = this.createLight(relationships);
						break;
					case 'Mesh':
						model = this.createMesh(relationships, geometryMap, materialMap);
						break;
					case 'NurbsCurve':
						model = this.createCurve(relationships, geometryMap);
						break;
					case 'LimbNode':
					case 'Root':
						model = new Bone();
						break;
					case 'Null':
					default:
						model = new Group();
						break;
				}
				model.name = node.attrName != null ? PropertyBinding.sanitizeNodeName(node.attrName) : '';
				model.userData.originalName = node.attrName;
				model.ID = id;
			}
			this.getTransformData(model, node);
			modelMap.set(id, model);
		}
		return modelMap;
	}

	public function buildSkeleton(relationships:FBXConnection, skeletons:Map<Int, FBXSkeleton>, id:Int, name:String):Dynamic {
		var bone:Dynamic = null;
		relationships.parents.forEach((parent) -> {
			for (ID in skeletons) {
				final skeleton = skeletons.get(ID);
				skeleton.rawBones.forEach((rawBone, i) -> {
					if (rawBone.ID == parent.ID) {
						final subBone = bone;
						bone = new Bone();
						bone.matrixWorld.copy(rawBone.transformLink);
						bone.name = name != null ? PropertyBinding.sanitizeNodeName(name) : '';
						bone.userData.originalName = name;
						bone.ID = id;
						skeleton.bones[i] = bone;
						if (subBone != null) {
							bone.add(subBone);
						}
					}
				});
			}
		});
		return bone;
	}

	public function createCamera(relationships:FBXConnection):Dynamic {
		var model:Dynamic;
		var cameraAttribute:Dynamic;
		relationships.children.forEach((child) -> {
			final attr = fbxTree.Objects.NodeAttribute[child.ID];
			if (attr != null) {
				cameraAttribute = attr;
			}
		});
		if (cameraAttribute == null) {
			model = new Object3D();
		} else {
			var type = 0;
			if (cameraAttribute.CameraProjectionType != null && cameraAttribute.CameraProjectionType.value == 1) {
				type = 1;
			}
			var nearClippingPlane = 1;
			if (cameraAttribute.NearPlane != null) {
				nearClippingPlane = cameraAttribute.NearPlane.value / 1000;
			}
			var farClippingPlane = 1000;
			if (cameraAttribute.FarPlane != null) {
				farClippingPlane = cameraAttribute.FarPlane.value / 1000;
			}
			var width = js.Browser.window.innerWidth;
			var height = js.Browser.window.innerHeight;
			if (cameraAttribute.AspectWidth != null && cameraAttribute.AspectHeight != null) {
				width = cameraAttribute.AspectWidth.value;
				height = cameraAttribute.AspectHeight.value;
			}
			final aspect = width / height;
			var fov = 45;
			if (cameraAttribute.FieldOfView != null) {
				fov = cameraAttribute.FieldOfView.value;
			}
			final focalLength = cameraAttribute.FocalLength != null ? cameraAttribute.FocalLength.value : null;
			switch (type) {
				case 0:
					model = new PerspectiveCamera(fov, aspect, nearClippingPlane, farClippingPlane);
					if (focalLength != null) model.setFocalLength(focalLength);
					break;
				case 1:
					model = new OrthographicCamera(-width / 2, width / 2, height / 2, -height / 2, nearClippingPlane, farClippingPlane);
					break;
				default:
					console.warn('THREE.FBXLoader: Unknown camera type ' + type + '.');
					model = new Object3D();
					break;
			}
		}
		return model;
	}

	public function createLight(relationships:FBXConnection):Dynamic {
		var model:Dynamic;
		var lightAttribute:Dynamic;
		relationships.children.forEach((child) -> {
			final attr = fbxTree.Objects.NodeAttribute[child.ID];
			if (attr != null) {
				lightAttribute = attr;
			}
		});
		if (lightAttribute == null) {
			model = new Object3D();
		} else {
			var type:Int;
			if (lightAttribute.LightType == null) {
				type = 0;
			} else {
				type = lightAttribute.LightType.value;
			}
			var color = 0xffffff;
			if (lightAttribute.Color != null) {
				color = new Color().fromArray(lightAttribute.Color.value).convertSRGBToLinear();
			}
			var intensity = (lightAttribute.Intensity == null) ? 1 : lightAttribute.Intensity.value / 100;
			if (lightAttribute.CastLightOnObject != null && lightAttribute.CastLightOnObject.value == 0) {
				intensity = 0;
			}
			var distance = 0;
			if (lightAttribute.FarAttenuationEnd != null) {
				if (lightAttribute.EnableFarAttenuation != null && lightAttribute.EnableFarAttenuation.value == 0) {
					distance = 0;
				} else {
					distance = lightAttribute.FarAttenuationEnd.value;
				}
			}
			final decay = 1;
			switch (type) {
				case 0:
					model = new PointLight(color, intensity, distance, decay);
					break;
				case 1:
					model = new DirectionalLight(color, intensity);
					break;
				case 2:
					var angle = Math.PI / 3;
					if (lightAttribute.InnerAngle != null) {
						angle = MathUtils.degToRad(lightAttribute.InnerAngle.value);
					}
					var penumbra = 0;
					if (lightAttribute.OuterAngle != null) {
						penumbra = MathUtils.degToRad(lightAttribute.OuterAngle.value);
						penumbra = Math.max(penumbra, 1);
					}
					model = new SpotLight(color, intensity, distance, angle, penumbra, decay);
					break;
				default:
					console.warn('THREE.FBXLoader: Unknown light type ' + lightAttribute.LightType.value + ', defaulting to a PointLight.');
					model = new PointLight(color, intensity);
					break;
			}
			if (lightAttribute.CastShadows != null && lightAttribute.CastShadows.value == 1) {
				model.castShadow = true;
			}
		}
		return model;
	}

	public function createMesh(relationships:FBXConnection, geometryMap:Map<Int, BufferGeometry>, materialMap:Map<Int, Dynamic>):Dynamic {
		var model:Dynamic;
		var geometry:BufferGeometry = null;
		var material:Dynamic = null;
		final materials = [];
		relationships.children.forEach((child) -> {
			if (geometryMap.exists(child.ID)) {
				geometry = geometryMap.get(child.ID);
			}
			if (materialMap.exists(child.ID)) {
				materials.push(materialMap.get(child.ID));
			}
		});
		if (materials.length > 1) {
			material = materials;
		} else if (materials.length > 0) {
			material = materials[0];
		} else {
			material = new MeshPhongMaterial({
				name: Loader.DEFAULT_MATERIAL_NAME,
				color: 0xcccccc
			});
			materials.push(material);
		}
		if ('color' in geometry.attributes) {
			materials.forEach((material) -> material.vertexColors = true);
		}
		if (geometry.FBX_Deformer != null) {
			model = new SkinnedMesh(geometry, material);
			model.normalizeSkinWeights();
		} else {
			model = new Mesh(geometry, material);
		}
		return model;
	}

	public function createCurve(relationships:FBXConnection, geometryMap:Map<Int, BufferGeometry>):Dynamic {
		final geometry = relationships.children.reduce((geo, child) -> {
			if (geometryMap.exists(child.ID)) geo = geometryMap.get(child.ID);
			return geo;
		}, null);
		final material = new LineBasicMaterial({
			name: Loader.DEFAULT_MATERIAL_NAME,
			color: 0x3300ff,
			linewidth: 1
		});
		return new Line(geometry, material);
	}

	public function getTransform
	public function getTransformData(model:Dynamic, modelNode:Dynamic) {
		final transformData = {
			inheritType: null,
			eulerOrder: null,
			translation: null,
			preRotation: null,
			rotation: null,
			postRotation: null,
			scale: null,
			scalingOffset: null,
			scalingPivot: null,
			rotationOffset: null,
			rotationPivot: null,
			parentMatrix: null,
			parentMatrixWorld: null
		};
		if ('InheritType' in modelNode) transformData.inheritType = Std.parseInt(modelNode.InheritType.value);
		if ('RotationOrder' in modelNode) transformData.eulerOrder = getEulerOrder(modelNode.RotationOrder.value);
		else transformData.eulerOrder = 'ZYX';
		if ('Lcl_Translation' in modelNode) transformData.translation = modelNode.Lcl_Translation.value;
		if ('PreRotation' in modelNode) transformData.preRotation = modelNode.PreRotation.value;
		if ('Lcl_Rotation' in modelNode) transformData.rotation = modelNode.Lcl_Rotation.value;
		if ('PostRotation' in modelNode) transformData.postRotation = modelNode.PostRotation.value;
		if ('Lcl_Scaling' in modelNode) transformData.scale = modelNode.Lcl_Scaling.value;
		if ('ScalingOffset' in modelNode) transformData.scalingOffset = modelNode.ScalingOffset.value;
		if ('ScalingPivot' in modelNode) transformData.scalingPivot = modelNode.ScalingPivot.value;
		if ('RotationOffset' in modelNode) transformData.rotationOffset = modelNode.RotationOffset.value;
		if ('RotationPivot' in modelNode) transformData.rotationPivot = modelNode.RotationPivot.value;
		model.userData.transformData = transformData;
	}

	public function setLookAtProperties(model:Dynamic, modelNode:Dynamic) {
		if ('LookAtProperty' in modelNode) {
			final children = connections.get(model.ID).children;
			children.forEach((child) -> {
				if (child.relationship == 'LookAtProperty') {
					final lookAtTarget = fbxTree.Objects.Model[child.ID];
					if ('Lcl_Translation' in lookAtTarget) {
						final pos = lookAtTarget.Lcl_Translation.value;
						if (model.target != null) {
							model.target.position.fromArray(pos);
							sceneGraph.add(model.target);
						} else {
							model.lookAt(new Vector3().fromArray(pos));
						}
					}
				}
			});
		}
	}

	public function bindSkeleton(skeletons:Map<Int, FBXSkeleton>, geometryMap:Map<Int, BufferGeometry>, modelMap:Map<Int, Dynamic>) {
		final bindMatrices = this.parsePoseNodes();
		for (ID in skeletons) {
			final skeleton = skeletons.get(ID);
			final parents = connections.get(Std.parseInt(skeleton.ID)).parents;
			parents.forEach((parent) -> {
				if (geometryMap.exists(parent.ID)) {
					final geoID = parent.ID;
					final geoRelationships = connections.get(geoID);
					geoRelationships.parents.forEach((geoConnParent) -> {
						if (modelMap.exists(geoConnParent.ID)) {
							final model = modelMap.get(geoConnParent.ID);
							model.bind(new Skeleton(skeleton.bones), bindMatrices[geoConnParent.ID]);
						}
					});
				}
			});
		}
	}

	public function parsePoseNodes():Map<Int, Matrix4> {
		final bindMatrices = new Map<Int, Matrix4>();
		if ('Pose' in fbxTree.Objects) {
			final BindPoseNode = fbxTree.Objects.Pose;
			for (nodeID in BindPoseNode) {
				if (BindPoseNode[nodeID].attrType == 'BindPose' && BindPoseNode[nodeID].NbPoseNodes > 0) {
					final poseNodes = BindPoseNode[nodeID].PoseNode;
					if (Std.isOfType(poseNodes, Array)) {
						poseNodes.forEach((poseNode) -> bindMatrices.set(poseNode.Node, new Matrix4().fromArray(poseNode.Matrix.a)));
					} else {
						bindMatrices.set(poseNodes.Node, new Matrix4().fromArray(poseNodes.Matrix.a));
					}
				}
			}
		}
		return bindMatrices;
	}

	public function addGlobalSceneSettings() {
		if ('GlobalSettings' in fbxTree) {
			if ('AmbientColor' in fbxTree.GlobalSettings) {
				final ambientColor = fbxTree.GlobalSettings.AmbientColor.value;
				final r = ambientColor[0];
				final g = ambientColor[1];
				final b = ambientColor[2];
				if (r != 0 || g != 0 || b != 0) {
					final color = new Color(r, g, b).convertSRGBToLinear();
					sceneGraph.add(new AmbientLight(color, 1));
				}
			}
			if ('UnitScaleFactor' in fbxTree.GlobalSettings) {
				sceneGraph.userData.unitScaleFactor = fbxTree.GlobalSettings.UnitScaleFactor.value;
			}
		}
	}
}

// parse Geometry data from FBXTree and return map of BufferGeometries
class GeometryParser {
	public var negativeMaterialIndices:Bool = false;

	public function new() {
	}

	// Parse nodes in FBXTree.Objects.Geometry
	public function parse(deformers:FBXDeformers):Map<Int, BufferGeometry> {
		final geometryMap = new Map<Int, BufferGeometry>();
		if ('Geometry' in fbxTree.Objects) {
			final geoNodes = fbxTree.Objects.Geometry;
			for (nodeID in geoNodes) {
				final relationships = connections.get(Std.parseInt(nodeID));
				final geo = this.parseGeometry(relationships, geoNodes[nodeID], deformers);
				geometryMap.set(Std.parseInt(nodeID), geo);
			}
		}
		if (this.negativeMaterialIndices) {
			console.warn('THREE.FBXLoader: The FBX file contains invalid (negative) material indices. The asset might not render as expected.');
		}
		return geometryMap;
	}

	// Parse single node in FBXTree.Objects.Geometry
	public function parseGeometry(relationships:FBXConnection, geoNode:Dynamic, deformers:FBXDeformers):BufferGeometry {
		switch (geoNode.attrType) {
			case 'Mesh':
				return this.parseMeshGeometry(relationships, geoNode, deformers);
			case 'NurbsCurve':
				return this.parseNurbsGeometry(geoNode);
			default:
				return new BufferGeometry();
		}
	}

	// Parse single node mesh geometry in FBXTree.Objects.Geometry
	public function parseMeshGeometry(relationships:FBXConnection, geoNode:Dynamic, deformers:FBXDeformers):BufferGeometry {
		final skeletons = deformers.skeletons;
		final morphTargets = [];
		final modelNodes = relationships.parents.map((parent) -> fbxTree.Objects.Model[parent.ID]);
		if (modelNodes.length == 0) return new BufferGeometry();
		final skeleton = relationships.children.reduce((skeleton, child) -> {
			if (skeletons.exists(child.ID)) skeleton = skeletons.get(child.ID);
			return skeleton;
		}, null);
		relationships.children.forEach((child) -> {
			if (deformers.morphTargets.exists(child.ID)) {
				morphTargets.push(deformers.morphTargets.get(child.ID));
			}
		});
		final modelNode = modelNodes[0];
		final transformData = {
			eulerOrder: null,
			inheritType: null,
			translation: null,
			rotation: null,
			scale: null
		};
		if ('RotationOrder' in modelNode) transformData.eulerOrder = getEulerOrder(modelNode.RotationOrder.value);
		if ('InheritType' in modelNode) transformData.inheritType = Std.parseInt(modelNode.InheritType.value);
		if ('GeometricTranslation' in modelNode) transformData.translation = modelNode.GeometricTranslation.value;
		if ('GeometricRotation' in modelNode) transformData.rotation = modelNode.GeometricRotation.value;
		if ('GeometricScaling' in modelNode) transformData.scale = modelNode.GeometricScaling.value;
		final transform = generateTransform(transformData);
		return this.genGeometry(geoNode, skeleton, morphTargets, transform);
	}

	// Generate a BufferGeometry from a node in FBXTree.Objects.Geometry
	public function genGeometry(geoNode:Dynamic, skeleton:FBXSkeleton, morphTargets:Array<FBXMorphTarget>, preTransform:Matrix4):BufferGeometry {
		final geo = new BufferGeometry();
		if (geoNode.attrName != null) geo.name = geoNode.attrName;
		final geoInfo = this.parseGeoNode(geoNode, skeleton);
		final buffers = this.genBuffers(geoInfo);
		final positionAttribute = new Float32BufferAttribute(buffers.vertex, 3);
		positionAttribute.applyMatrix4(preTransform);
		geo.setAttribute('position', positionAttribute);
		if (buffers.colors.length > 0) {
			geo.setAttribute('color', new Float32BufferAttribute(buffers.colors, 3));
		}
		if (skeleton != null) {
			geo.setAttribute('skinIndex', new Uint16BufferAttribute(buffers.weightsIndices, 4));
			geo.setAttribute('skinWeight', new Float32BufferAttribute(buffers.vertexWeights, 4));
			geo.FBX_Deformer = skeleton;
		}
		if (buffers.normal.length > 0) {
			final normalMatrix = new Matrix3().getNormalMatrix(preTransform);
			final normalAttribute = new Float32BufferAttribute(buffers.normal, 3);
			normalAttribute.applyNormalMatrix(normalMatrix);
			geo.setAttribute('normal', normalAttribute);
		}
		buffers.uvs.forEach((uvBuffer, i) -> {
			final name = i == 0 ? 'uv' : 'uv' + i;
			geo.setAttribute(name, new Float32BufferAttribute(buffers.uvs[i], 2));
		});
		if (geoInfo.material != null && geoInfo.material.mappingType != 'AllSame') {
			var prevMaterialIndex = buffers.materialIndex[0];
			var startIndex = 0;
			buffers.materialIndex.forEach((currentIndex, i) -> {
				if (currentIndex != prevMaterialIndex) {
					geo.addGroup(startIndex, i - startIndex, prevMaterialIndex);
					prevMaterialIndex = currentIndex;
					startIndex = i;
				}
			});
			if (geo.groups.length > 0) {
				final lastGroup = geo.groups[geo.groups.length - 1];
				final lastIndex = lastGroup.start + lastGroup.count;
				if (lastIndex != buffers.materialIndex.length) {
					geo.addGroup(lastIndex, buffers.materialIndex.length - lastIndex, prevMaterialIndex);
				}
			}
			if (geo.groups.length == 0) {
				geo.addGroup(0, buffers.materialIndex.length, buffers.materialIndex[0]);
			}
		}
		this.addMorphTargets(geo, geoNode, morphTargets, preTransform);
		return geo;
	}

	public function parseGeoNode(geoNode:Dynamic, skeleton:FBXSkeleton):FBXGeoInfo {
		final geoInfo = {
			vertexPositions: [],
			vertexIndices: [],
			color: null,
			material: null,
			normal: null,
			uv: [],
			weightTable: {}
		};
		geoInfo.vertexPositions = (geoNode.Vertices != null) ? geoNode.Vertices.a : [];
		geoInfo.vertexIndices = (geoNode.PolygonVertexIndex != null) ? geoNode.PolygonVertexIndex.a : [];
		if (geoNode.LayerElementColor != null) {
			geoInfo.color = this.parseVertexColors(geoNode.LayerElementColor[0]);
		}
		if (geoNode.LayerElementMaterial != null) {
			geoInfo.material = this.parseMaterialIndices(geoNode.LayerElementMaterial[0]);
		}
		if (geoNode.LayerElementNormal != null) {
			geoInfo.normal = this.parseNormals(geoNode.LayerElementNormal[0]);
		}
		if (geoNode.LayerElementUV != null) {
			var i = 0;
			while (geoNode.LayerElementUV[i] != null) {
				if (geoNode.LayerElementUV[i].UV != null) {
					geoInfo.uv.push(this.parseUVs(geoNode.LayerElementUV[i]));
				}
				i++;
			}
		}
		if (skeleton != null) {
			geoInfo.skeleton = skeleton;
			skeleton.rawBones.forEach((rawBone, i) -> {
				rawBone.indices.forEach((index, j) -> {
					if (!geoInfo.weightTable.exists(index)) geoInfo.weightTable.set(index, []);
					geoInfo.weightTable.get(index).push({
						id: i,
						weight: rawBone.weights[j]
					});
				});
			});
		}
		return geoInfo;
	}

	public function genBuffers(geoInfo:FBXGeoInfo):FBXBuffers {
		final buffers = {
			vertex: [],
			normal: [],
			colors: [],
			uvs: [],
			materialIndex: [],
			vertexWeights: [],
			weightsIndices: []
		};
		var polygonIndex = 0;
		var faceLength = 0;
		var displayedWeightsWarning = false;
		var facePositionIndexes = [];
		var faceNormals = [];
		var faceColors = [];
		var faceUVs = [];
		var faceWeights = [];
		var faceWeightIndices = [];
		geoInfo.vertexIndices.forEach((vertexIndex, polygonVertexIndex) -> {
			var materialIndex:Int;
			var endOfFace:Bool = false;
			if (vertexIndex < 0) {
				vertexIndex = vertexIndex ^ - 1;
				endOfFace = true;
			}
			var weightIndices = [];
			var weights = [];
			facePositionIndexes.push(vertexIndex * 3, vertexIndex * 3 + 1, vertexIndex * 3 + 2);
			if (geoInfo.color != null) {
				final data = getData(polygonVertexIndex, polygonIndex, vertexIndex, geoInfo.color);
				faceColors.push(data[0], data[1], data[2]);
			}
			if (geoInfo.skeleton != null) {
				if (geoInfo.weightTable.exists(vertexIndex)) {
					geoInfo.weightTable.get(vertexIndex).forEach((wt) -> {
						weights.push(wt.weight);
						weightIndices.push(wt.id);
					});
				}
				if (weights.length > 4) {
					if (!displayedWeightsWarning) {
						console.warn('THREE.FBXLoader: Vertex has more than 4 skinning weights assigned to vertex. Deleting additional weights.');
						displayedWeightsWarning = true;
					}
					final wIndex = [0, 0, 0, 0];
					final Weight = [0, 0, 0, 0];
					weights.forEach((weight, weightIndex) -> {
						var currentWeight = weight;
						var currentIndex = weightIndices[weightIndex];
						Weight.forEach((comparedWeight, comparedWeightIndex, comparedWeightArray) -> {
							if (currentWeight > comparedWeight) {
								comparedWeightArray[comparedWeightIndex] = currentWeight;
								currentWeight = comparedWeight;
								final tmp = wIndex[comparedWeightIndex];
								wIndex[comparedWeightIndex] = currentIndex;
								currentIndex = tmp;
							}
						});
					});
					weightIndices = wIndex;
					weights = Weight;
				}
				while (weights.length < 4) {
					weights.push(0);
					weightIndices.push(0);
				}
				for (i in 0...4) {
					faceWeights.push(weights[i]);
					faceWeightIndices.push(weightIndices[i]);
				}
			}
			if (geoInfo.normal != null) {
				final data = getData(polygonVertexIndex, polygonIndex, vertexIndex, geoInfo.normal);
				faceNormals.push(data[0], data[1], data[2]);
			}
			if (geoInfo.material != null && geoInfo.material.mappingType != 'AllSame') {
				materialIndex = getData(polygonVertexIndex, polygonIndex, vertexIndex, geoInfo.material)[0];
				if (materialIndex < 0) {
					this.negativeMaterialIndices = true;
					materialIndex = 0;
				}
			}
			if (geoInfo.uv != null) {
				geoInfo.uv.forEach((uv, i) -> {
					final data = getData(polygonVertexIndex, polygonIndex, vertexIndex, uv);
					if (faceUVs[i] == null) {
						faceUVs[i] = [];
					}
					faceUVs[i].push(data[0]);
					faceUVs[i].push(data[1]);
				});
			}
			faceLength++;
			if (endOfFace) {
				this.genFace(buffers, geoInfo, facePositionIndexes, materialIndex, faceNormals, faceColors, faceUVs, faceWeights, faceWeightIndices, faceLength);
				polygonIndex++;
				faceLength = 0;
				facePositionIndexes = [];
				faceNormals = [];
				faceColors = [];
				faceUVs = [];
				faceWeights = [];
				faceWeightIndices = [];
			}
		});
		return buffers;
	}

	// See https://www.khronos.org/opengl/wiki/Calculating_a_Surface_Normal
	public function getNormalNewell(vertices:Array<Vector3>):Vector3 {
		final normal = new Vector3(0.0, 0.0, 0.0);
		for (i in 0...vertices.length) {
			final current = vertices[i];
			final next = vertices[(i + 1) % vertices.length];
			normal.x += (current.y - next.y) * (current.z + next.z);
			normal.y += (current.z - next.z) * (current.x + next.x);
			normal.z += (current.x - next.x) * (current.y + next.y);
		}
		normal.normalize();
		return normal;
	}

	public function getNormalTangentAndBitangent(vertices:Array<Vector3>):{ normal:Vector3, tangent:Vector3, bitangent:Vector3 } {
		final normalVector = this.getNormalNewell(vertices);
		final up = Math.abs(normalVector.z) > 0.5 ? new Vector3(0.0, 1.0, 0.0) : new Vector3(0.0, 0.0, 1.0);
		final tangent = up.cross(normalVector).normalize();
		final bitangent = normalVector.clone().cross(tangent).normalize();
		return {
			normal: normalVector,
			tangent: tangent,
			bitangent: bitangent
		};
	}

	public function flattenVertex(vertex:Vector3, normalTangent:Vector3, normalBitangent:Vector3):Vector2 {
		return new Vector2(
			vertex.dot(normalTangent),
			vertex.dot(normalBitangent)
		);
	}

	// Generate data for a single face in a geometry. If the face is a quad then split it into 2 tris
	public function genFace(buffers:FBXBuffers, geoInfo:FBXGeoInfo, facePositionIndexes:Array<Float>, materialIndex:Int, faceNormals:Array<Float>, faceColors:Array<Float>, faceUVs:Array<Array<Float>>, faceWeights:Array<Float>, faceWeightIndices:Array<Int>, faceLength:Int) {
		var triangles:Array<Array<Int>>;
		if (faceLength > 3) {
			final vertices = [];
			for (i in 0...facePositionIndexes.length) {
				vertices.push(new Vector3(
					geoInfo.vertexPositions[facePositionIndexes[i]],
					geoInfo.vertexPositions[facePositionIndexes[i + 1]],
					geoInfo.vertexPositions[facePositionIndexes[i + 2]]
				));
			}
			final normalTangentAndBitangent = this.getNormalTangentAndBitangent(vertices);
			final triangulationInput = [];
			vertices.forEach((vertex) -> triangulationInput.push(this.flattenVertex(vertex, normalTangentAndBitangent.tangent, normalTangentAndBitangent.bitangent)));
			triangles = ShapeUtils.triangulateShape(triangulationInput, []);
		} else {
			triangles = [[0, 1, 2]];
		}
		triangles.forEach((triangle) -> {
			final i0 = triangle[0];
			final i1 = triangle[1];
			final i2 = triangle[2];
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i0 * 3]]);
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i0 * 3 + 1]]);
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i0 * 3 + 2]]);
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i1 * 3]]);
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i1 * 3 + 1]]);
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i1 * 3 + 2]]);
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i2 * 3]]);
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i2 * 3 + 1]]);
			buffers.vertex.push(geoInfo.vertexPositions[facePositionIndexes[i2 * 3 + 2]]);
			if (geoInfo.skeleton != null) {
				buffers.vertexWeights.push(faceWeights[i0 * 4]);
				buffers.vertexWeights.push(faceWeights[i0 * 4 + 1]);
				buffers.vertexWeights.push(faceWeights[i0 * 4 + 2]);
				buffers.vertexWeights.push(faceWeights[i0 * 4 + 3]);
				buffers.vertexWeights.push(faceWeights[i1 * 4]);
				buffers.vertexWeights.push(faceWeights[i1 * 4 + 1]);
				buffers.vertexWeights.push(faceWeights[i1 * 4 + 2]);
				buffers.vertexWeights.push(faceWeights[i1 * 4 + 3]);
				buffers.vertexWeights.push(faceWeights[i2 * 4]);
				buffers.vertexWeights.push(faceWeights[i2 * 4 + 1]);
				buffers.vertexWeights.push(faceWeights[i2 * 4 + 2]);
				buffers.vertexWeights.push(faceWeights[i2 * 4 + 3]);
				buffers.weightsIndices.push(faceWeightIndices[i0 * 4]);
				buffers.weightsIndices.push(faceWeightIndices[i0 * 4 + 1]);
				buffers.weightsIndices.push(faceWeightIndices[i0 * 4 + 2]);
				buffers.weightsIndices.push(faceWeightIndices[i0 * 4 + 3]);
				buffers.weightsIndices.push(faceWeightIndices[i1 * 4]);
				buffers.weightsIndices.push(faceWeightIndices[i1 * 4 + 1]);
				buffers.weightsIndices.push(faceWeightIndices[i1 * 4 + 2]);
				buffers.weightsIndices.push(faceWeightIndices[i1 * 4 + 3]);
				buffers.weightsIndices.push(faceWeightIndices[i2 * 4]);
				buffers.weightsIndices.push(faceWeightIndices[i2 * 4 + 1]);
				buffers.weightsIndices.push(faceWeightIndices[i2 * 4 + 2]);
				buffers.weightsIndices.push(faceWeightIndices[i2 * 4 + 3]);
			}
			if (geoInfo.color != null) {
				buffers.colors.push(faceColors[i0 * 3]);
				buffers.colors.push(faceColors[i0 * 3 + 1]);
				buffers.colors.push(faceColors[i0 * 3 + 2]);
				buffers.colors.push(faceColors[i1 * 3]);
				buffers.colors.push(faceColors[i1 * 3 + 1]);
				buffers.colors.push(faceColors[i1 * 3 + 2]);
				buffers.colors.push(faceColors[i2 * 3]);
				buffers.colors.push(faceColors[i2 * 3 + 1]);
				buffers.colors.push(faceColors[i2 * 3 + 2]);
			}
			if (geoInfo.material != null && geoInfo.material.mappingType != 'AllSame') {
				buffers.materialIndex.push(materialIndex);
				buffers.materialIndex.push(materialIndex);
				buffers.materialIndex.push(materialIndex);
			}
			if (geoInfo.normal != null) {
				buffers.normal.push(faceNormals[i0 * 3]);
				buffers.normal.push(faceNormals[i0 * 3 + 1]);
				buffers.normal.push(faceNormals[i0 * 3 + 2]);
				buffers.normal.push(faceNormals[i1 * 3]);
				buffers.normal.push(faceNormals[i1 * 3 + 1]);
				buffers.normal.push(faceNormals[i1 * 3 + 2]);
				buffers.normal.push(faceNormals[i2 * 3]);
				buffers.normal.push(faceNormals[i2 * 3 + 1]);
				buffers.normal.push(faceNormals[i2 * 3 + 2]);
			}
			if (geoInfo.uv != null) {
				geoInfo.uv.forEach((uv, j) -> {
					if (buffers.uvs[j] == null) buffers.uvs[j] = [];
					buffers.uvs[j].push(faceUVs[j][i0 * 2]);
					buffers.uvs[j].push(faceUVs[j][i0 * 2 + 1]);
					buffers.uvs[j].push(faceUVs[j][i1 * 2]);
					buffers.uvs[j].push(faceUVs[j][i1 * 2 + 1]);
					buffers.uvs[j].push(faceUVs[j][i2 * 2]);
					buffers.uvs[j].push(faceUVs[j][i2 * 2 + 1]);
				});
			}
		});
	}

	public function addMorphTargets(parentGeo:BufferGeometry, parentGeoNode:Dynamic, morphTargets:Array<FBXMorphTarget>, preTransform:Matrix4) {
		if (morphTargets.length == 0) return;
		parentGeo.morphTargetsRelative = true;
		parentGeo.morphAttributes.position = [];
		morphTargets.forEach((morphTarget) -> {
			morphTarget.rawTargets.forEach((rawTarget) -> {
				final morphGeoNode = fbxTree.Objects.Geometry[rawTarget.geoID];
				if (morphGeoNode != null) {
					this.genMorphGeometry(parentGeo, parentGeoNode, morphGeoNode, preTransform, rawTarget.name);
				}
			});
		});
	}

	// a morph geometry node is similar to a standard  node, and the node is also contained
	// in FBXTree.Objects.Geometry, however it can only have attributes for position, normal
	// and a special attribute Index defining which vertices of the original geometry are affected
	// Normal and position attributes only have data for the vertices that are affected by the morph
	public function genMorphGeometry(parentGeo:BufferGeometry, parentGeoNode:Dynamic, morphGeoNode:Dynamic, preTransform:Matrix4, name:String) {
		final vertexIndices = (parentGeoNode.PolygonVertexIndex != null) ? parentGeoNode.PolygonVertexIndex.a : [];
		final morphPositionsSparse = (morphGeoNode.Vertices != null) ? morphGeoNode.Vertices.a : [];
		final indices = (morphGeoNode.Indexes != null) ? morphGeoNode.Indexes.a : [];
		final length = parentGeo.attributes.position.count * 3;
		final morphPositions = new Float32Array(length);
		for (i in 0...indices.length) {
			final morphIndex = indices[i] * 3;
			morphPositions[morphIndex] = morphPositionsSparse[i * 3];
			morphPositions[morphIndex + 1] = morphPositionsSparse[i * 3 + 1];
			morphPositions[morphIndex + 2] = morphPositionsSparse[i * 3 + 2];
		}
		final morphGeoInfo = {
			vertexIndices: vertexIndices,
			vertexPositions: morphPositions
		};
		final morphBuffers = this.genBuffers(morphGeoInfo);
		final positionAttribute = new Float32BufferAttribute(morphBuffers.vertex, 3);
		positionAttribute.name = name != null ? name : morphGeoNode.attrName;
		positionAttribute.applyMatrix4(preTransform);
		parentGeo.morphAttributes.position.push(positionAttribute);
	}

	// Parse normal from FBXTree.Objects.Geometry.LayerElementNormal if it exists
	public function parseNormals(NormalNode:Dynamic):FBXLayerElement {
		final mappingType = NormalNode.MappingInformationType;
		final referenceType = NormalNode.ReferenceInformationType;
		final buffer = NormalNode.Normals.a;
		var indexBuffer = [];
		if (referenceType == 'IndexToDirect') {
			if ('NormalIndex' in NormalNode) {
				indexBuffer = NormalNode.NormalIndex.a;
			} else if ('NormalsIndex' in NormalNode) {
				indexBuffer = NormalNode.NormalsIndex.a;
			}
		}
		return {
			dataSize: 3,
			buffer: buffer,
			indices: indexBuffer,
			mappingType: mappingType,
			referenceType: referenceType
		};
	}

	// Parse UVs from FBXTree.Objects.Geometry.LayerElementUV if it exists
	public function parseUVs(UVNode:Dynamic):FBXLayerElement {
		final mappingType = UVNode.MappingInformationType;
		final referenceType = UVNode.ReferenceInformationType;
		final buffer = UVNode.UV.a;
		var indexBuffer = [];
		if (referenceType == 'IndexToDirect') {
			indexBuffer = UVNode.UVIndex.a;
		}
		return {
			dataSize: 2,
			buffer: buffer,
			indices: indexBuffer,
			mappingType: mappingType,
			referenceType: referenceType
		};
	}

	// Parse Vertex Colors from FBXTree.Objects.Geometry.LayerElementColor if it exists
	public function parseVertexColors(ColorNode:Dynamic):FBXLayerElement {
		final mappingType = ColorNode.MappingInformationType;
		final referenceType = ColorNode.ReferenceInformationType;
		final buffer = ColorNode.Colors.a;
		var indexBuffer = [];
		if (referenceType == 'IndexToDirect') {
			indexBuffer = ColorNode.ColorIndex.a;
		}
		for (i in 0...buffer.length) {
			final c = new Color();
			c.fromArray(buffer, i).convertSRGBToLinear().toArray(buffer, i);
		}
		return {
			dataSize: 4,
			buffer: buffer,
			indices: indexBuffer,
			mappingType: mappingType,
			referenceType: referenceType
		};
	}

	// Parse mapping and material data in FBXTree.Objects.Geometry.LayerElementMaterial if it exists
	public function parseMaterialIndices(MaterialNode:Dynamic):FBXLayerElement {
		final mappingType = MaterialNode.MappingInformationType;
		final referenceType = MaterialNode.ReferenceInformationType;
		if (mappingType == 'NoMappingInformation') {
			return {
				dataSize: 1,
				buffer: [0],
				indices: [0],
				mappingType: 'AllSame',
				referenceType: referenceType
			};
		}
		final materialIndexBuffer = MaterialNode.Materials.a;
		final materialIndices = [];
		for (i in 0...materialIndexBuffer.length) {
			materialIndices.push(i);
		}
		return {
			dataSize: 1,
			buffer: materialIndexBuffer,
			indices: materialIndices,
			mappingType: mappingType,
			referenceType: referenceType
		};
	}

	// Generate a NurbGeometry from a node in FBXTree.Objects.Geometry
	public function parseNurbsGeometry(geoNode:Dynamic):BufferGeometry {
		final order = Std.parseInt(geoNode.Order);
		if (Math.isNaN(order)) {
			console.error('THREE.FBXLoader: Invalid Order %s given for geometry ID: %s', geoNode.Order, geoNode.id);
			return new BufferGeometry();
		}
		final degree = order - 1;
		final knots = geoNode.KnotVector.a;
		final controlPoints = [];
		final pointsValues = geoNode.Points.a;
		for (i in 0...pointsValues.length) {
			controlPoints.push(new Vector4().fromArray(pointsValues, i));
		}
		var startKnot:Int, endKnot:Int;
		if (geoNode.Form == 'Closed') {
			controlPoints.push(controlPoints[0]);
		} else if (geoNode.Form == 'Periodic') {
			startKnot = degree;
			endKnot = knots.length - 1 - startKnot;
			for (i in 0...degree) {
				controlPoints.push(controlPoints[i]);
			}
		}
		final curve = new NURBSCurve(degree, knots, controlPoints, startKnot, endKnot);
		final points = curve.getPoints(controlPoints.length * 1
			controlPoints.push(controlPoints[0]);
		} else if (geoNode.Form == 'Periodic') {
			startKnot = degree;
			endKnot = knots.length - 1 - startKnot;
			for (i in 0...degree) {
				controlPoints.push(controlPoints[i]);
			}
		}
		final curve = new NURBSCurve(degree, knots, controlPoints, startKnot, endKnot);
		final points = curve.getPoints(controlPoints.length * 12);
		return new BufferGeometry().setFromPoints(points);
	}
}

// parse animation data from FBXTree
class AnimationParser {
	// take raw animation clips and turn them into three.js animation clips
	public function parse():Array<AnimationClip> {
		final animationClips = [];
		final rawClips = this.parseClips();
		if (rawClips != null) {
			for (key in rawClips) {
				final rawClip = rawClips[key];
				final clip = this.addClip(rawClip);
				animationClips.push(clip);
			}
		}
		return animationClips;
	}

	public function parseClips():Map<Int, FBXRawClip> {
		if (fbxTree.Objects.AnimationCurve == null) return null;
		final curveNodesMap = this.parseAnimationCurveNodes();
		this.parseAnimationCurves(curveNodesMap);
		final layersMap = this.parseAnimationLayers(curveNodesMap);
		final rawClips = this.parseAnimStacks(layersMap);
		return rawClips;
	}

	// parse nodes in FBXTree.Objects.AnimationCurveNode
	// each AnimationCurveNode holds data for an animation transform for a model (e.g. left arm rotation )
	// and is referenced by an AnimationLayer
	public function parseAnimationCurveNodes():Map<Int, FBXCurveNode> {
		final rawCurveNodes = fbxTree.Objects.AnimationCurveNode;
		final curveNodesMap = new Map<Int, FBXCurveNode>();
		for (nodeID in rawCurveNodes) {
			final rawCurveNode = rawCurveNodes[nodeID];
			if (rawCurveNode.attrName.match(/S|R|T|DeformPercent/) != null) {
				final curveNode = {
					id: rawCurveNode.id,
					attr: rawCurveNode.attrName,
					curves: {}
				};
				curveNodesMap.set(curveNode.id, curveNode);
			}
		}
		return curveNodesMap;
	}

	// parse nodes in FBXTree.Objects.AnimationCurve and connect them up to
	// previously parsed AnimationCurveNodes. Each AnimationCurve holds data for a single animated
	// axis ( e.g. times and values of x rotation)
	public function parseAnimationCurves(curveNodesMap:Map<Int, FBXCurveNode>) {
		final rawCurves = fbxTree.Objects.AnimationCurve;
		for (nodeID in rawCurves) {
			final animationCurve = {
				id: rawCurves[nodeID].id,
				times: rawCurves[nodeID].KeyTime.a.map(convertFBXTimeToSeconds),
				values: rawCurves[nodeID].KeyValueFloat.a
			};
			final relationships = connections.get(animationCurve.id);
			if (relationships != null) {
				final animationCurveID = relationships.parents[0].ID;
				final animationCurveRelationship = relationships.parents[0].relationship;
				if (animationCurveRelationship.match(/X/) != null) {
					curveNodesMap.get(animationCurveID).curves['x'] = animationCurve;
				} else if (animationCurveRelationship.match(/Y/) != null) {
					curveNodesMap.get(animationCurveID).curves['y'] = animationCurve;
				} else if (animationCurveRelationship.match(/Z/) != null) {
					curveNodesMap.get(animationCurveID).curves['z'] = animationCurve;
				} else if (animationCurveRelationship.match(/DeformPercent/) != null && curveNodesMap.exists(animationCurveID)) {
					curveNodesMap.get(animationCurveID).curves['morph'] = animationCurve;
				}
			}
		}
	}

	// parse nodes in FBXTree.Objects.AnimationLayer. Each layers holds references
	// to various AnimationCurveNodes and is referenced by an AnimationStack node
	// note: theoretically a stack can have multiple layers, however in practice there always seems to be one per stack
	public function parseAnimationLayers(curveNodesMap:Map<Int, FBXCurveNode>):Map<Int, Array<FBXAnimTrackNode>> {
		final rawLayers = fbxTree.Objects.AnimationLayer;
		final layersMap = new Map<Int, Array<FBXAnimTrackNode>>();
		for (nodeID in rawLayers) {
			final layerCurveNodes = [];
			final connection = connections.get(Std.parseInt(nodeID));
			if (connection != null) {
				final children = connection.children;
				children.forEach((child, i) -> {
					if (curveNodesMap.exists(child.ID)) {
						final curveNode = curveNodesMap.get(child.ID);
						if (curveNode.curves.x != null || curveNode.curves.y != null || curveNode.curves.z != null) {
							if (layerCurveNodes[i] == null) {
								final modelID = connections.get(child.ID).parents.filter((parent) -> parent.relationship != null)[0].ID;
								if (modelID != null) {
									final rawModel = fbxTree.Objects.Model[modelID.toString()];
									if (rawModel == null) {
										console.warn('THREE.FBXLoader: Encountered a unused curve.', child);
										return;
									}
									final node = {
										modelName: rawModel.attrName != null ? PropertyBinding.sanitizeNodeName(rawModel.attrName) : '',
										ID: rawModel.id,
										initialPosition: [0, 0, 0],
										initialRotation: [0, 0, 0],
										initialScale: [1, 1, 1],
										transform: null,
										preRotation: null,
										postRotation: null,
										eulerOrder: null
									};
									sceneGraph.traverse((child) -> {
										if (child.ID == rawModel.id) {
											node.transform = child.matrix;
											if (child.userData.transformData != null) node.eulerOrder = child.userData.transformData.eulerOrder;
										}
									});
									if (node.transform == null) node.transform = new Matrix4();
									if ('PreRotation' in rawModel) node.preRotation = rawModel.PreRotation.value;
									if ('PostRotation' in rawModel) node.postRotation = rawModel.PostRotation.value;
									layerCurveNodes[i] = node;
								}
							}
							if (layerCurveNodes[i] != null) layerCurveNodes[i][curveNode.attr] = curveNode;
						} else if (curveNode.curves.morph != null) {
							if (layerCurveNodes[i] == null) {
								final deformerID = connections.get(child.ID).parents.filter((parent) -> parent.relationship != null)[0].ID;
								final morpherID = connections.get(deformerID).parents[0].ID;
								final geoID = connections.get(morpherID).parents[0].ID;
								final modelID = connections.get(geoID).parents[0].ID;
								final rawModel = fbxTree.Objects.Model[modelID];
								final node = {
									modelName: rawModel.attrName != null ? PropertyBinding.sanitizeNodeName(rawModel.attrName) : '',
									morphName: fbxTree.Objects.Deformer[deformerID].attrName
								};
								layerCurveNodes[i] = node;
							}
							layerCurveNodes[i][curveNode.attr] = curveNode;
						}
					}
				});
				layersMap.set(Std.parseInt(nodeID), layerCurveNodes);
			}
		}
		return layersMap;
	}

	// parse nodes in FBXTree.Objects.AnimationStack. These are the top level node in the animation
	// hierarchy. Each Stack node will be used to create a AnimationClip
	public function parseAnimStacks(layersMap:Map<Int, Array<FBXAnimTrackNode>>):Map<Int, FBXRawClip> {
		final rawStacks = fbxTree.Objects.AnimationStack;
		final rawClips = new Map<Int, FBXRawClip>();
		for (nodeID in rawStacks) {
			final children = connections.get(Std.parseInt(nodeID)).children;
			if (children.length > 1) {
				console.warn('THREE.FBXLoader: Encountered an animation stack with multiple layers, this is currently not supported. Ignoring subsequent layers.');
			}
			final layer = layersMap.get(children[0].ID);
			rawClips.set(Std.parseInt(nodeID), {
				name: rawStacks[nodeID].attrName,
				layer: layer
			});
		}
		return rawClips;
	}

	public function addClip(rawClip:FBXRawClip):AnimationClip {
		var tracks = [];
		rawClip.layer.forEach((rawTracks) -> tracks = tracks.concat(this.generateTracks(rawTracks)));
		return new AnimationClip(rawClip.name, -1, tracks);
	}

	public function generateTracks(rawTracks:FBXAnimTrackNode):Array<Dynamic> {
		final tracks = [];
		var initialPosition = new Vector3();
		var initialScale = new Vector3();
		if (rawTracks.transform != null) rawTracks.transform.decompose(initialPosition, new Quaternion(), initialScale);
		initialPosition = initialPosition.toArray();
		initialScale = initialScale.toArray();
		if (rawTracks.T != null && Object.keys(rawTracks.T.curves).length > 0) {
			final positionTrack = this.generateVectorTrack(rawTracks.modelName, rawTracks.T.curves, initialPosition, 'position');
			if (positionTrack != null) tracks.push(positionTrack);
		}
		if (rawTracks.R != null && Object.keys(rawTracks.R.curves).length > 0) {
			final rotationTrack = this.generateRotationTrack(rawTracks.modelName, rawTracks.R.curves, rawTracks.preRotation, rawTracks.postRotation, rawTracks.eulerOrder);
			if (rotationTrack != null) tracks.push(rotationTrack);
		}
		if (rawTracks.S != null && Object.keys(rawTracks.S.curves).length > 0) {
			final scaleTrack = this.generateVectorTrack(rawTracks.modelName, rawTracks.S.curves, initialScale, 'scale');
			if (scaleTrack != null) tracks.push(scaleTrack);
		}
		if (rawTracks.DeformPercent != null) {
			final morphTrack = this.generateMorphTrack(rawTracks);
			if (morphTrack != null) tracks.push(morphTrack);
		}
		return tracks;
	}

	public function generateVectorTrack(modelName:String, curves:Dynamic, initialValue:Array<Float>, type:String):Dynamic {
		final times = this.getTimesForAllAxes(curves);
		final values = this.getKeyframeTrackValues(times, curves, initialValue);
		return new VectorKeyframeTrack(modelName + '.' + type, times, values);
	}

	public function generateRotationTrack(modelName:String, curves:Dynamic, preRotation:Array<Float>, postRotation:Array<Float>, eulerOrder:String):Dynamic {
		var times:Array<Float>;
		var values:Array<Float>;
		if (curves.x != null && curves.y != null && curves.z != null) {
			final result = this.interpolateRotations(curves.x, curves.y, curves.z, eulerOrder);
			times = result[0];
			values = result[1];
		}
		if (preRotation != null) {
			preRotation = preRotation.map(MathUtils.degToRad);
			preRotation.push(eulerOrder);
			preRotation = new Euler().fromArray(preRotation);
			preRotation = new Quaternion().setFromEuler(preRotation);
		}
		if (postRotation != null) {
			postRotation = postRotation.map(MathUtils.degToRad);
			postRotation.push(eulerOrder);
			postRotation = new Euler().fromArray(postRotation);
			postRotation = new Quaternion().setFromEuler(postRotation).invert();
		}
		final quaternion = new Quaternion();
		final euler = new Euler();
		final quaternionValues = [];
		if (values == null || times == null) return new QuaternionKeyframeTrack(modelName + '.quaternion', [0], [0]);
		for (i in 0...values.length) {
			if (i % 3 == 0) {
				euler.set(values[i], values[i + 1], values[i + 2], eulerOrder);
				quaternion.setFromEuler(euler);
				if (preRotation != null) quaternion.premultiply(preRotation);
				if (postRotation != null) quaternion.multiply(postRotation);
				if (i > 2) {
					final prevQuat = new Quaternion().fromArray(quaternionValues, ((i - 3) / 3) * 4);
					if (prevQuat.dot(quaternion) < 0) {
						quaternion.set(-quaternion.x, -quaternion.y, -quaternion.z, -quaternion.w);
					}
				}
				quaternion.toArray(quaternionValues, (i / 3) * 4);
			}
		}
		return new QuaternionKeyframeTrack(modelName + '.quaternion', times, quaternionValues);
	}

	public function generateMorphTrack(rawTracks:FBXAnimTrackNode):Dynamic {
		final curves = rawTracks.DeformPercent.curves.morph;
		final values = curves.values.map((val) -> val / 100);
		final morphNum = sceneGraph.getObjectByName(rawTracks.modelName).morphTargetDictionary[rawTracks.morphName];
		return new NumberKeyframeTrack(rawTracks.modelName + '.morphTargetInfluences[' + morphNum + ']', curves.times, values);
	}

	// For all animated objects, times are defined separately for each axis
	// Here we'll combine the times into one sorted array without duplicates
	public function getTimesForAllAxes(curves:Dynamic):Array<Float> {
		var times = [];
		if (curves.x != null) times = times.concat(curves.x.times);
		if (curves.y != null) times = times.concat(curves.y.times);
		if (curves.z != null) times = times.concat(curves.z.times);
		times = times.sort((a, b) -> a - b);
		if (times.length > 1) {
			var targetIndex = 1;
			var lastValue = times[0];
			for (i in 1...times.length) {
				final currentValue = times[i];
				if (currentValue != lastValue) {
					times[targetIndex] = currentValue;
					lastValue = currentValue;
					targetIndex++;
				}
			}
			times = times.slice(0, targetIndex);
		}
		return times;
	}

	public function getKeyframeTrackValues(times:Array<Float>, curves:Dynamic, initialValue:Array<Float>):Array<Float> {
		final prevValue = initialValue;
		final values = [];
		var xIndex = - 1;
		var yIndex = - 1;
		var zIndex = - 1;
		times.forEach((time) -> {
			if (curves.x != null) xIndex = curves.x.times.indexOf(time);
			if (curves.y != null) yIndex = curves.y.times.indexOf(time);
			if (curves.z != null) zIndex = curves.z.times.indexOf(time);
			if (xIndex != - 1) {
				final xValue = curves.x.values[xIndex];
				values.push(xValue);
				prevValue[0] = xValue;
			} else {
				values.push(prevValue[0]);
			}
			if (yIndex != - 1) {
				final yValue = curves.y.values[yIndex];
				values.push(yValue);
				prevValue[1] = yValue;
			} else {
				values.push(prevValue[1]);
			}
			if (zIndex != - 1) {
				final zValue = curves.z.values[zIndex];
				values.push(zValue);
				prevValue[2] = zValue;
			} else {
				values.push(prevValue[2]);
			}
		});
		return values;
	}

	// Rotations are defined as Euler angles which can have values  of any size
	// These will be converted to quaternions which don't support values greater than
	// PI, so we'll interpolate large rotations
	public function interpolateRotations(curvex:FBXAnimationCurve, curvey:FBXAnimationCurve, curvez:FBXAnimationCurve, eulerOrder:String):Array<Array<Float>> {
		final times = [];
		final values = [];
		times.push(curvex.times[0]);
		values.push(MathUtils.degToRad(curvex.values[0]));
		values.push(MathUtils.degToRad(curvey.values[0]));
		values.push(MathUtils.degToRad(curvez.values[0]));
		for (i in 1...curvex.values.length) {
			final initialValue = [
				curvex.values[i - 1],
				curvey.values[i - 1],
				curvez.values[i - 1]
			];
			if (Math.isNaN(initialValue[0]) || Math.isNaN(initialValue[1]) || Math.isNaN(initialValue[2])) {
				continue;
			}
			final initialValueRad = initialValue.map(MathUtils.degToRad);
			final currentValue = [
				curvex.values[i],
				curvey.values[i],
				curvez.values[i]
			];
			if (Math.isNaN(currentValue[0]) || Math.isNaN(currentValue[1]) || Math.isNaN(currentValue[2])) {
				continue;
			}
			final currentValueRad = currentValue.map(MathUtils.degToRad);
			final valuesSpan = [
				currentValue[0] - initialValue[0],
				currentValue[1] - initialValue[1],
				currentValue[2] - initialValue[2]
			];
			final absoluteSpan = [
				Math.abs(valuesSpan[0]),
				Math.abs(valuesSpan[1]),
				Math.abs(valuesSpan[2])
			];
			if (absoluteSpan[0] >= 180 || absoluteSpan[1] >= 180 || absoluteSpan[2] >= 180) {
				final maxAbsSpan = Math.max(absoluteSpan[0], absoluteSpan[1], absoluteSpan[2]);
				final numSubIntervals = maxAbsSpan / 180;
				final E1 = new Euler(initialValueRad[0], initialValueRad[1], initialValueRad[2], eulerOrder);
				final E2 = new Euler(currentValueRad[0], currentValueRad[1], currentValueRad[2], eulerOrder);
				final Q1 = new Quaternion().setFromEuler(E1);
				final Q2 = new Quaternion().setFromEuler(E2);
				if (Q1.dot(Q2) < 0) {
					Q2.set(-Q2.x, -Q2.y, -Q2.z, -Q2.w);
				}
				final initialTime = curvex.times[i - 1];
				final timeSpan = curvex.times[i] - initialTime;
				final Q = new Quaternion();
				final E = new Euler();
				for (t in 0...numSubIntervals) {
					Q.copy(Q1.clone().slerp(Q2.clone(), t / numSubIntervals));
					times.push(initialTime + t * timeSpan / numSubIntervals);
					E.setFromQuaternion(Q, eulerOrder);
					values.push(E.x);
					values.push(E.y);
					values.push(E.z);
				}
			} else {
				times.push(curvex.times[i]);
				values.push(MathUtils.degToRad(curvex.values[i]));
				values.push(MathUtils.degToRad(curvey.values[i]));
				values.push(MathUtils.degToRad(curvez.values[i]));
			}
		}
		return [times, values];
	}
}

// parse an FBX file in ASCII format
class TextParser {
	public var currentIndent:Int = 0;
	public var allNodes:FBXTree = null;
	public var nodeStack:Array<Dynamic> = null;
	public var currentProp:Array<Dynamic> = null;
	public var currentPropName:String = null;

	public function new() {
		this.allNodes = new FBXTree();
		this.nodeStack = [];
		this.currentProp = [];
		this.currentPropName = '';
	}

	public function getPrevNode():Dynamic {
		return this.nodeStack[this.currentIndent - 2];
	}

	public function getCurrentNode():Dynamic {
		return this.nodeStack[this.currentIndent - 1];
	}

	public function getCurrentProp():Array<Dynamic> {
		return this.currentProp;
	}

	public function pushStack(node:Dynamic) {
		this.nodeStack.push(node);
		this.currentIndent += 1;
	}

	public function popStack() {
		this.nodeStack.pop();
		this.currentIndent -= 1;
	}

	public function setCurrentProp(val:Dynamic, name:String) {
		this.currentProp = val;
		this.currentPropName = name;
	}

	public function parse(text:String):FBXTree {
		this.currentIndent = 0;
		this.allNodes = new FBXTree();
		this.nodeStack = [];
		this.currentProp = [];
		this.currentPropName = '';
		final split = text.split(/[\r\n]+/);
		split.forEach((line, i) -> {
			final matchComment = line.match(/^[\s\t]*;/);
			final matchEmpty = line.match(/^[\s\t]*$/);
			if (matchComment != null || matchEmpty != null) return;
			final matchBeginning = line.match('^\\t{' + this.currentIndent + '}(\\w+):(.*){', '');
			final matchProperty = line.match('^\\t{' + (this.currentIndent) + '}(\\w+):[\\s\\t\\r\\n](.*)', '');
			final matchEnd = line.match('^\\t{' + (this.currentIndent - 1) + '}}', '');
			if (matchBeginning != null) {
				this.parseNodeBegin(line, matchBeginning);
			} else if (matchProperty != null) {
				this.parseNodeProperty(line, matchProperty, split[++i]);
			} else if (matchEnd != null) {
				this.popStack();
			} else if (line.match(/^[^\s\t}]/) != null) {
				this.parseNodePropertyContinued(line);
			}
		});
		return this.allNodes;
	}

	public function parseNodeBegin(line:String, property:Array<String>) {
		final nodeName = property[1].trim().replace(/^"/, '').replace(/"$/, '');
		final nodeAttrs = property[2].split(',').map((attr) -> attr.trim().replace(/^"/, '').replace(/"$/, ''));
		final node = {name: nodeName};
		final attrs = this.parseNodeAttr(nodeAttrs);
		final currentNode = this.getCurrentNode();
		if (this.currentIndent == 0) {
			this.allNodes.add(nodeName, node);
		} else {
			if (nodeName in currentNode) {
				if (nodeName == 'PoseNode') {
					currentNode.PoseNode.push(node);
				} else if (currentNode[nodeName].id != null) {
					currentNode[nodeName] = {};
					currentNode[nodeName][currentNode[nodeName].id] = currentNode[nodeName];
				}
				if (attrs.id != '') currentNode[nodeName][attrs.id] = node;
			} else if (Std.isOfType(attrs.id, Int)) {
				currentNode[nodeName] = {};
				currentNode[nodeName][attrs.id] = node;
			} else if (nodeName != 'Properties70') {
				if (nodeName == 'PoseNode') currentNode[nodeName] = [node];
				else currentNode[nodeName] = node;
			}
		}
		if (Std.isOfType(attrs.id, Int)) node.id = attrs.id;
		if (attrs.name != '') node.attrName = attrs.name;
		if (attrs.type != '') node.attrType = attrs.type;
		this.pushStack(node);
	}

	public function parseNodeAttr(attrs:Array<String>):{ id:Dynamic, name:String, type:String } {
		var id = attrs[0];
		if (attrs[0] != '') {
			id = Std.parseInt(attrs[0]);
			if (Math.isNaN(id)) {
				id = attrs[0];
			}
		}
		var name = '', type = '';
		if (attrs.length > 1) {
			name = attrs[1].replace(/^(\w+)::/, '');
			type = attrs[2];
		}
		return {id: id, name: name, type: type};
	}

	public function parseNodeProperty(line:String, property:Array<String>, contentLine:String) {
		var propName = property[1].replace(/^"/, '').replace(/"$/, '').trim();
		var propValue = property[2].replace(/^"/, '').replace(/"$/, '').trim();
		if (propName == 'Content' && propValue == ',') {
			propValue = contentLine.replace(/"/g, '').replace(/,$/, '').trim();
		}
		final currentNode = this.getCurrentNode();
		final parentName = currentNode.name;
		if (parentName == 'Properties70') {
			this.parseNodeSpecialProperty(line, propName, propValue);
			return;
		}
		if (propName == 'C') {
			final connProps = propValue.split(',').slice(1);
			final from = Std.parseInt(connProps[0]);
			final to = Std.parseInt(connProps[1]);
			var rest = propValue.split(',').slice(3);
			rest = rest.map((elem) -> elem.trim().replace(/^"/, ''));
			propName = 'connections';
			propValue = [from, to];
			append(propValue, rest);
			if (currentNode[propName] == null) {
				currentNode[propName] = [];
			}
		}
		if (propName == 'Node') currentNode.id = propValue;
		if (propName in currentNode && Std.isOfType(currentNode[propName], Array)) {
			currentNode[propName].push(propValue);
		} else {
			if (propName != 'a') currentNode[propName] = propValue;
			else currentNode.a = propValue;
		}
		this.setCurrentProp(currentNode, propName);
		if (propName == 'a' && propValue.substring(propValue.length - 1) != ',') {
			currentNode.a = parseNumberArray(propValue);
		}
	}

	public function parseNodePropertyContinued(line:String) {
		final currentNode = this.getCurrentNode();
		currentNode.a += line;
		if (line.substring(line.length - 1) != ',') {
			currentNode.a = parseNumberArray(currentNode.a);
		}
	}

	// parse "Property70"
	public function parseNodeSpecialProperty(line:String, propName:String, propValue:String) {
		final props = propValue.split('",').map((prop) -> prop.trim().replace(/^\"/, '').replace(/\s/, '_'));
		final innerPropName = props[0];
		final innerPropType1 = props[1];
		final innerPropType2 = props[2];
		final innerPropFlag = props[3];
		var innerPropValue = props[4];
		switch (innerPropType1) {
			case 'int':
			case 'enum':
			case 'bool':
			case 'ULongLong':
			case 'double':
			case 'Number':
			case 'FieldOfView':
				innerPropValue = Std.parseFloat(innerPropValue);
				break;
			case 'Color':
			case 'ColorRGB':
			case 'Vector3D':
			case 'Lcl_Translation':
			case 'Lcl_Rotation':
			case 'Lcl_Scaling':
				innerPropValue = parseNumberArray(innerPropValue);
				break;
		}
		this.getPrevNode()[innerPropName] = {
			type: innerPropType1,
			type2: innerPropType2,
			flag: innerPropFlag,
			value: innerPropValue
		};
		this.setCurrentProp(this.getPrevNode(), innerPropName);
	}
}

// Parse an FBX file in Binary format
class BinaryParser {
	public function new() {
	}

	public function parse(buffer:Bytes):FBXTree {
		final reader = new BinaryReader(buffer);
		reader.skip(23);
		final version = reader.getUint32();
		if (version < 6400) {
			throw new Error('THREE.FBXLoader: FBX version not supported, FileVersion: ' + version);
		}
		final allNodes = new FBXTree();
		while (!this.endOfContent(reader)) {
			final node = this.parseNode(reader, version);
			if (node != null) allNodes.add(node.name, node);
		}
		return allNodes;
	}

	// Check if reader has reached the end of content.
	public function endOfContent(reader:BinaryReader):Bool {
		if (reader.size() % 16 == 0) {
			return ((reader.getOffset() + 160 + 16) & ~0xf) >= reader.size();
		} else {
			return reader.getOffset() + 160 + 16 >= reader.size();
		}
	}

	// recursively parse nodes until the end of the file is reached
	public function parseNode(reader:BinaryReader, version:Int):Dynamic {
		final node = {};
		final endOffset = (version >= 7500) ? reader.getUint64() : reader.getUint32();
		final numProperties = (version >= 7500) ? reader.getUint64() : reader.getUint32();
		(version >= 7500) ? reader.getUint64() : reader.getUint32();
		final nameLen = reader.getUint8();
		final name = reader.getString(nameLen);
		if (endOffset == 0) return null;
		final propertyList = [];
		for (i in 0...numProperties) {
			propertyList.push(this.parseProperty(reader));
		}
		final id = propertyList.length > 0 ? propertyList[0] : '';
		final attrName = propertyList.length > 1 ? propertyList[1] : '';
		final attrType = propertyList.length > 2 ? propertyList[2] : '';
		node.singleProperty = (numProperties == 1 && reader.getOffset() == endOffset) ? true : false;
		while (endOffset > reader.getOffset()) {
			final subNode = this.parseNode(reader, version);
			if (subNode != null) this.parseSubNode(name, node, subNode);
		}
		node.propertyList = propertyList;
		if (Std.isOfType(id, Int)) node.id = id;
		if (attrName != '') node.attrName = attrName;
		if (attrType != '') node.attrType = attrType;
		if (name != '') node.name = name;
		return node;
	}

	public function parseSubNode(name:String, node:Dynamic, subNode:Dynamic) {
		if (subNode.singleProperty) {
			final value = subNode.propertyList[0];
			if (Std.isOfType(value, Array)) {
				node[subNode.name] = subNode;
				subNode.a = value;
			} else {
				node[subNode.name] = value;
			}
		} else if (name == 'Connections' && subNode.name == 'C') {
			final array = [];
			subNode.propertyList.forEach((property, i) -> {
				if (i != 0) array.push(property);
			});
			if (node.connections == null) {
				node.connections = [];
			}
			node.connections.push(array);
		} else if (subNode.name == 'Properties70') {
			final keys = Object.keys(subNode);
			keys.forEach((key) -> node[key] = subNode[key]);
		} else if (name == 'Properties70' && subNode.name == 'P') {
			var innerPropName = subNode.propertyList[0];
			var innerPropType1 = subNode.propertyList[1];
			final innerPropType2 = subNode.propertyList[2];
			final innerPropFlag = subNode.propertyList[3];
			var innerPropValue:Dynamic;
			if (innerPropName.indexOf('Lcl ') == 0) innerPropName = innerPropName.replace('Lcl ', 'Lcl_');
			if (innerPropType1.indexOf('Lcl ') == 0) innerPropType1 = innerPropType1.replace('Lcl ', 'Lcl_');
			if (innerPropType1 == 'Color' || innerPropType1 == 'ColorRGB' || innerPropType1 == 'Vector' || innerPropType1 == 'Vector3D' || innerPropType1.
			keys.forEach((key) -> node[key] = subNode[key]);
		} else if (name == 'Properties70' && subNode.name == 'P') {
			var innerPropName = subNode.propertyList[0];
			var innerPropType1 = subNode.propertyList[1];
			final innerPropType2 = subNode.propertyList[2];
			final innerPropFlag = subNode.propertyList[3];
			var innerPropValue:Dynamic;
			if (innerPropName.indexOf('Lcl ') == 0) innerPropName = innerPropName.replace('Lcl ', 'Lcl_');
			if (innerPropType1.indexOf('Lcl ') == 0) innerPropType1 = innerPropType1.replace('Lcl ', 'Lcl_');
			if (innerPropType1 == 'Color' || innerPropType1 == 'ColorRGB' || innerPropType1 == 'Vector' || innerPropType1 == 'Vector3D' || innerPropType1.indexOf('Lcl_') == 0) {
				innerPropValue = [
					subNode.propertyList[4],
					subNode.propertyList[5],
					subNode.propertyList[6]
				];
			} else {
				innerPropValue = subNode.propertyList[4];
			}
			node[innerPropName] = {
				type: innerPropType1,
				type2: innerPropType2,
				flag: innerPropFlag,
				value: innerPropValue
			};
		} else if (node[subNode.name] == null) {
			if (Std.isOfType(subNode.id, Int)) {
				node[subNode.name] = {};
				node[subNode.name][subNode.id] = subNode;
			} else {
				node[subNode.name] = subNode;
			}
		} else {
			if (subNode.name == 'PoseNode') {
				if (!Std.isOfType(node[subNode.name], Array)) {
					node[subNode.name] = [node[subNode.name]];
				}
				node[subNode.name].push(subNode);
			} else if (node[subNode.name][subNode.id] == null) {
				node[subNode.name][subNode.id] = subNode;
			}
		}
	}

	public function parseProperty(reader:BinaryReader):Dynamic {
		final type = reader.getString(1);
		var length:Int;
		switch (type) {
			case 'C':
				return reader.getBoolean();
			case 'D':
				return reader.getFloat64();
			case 'F':
				return reader.getFloat32();
			case 'I':
				return reader.getInt32();
			case 'L':
				return reader.getInt64();
			case 'R':
				length = reader.getUint32();
				return reader.getArrayBuffer(length);
			case 'S':
				length = reader.getUint32();
				return reader.getString(length);
			case 'Y':
				return reader.getInt16();
			case 'b':
			case 'c':
			case 'd':
			case 'f':
			case 'i':
			case 'l':
				final arrayLength = reader.getUint32();
				final encoding = reader.getUint32();
				final compressedLength = reader.getUint32();
				if (encoding == 0) {
					switch (type) {
						case 'b':
						case 'c':
							return reader.getBooleanArray(arrayLength);
						case 'd':
							return reader.getFloat64Array(arrayLength);
						case 'f':
							return reader.getFloat32Array(arrayLength);
						case 'i':
							return reader.getInt32Array(arrayLength);
						case 'l':
							return reader.getInt64Array(arrayLength);
					}
				}
				final data = FFlate.unzlibSync(new Uint8Array(reader.getArrayBuffer(compressedLength)));
				final reader2 = new BinaryReader(data.buffer);
				switch (type) {
					case 'b':
					case 'c':
						return reader2.getBooleanArray(arrayLength);
					case 'd':
						return reader2.getFloat64Array(arrayLength);
					case 'f':
						return reader2.getFloat32Array(arrayLength);
					case 'i':
						return reader2.getInt32Array(arrayLength);
					case 'l':
						return reader2.getInt64Array(arrayLength);
				}
				break;
			default:
				throw new Error('THREE.FBXLoader: Unknown property type ' + type);
		}
	}
}

class BinaryReader {
	public var dv:DataView = null;
	public var offset:Int = 0;
	public var littleEndian:Bool = true;
	public var _textDecoder:js.html.TextDecoder = null;

	public function new(buffer:Bytes, littleEndian:Bool = true) {
		this.dv = new DataView(buffer);
		this.offset = 0;
		this.littleEndian = littleEndian;
		this._textDecoder = new js.html.TextDecoder();
	}

	public function getOffset():Int {
		return this.offset;
	}

	public function size():Int {
		return this.dv.buffer.byteLength;
	}

	public function skip(length:Int) {
		this.offset += length;
	}

	// seems like true/false representation depends on exporter.
	// true: 1 or 'Y'(=0x59), false: 0 or 'T'(=0x54)
	// then sees LSB.
	public function getBoolean():Bool {
		return (this.getUint8() & 1) == 1;
	}

	public function getBooleanArray(size:Int):Array<Bool> {
		final a = [];
		for (i in 0...size) {
			a.push(this.getBoolean());
		}
		return a;
	}

	public function getUint8():Int {
		final value = this.dv.getUint8(this.offset);
		this.offset += 1;
		return value;
	}

	public function getInt16():Int {
		final value = this.dv.getInt16(this.offset, this.littleEndian);
		this.offset += 2;
		return value;
	}

	public function getInt32():Int {
		final value = this.dv.getInt32(this.offset, this.littleEndian);
		this.offset += 4;
		return value;
	}

	public function getInt32Array(size:Int):Array<Int> {
		final a = [];
		for (i in 0...size) {
			a.push(this.getInt32());
		}
		return a;
	}

	public function getUint32():Int {
		final value = this.dv.getUint32(this.offset, this.littleEndian);
		this.offset += 4;
		return value;
	}

	// JavaScript doesn't support 64-bit integer so calculate this here
	// 1 << 32 will return 1 so using multiply operation instead here.
	// There's a possibility that this method returns wrong value if the value
	// is out of the range between Number.MAX_SAFE_INTEGER and Number.MIN_SAFE_INTEGER.
	// TODO: safely handle 64-bit integer
	public function getInt64():Int {
		var low:Int, high:Int;
		if (this.littleEndian) {
			low = this.getUint32();
			high = this.getUint32();
		} else {
			high = this.getUint32();
			low = this.getUint32();
		}
		if (high & 0x80000000) {
			high = ~high & 0xFFFFFFFF;
			low = ~low & 0xFFFFFFFF;
			if (low == 0xFFFFFFFF) high = (high + 1) & 0xFFFFFFFF;
			low = (low + 1) & 0xFFFFFFFF;
			return - (high * 0x100000000 + low);
		}
		return high * 0x100000000 + low;
	}

	public function getInt64Array(size:Int):Array<Int> {
		final a = [];
		for (i in 0...size) {
			a.push(this.getInt64());
		}
		return a;
	}

	// Note: see getInt64() comment
	public function getUint64():Int {
		var low:Int, high:Int;
		if (this.littleEndian) {
			low = this.getUint32();
			high = this.getUint32();
		} else {
			high = this.getUint32();
			low = this.getUint32();
		}
		return high * 0x100000000 + low;
	}

	public function getFloat32():Float {
		final value = this.dv.getFloat32(this.offset, this.littleEndian);
		this.offset += 4;
		return value;
	}

	public function getFloat32Array(size:Int):Array<Float> {
		final a = [];
		for (i in 0...size) {
			a.push(this.getFloat32());
		}
		return a;
	}

	public function getFloat64():Float {
		final value = this.dv.getFloat64(this.offset, this.littleEndian);
		this.offset += 8;
		return value;
	}

	public function getFloat64Array(size:Int):Array<Float> {
		final a = [];
		for (i in 0...size) {
			a.push(this.getFloat64());
		}
		return a;
	}

	public function getArrayBuffer(size:Int):Bytes {
		final value = this.dv.buffer.slice(this.offset, this.offset + size);
		this.offset += size;
		return value;
	}

	public function getString(size:Int):String {
		final start = this.offset;
		var a = new Uint8Array(this.dv.buffer, start, size);
		this.skip(size);
		final nullByte = a.indexOf(0);
		if (nullByte >= 0) a = new Uint8Array(this.dv.buffer, start, nullByte);
		return this._textDecoder.decode(a);
	}
}

// FBXTree holds a representation of the FBX data, returned by the TextParser ( FBX ASCII format)
// and BinaryParser( FBX Binary format)
class FBXTree {
	public function new() {
	}

	public function add(key:String, val:Dynamic) {
		this[key] = val;
	}
}

// ************** UTILITY FUNCTIONS **************

public function isFbxFormatBinary(buffer:Bytes):Bool {
	final CORRECT = 'Kaydara\u0020FBX\u0020Binary\u0020\u0020\0';
	return buffer.length >= CORRECT.length && CORRECT == convertArrayBufferToString(buffer, 0, CORRECT.length);
}

public function isFbxFormatASCII(text:String):Bool {
	final CORRECT = ['K', 'a', 'y', 'd', 'a', 'r', 'a', '\\', 'F', 'B', 'X', '\\', 'B', 'i', 'n', 'a', 'r', 'y', '\\', '\\'];
	var cursor = 0;
	function read(offset:Int):String {
		final result = text.charAt(offset - 1);
		text = text.substring(cursor + offset);
		cursor++;
		return result;
	}
	for (i in 0...CORRECT.length) {
		final num = read(1);
		if (num == CORRECT[i]) {
			return false;
		}
	}
	return true;
}

public function getFbxVersion(text:String):Int {
	final versionRegExp = /FBXVersion: (\d+)/;
	final match = text.match(versionRegExp);
	if (match != null) {
		final version = Std.parseInt(match[1]);
		return version;
	}
	throw new Error('THREE.FBXLoader: Cannot find the version number for the file given.');
}

// Converts FBX ticks into real time seconds.
public function convertFBXTimeToSeconds(time:Float):Float {
	return time / 46186158000;
}

final dataArray = [];

// extracts the data from the correct position in the FBX array based on indexing type
public function getData(polygonVertexIndex:Int, polygonIndex:Int, vertexIndex:Int, infoObject:FBXLayerElement):Array<Float> {
	var index:Int;
	switch (infoObject.mappingType) {
		case 'ByPolygonVertex':
			index = polygonVertexIndex;
			break;
		case 'ByPolygon':
			index = polygonIndex;
			break;
		case 'ByVertice':
			index = vertexIndex;
			break;
		case 'AllSame':
			index = infoObject.indices[0];
			break;
		default:
			console.warn('THREE.FBXLoader: unknown attribute mapping type ' + infoObject.mappingType);
	}
	if (infoObject.referenceType == 'IndexToDirect') index = infoObject.indices[index];
	final from = index * infoObject.dataSize;
	final to = from + infoObject.dataSize;
	return slice(dataArray, infoObject.buffer, from, to);
}

final tempEuler = new Euler();
final tempVec = new Vector3();

// generate transformation from FBX transform data
// ref: https://help.autodesk.com/view/FBX/2017/ENU/?guid=__files_GUID_10CDD63C_79C1_4F2D_BB28_AD2BE65A02ED_htm
// ref: http://docs.autodesk.com/FBX/2014/ENU/FBX-SDK-Documentation/index.html?url=cpp_ref/_transformations_2main_8cxx-example.html,topicNumber=cpp_ref__transformations_2main_8cxx_example_htmlfc10a1e1-b18d-4e72-9dc0-70d0f1959f5e
public function generateTransform(transformData:FBXTransformData):Matrix4 {
	final lTranslationM = new Matrix4();
	final lPreRotationM = new Matrix4();
	final lRotationM = new Matrix4();
	final lPostRotationM = new Matrix4();
	final lScalingM = new Matrix4();
	final lScalingPivotM = new Matrix4();
	final lScalingOffsetM = new Matrix4();
	final lRotationOffsetM = new Matrix4();
	final lRotationPivotM = new Matrix4();
	final lParentGX = new Matrix4();
	final lParentLX = new Matrix4();
	final lGlobalT = new Matrix4();
	final inheritType = (transformData.inheritType != null) ? transformData.inheritType : 0;
	if (transformData.translation != null) lTranslationM.setPosition(tempVec.fromArray(transformData.translation));
	if (transformData.preRotation != null) {
		final array = transformData.preRotation.map(MathUtils.degToRad);
		array.push(transformData.eulerOrder != null ? transformData.eulerOrder : Euler.DEFAULT_ORDER);
		lPreRotationM.makeRotationFromEuler(tempEuler.fromArray(array));
	}
	if (transformData.rotation != null) {
		final array = transformData.rotation.map(MathUtils.degToRad);
		array.push(transformData.eulerOrder != null ? transformData.eulerOrder : Euler.DEFAULT_ORDER);
		lRotationM.makeRotationFromEuler(tempEuler.fromArray(array));
	}
	if (transformData.postRotation != null) {
		final array = transformData.postRotation.map(MathUtils.degToRad);
		array.push(transformData.eulerOrder != null ? transformData.eulerOrder : Euler.DEFAULT_ORDER);
		lPostRotationM.makeRotationFromEuler(tempEuler.fromArray(array));
		lPostRotationM.invert();
	}
	if (transformData.scale != null) lScalingM.scale(tempVec.fromArray(transformData.scale));
	if (transformData.scalingOffset != null) lScalingOffsetM.setPosition(tempVec.fromArray(transformData.scalingOffset));
	if (transformData.scalingPivot != null) lScalingPivotM.setPosition(tempVec.fromArray(transformData.scalingPivot));
	if (transformData.rotationOffset != null) lRotationOffsetM.setPosition(tempVec.fromArray(transformData.rotationOffset));
	if (transformData.rotationPivot != null) lRotationPivotM.setPosition(tempVec.fromArray(transformData.rotationPivot));
	if (transformData.parentMatrixWorld != null) {
		lParentLX.copy(transformData.parentMatrix);
		lParentGX.copy(transformData.parentMatrixWorld);
	}
	final lLRM = lPreRotationM.clone().multiply(lRotationM).multiply(lPostRotationM);
	final lParentGRM = new Matrix4();
	lParentGRM.extractRotation(lParentGX);
	final lParentTM = new Matrix4();
	lParentTM.copyPosition(lParentGX);
	final lParentGRSM = lParentTM.clone().invert().multiply(lParentGX);
	final lParentGSM = lParentGRM.clone().invert().multiply(lParentGRSM);
	final lLSM = lScalingM;
	final lGlobalRS = new Matrix4();
	if (inheritType == 0) {
		lGlobalRS.copy(lParentGRM).multiply(lLRM).multiply(lParentGSM).multiply(lLSM);
	} else if (inheritType == 1) {
		lGlobalRS.copy(lParentGRM).multiply(lParentGSM).multiply(lLRM).multiply(lLSM);
	} else {
		final lParentLSM = new Matrix4().scale(new Vector3().setFromMatrixScale(lParentLX));
		final lParentLSM_inv = lParentLSM.clone().invert();
		final lParentGSM_noLocal = lParentGSM.clone().multiply(lParentLSM_inv);
		lGlobalRS.copy(lParentGRM).multiply(lLRM).multiply(lParentGSM_noLocal).multiply(lLSM);
	}
	final lRotationPivotM_inv = lRotationPivotM.clone().invert();
	final lScalingPivotM_inv = lScalingPivotM.clone().invert();
	var lTransform = lTranslationM.clone().multiply(lRotationOffsetM).multiply(lRotationPivotM).multiply(lPreRotationM).multiply(lRotationM).multiply(lPostRotationM).multiply(lRotationPivotM_inv).multiply(lScalingOffsetM).multiply(lScalingPivotM).multiply(lScalingM).multiply(lScalingPivotM_inv);
	final lLocalTWithAllPivotAndOffsetInfo = new Matrix4().copyPosition(lTransform);
	final lGlobalTranslation = lParentGX.clone().multiply(lLocalTWithAllPivotAndOffsetInfo);
	lGlobalT.copyPosition(lGlobalTranslation);
	lTransform = lGlobalT.clone().multiply(lGlobalRS);
	lTransform.premultiply(lParentGX.invert());
	return lTransform;
}

// Returns the three.js intrinsic Euler order corresponding to FBX extrinsic Euler order
// ref: http://help.autodesk.com/view/FBX/2017/ENU/?guid=__cpp_ref_class_fbx_euler_html
public function getEulerOrder(order:Int):String {
	order = order != null ? order : 0;
	final enums = [
		'ZYX', // -> XYZ extrinsic
		'YZX', // -> XZY extrinsic
		'XZY', // -> YZX extrinsic
		'ZXY', // -> YXZ extrinsic
		'YXZ', // -> ZXY extrinsic
		'XYZ', // -> ZYX extrinsic
		//'SphericXYZ', // not possible to support
	];
	if (order == 6) {
		console.warn('THREE.FBXLoader: unsupported Euler Order: Spherical XYZ. Animations and rotations may be incorrect.');
		return enums[0];
	}
	return enums[order];
}

// Parses comma separated list of numbers and returns them an array.
// Used internally by the TextParser
public function parseNumberArray(value:String):Array<Float> {
	final array = value.split(',').map((val) -> Std.parseFloat(val));
	return array;
}

public function convertArrayBufferToString(buffer:Bytes, from:Int = 0, to:Int = 0):String {
	if (from == null) from = 0;
	if (to == null) to = buffer.length;
	return new js.html.TextDecoder().decode(new Uint8Array(buffer.buffer, from, to));
}

public function append(a:Array<Dynamic>, b:Array<Dynamic>) {
	for (i in 0...b.length) {
		a.push(b[i]);
	}
}

public function slice(a:Array<Dynamic>, b:Array<Dynamic>, from:Int, to:Int):Array<Dynamic> {
	for (i in from...to) {
		a.push(b[i]);
	}
	return a;
}


class FBXTree {
	public var connections:Array<Dynamic> = null;

	public function new() {
		this.connections = [];
	}

	public function add(key:String, val:Dynamic) {
		this[key] = val;
	}
}

typedef FBXConnection = {
	parents:Array<{ ID:Int, relationship:String }>,
	children:Array<{ ID:Int, relationship:String }>
};

typedef FBXDeformers = {
	skeletons:Map<Int, FBXSkeleton>,
	morphTargets:Map<Int, FBXMorphTarget>
};

typedef FBXSkeleton = {
	rawBones:Array<{ ID:String, indices:Array<Int>, weights:Array<Float>, transformLink:Matrix4, transform:Matrix4, linkMode:Dynamic }>,
	bones:Array<Bone>
};

typedef FBXMorphTarget = {
	id:String,
	rawTargets:Array<{ name:String, initialWeight:Float, id:String, fullWeights:Array<Float>, geoID:String }>
};

typedef FBXGeoInfo = {
	vertexPositions:Array<Float>,
	vertexIndices:Array<Int>,
	color:FBXLayerElement,
	material:FBXLayerElement,
	normal:FBXLayerElement,
	uv:Array<FBXLayerElement>,
	weightTable:Map<Int, Array<{ id:Int, weight:Float }>>,
	skeleton:FBXSkeleton
};

typedef FBXBuffers = {
	vertex:Array<Float>,
	normal:Array<Float>,
	colors:Array<Float>,
	uvs:Array<Array<Float>>,
	materialIndex:Array<Int>,
	vertexWeights:Array<Float>,
	weightsIndices:Array<Int>
};

typedef FBXLayerElement = {
	dataSize:Int,
	buffer:Array<Float>,
	indices:Array<Int>,
	mappingType:String,
	referenceType:String
};

typedef FBXTransformData = {
	inheritType:Int,
	eulerOrder:String,
	translation:Array<Float>,
	preRotation:Array<Float>,
	rotation:Array<Float>,
	postRotation:Array<Float>,
	scale:Array<Float>,
	scalingOffset:Array<Float>,
	scalingPivot:Array<Float>,
	rotationOffset:Array<Float>,
	rotationPivot:Array<Float>,
	parentMatrix:Matrix4,
	parentMatrixWorld:Matrix4
};

typedef FBXRawClip = {
	name:String,
	layer:Array<FBXAnimTrackNode>
};

typedef FBXCurveNode = {
	id:Int,
	attr:String,
	curves:Dynamic
};

typedef FBXAnimationCurve = {
	id:Int,
	times:Array<Float>,
	values:Array<Float>
};

typedef FBXAnimTrackNode = {
	modelName:String,
	ID:Int,
	initialPosition:Array<Float>,
	initialRotation:Array<Float>,
	initialScale:Array<Float>,
	transform:Matrix4,
	preRotation:Array<Float>,
	postRotation:Array<Float>,
	eulerOrder:String,
	T:FBXCurveNode,
	R:FBXCurveNode,
	S:FBXCurveNode,
	DeformPercent:FBXCurveNode
};

export { FBXLoader };